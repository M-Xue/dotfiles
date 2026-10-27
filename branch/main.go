// Command branch is an interactive local-branch switcher for git.
//
// It lists local branches most recently checked out first (taken from HEAD's
// reflog), marked the same way `git branch` does (current branch "*" in green,
// branches checked out in another worktree "+" in cyan), lets you fuzzy-filter them with a search bar, and when you press
// Enter leaves the TUI and runs `git switch` on the selected branch in your
// terminal, so you see exactly what git normally prints. Ctrl-D and Shift-D do
// the same with `git branch -d` and `git branch -D`.
package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"sort"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"github.com/sahilm/fuzzy"
)

var (
	// "Search" label.
	labelStyle = lipgloss.NewStyle().Bold(true)
	// One blank line above and one space to the left of everything.
	frameStyle = lipgloss.NewStyle().PaddingTop(1).PaddingLeft(1)
	// Same ANSI colours `git branch` uses: green for current, cyan for worktree.
	currentStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("2"))
	worktreeStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("6"))
	plainStyle    = lipgloss.NewStyle()
)

// branch is one line of `git branch` output.
type branch struct {
	Name     string
	Current  bool // checked out in this worktree ("*")
	Worktree bool // checked out in another worktree ("+")
	Pseudo   bool // e.g. "(HEAD detached at abc123)"; not switchable

	// Byte offsets in Name of the characters the search matched, for
	// highlighting. Empty when there is no search text.
	matched []int
}

type branchesMsg struct {
	branches []branch
	err      error
}

type model struct {
	search   textinput.Model
	all      []branch
	filtered []branch
	selected string // name of the selected branch, "" when nothing is selected
	offset   int    // first visible row, for scrolling long lists

	loading  bool
	quitting bool
	fatal    error    // fatal error reported after the program exits
	gitArgs  []string // git command to run once the TUI has exited, e.g. "switch", "main"
	width    int
	height   int
}

const searchLabel = "Search: "

func newModel() model {
	ti := textinput.New()
	ti.Prompt = ""
	ti.Width = 40
	ti.Focus()
	return model{search: ti, loading: true}
}

func (m model) Init() tea.Cmd {
	return tea.Batch(textinput.Blink, loadBranches)
}

// loadBranches asks git for the local branches and orders them by most
// recent checkout.
func loadBranches() tea.Msg {
	out, err := exec.Command("git", "branch", "--no-color",
		"--format=%(HEAD)%09%(refname:short)%09%(worktreepath)").Output()
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) && len(exitErr.Stderr) > 0 {
			return branchesMsg{err: errors.New(strings.TrimSpace(string(exitErr.Stderr)))}
		}
		return branchesMsg{err: err}
	}
	branches := parseBranches(string(out))
	// The reflog is best-effort: without one, branches stay in git's order.
	if log, err := exec.Command("git", "reflog", "show", "--format=%gs").Output(); err == nil {
		sortByRecency(branches, checkoutOrder(string(log)))
	}
	return branchesMsg{branches: branches}
}

var checkoutRe = regexp.MustCompile(`^checkout: moving from (\S+) to (\S+)$`)

// checkoutOrder reads HEAD's reflog (newest entry first) and returns, for
// every branch name that appears in a checkout, how recently it was checked
// out: 0 for the most recent, 1 for the next, and so on. The "from" side of
// an entry counts too, since that branch was checked out just before.
func checkoutOrder(reflog string) map[string]int {
	order := map[string]int{}
	for _, line := range strings.Split(reflog, "\n") {
		m := checkoutRe.FindStringSubmatch(line)
		if m == nil {
			continue
		}
		for _, name := range []string{m[2], m[1]} {
			if _, seen := order[name]; !seen {
				order[name] = len(order)
			}
		}
	}
	return order
}

// sortByRecency puts the current branch first, then the others by most
// recent checkout, then branches never checked out in their existing order.
func sortByRecency(branches []branch, order map[string]int) {
	rank := func(b branch) int {
		if b.Current {
			return -1
		}
		if r, ok := order[b.Name]; ok {
			return r
		}
		return len(order)
	}
	sort.SliceStable(branches, func(i, j int) bool {
		return rank(branches[i]) < rank(branches[j])
	})
}

func parseBranches(out string) []branch {
	var branches []branch
	for _, line := range strings.Split(out, "\n") {
		parts := strings.SplitN(line, "\t", 3)
		if len(parts) != 3 {
			continue
		}
		b := branch{Name: parts[1], Current: parts[0] == "*"}
		b.Worktree = !b.Current && parts[2] != ""
		b.Pseudo = strings.HasPrefix(b.Name, "(")
		branches = append(branches, b)
	}
	return branches
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		m.search.Width = max(10, m.width-len(searchLabel)-2)
		m.ensureVisible()
		return m, nil

	case branchesMsg:
		m.loading = false
		if msg.err != nil {
			m.fatal = msg.err
			m.quitting = true
			return m, tea.Quit
		}
		m.all = msg.branches
		m.applyFilter()
		return m, nil

	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyCtrlC, tea.KeyEsc:
			m.quitting = true
			return m, tea.Quit
		case tea.KeyTab, tea.KeyDown, tea.KeyCtrlN:
			m.move(1)
			return m, nil
		case tea.KeyShiftTab, tea.KeyUp, tea.KeyCtrlP:
			m.move(-1)
			return m, nil
		case tea.KeyEnter:
			return m, m.run("switch")
		case tea.KeyCtrlD:
			return m, m.run("branch", "-d")
		}
		// Shift-D. Search is case-insensitive, so a capital D is never needed there.
		if !msg.Paste && string(msg.Runes) == "D" {
			return m, m.run("branch", "-D")
		}
		var cmd tea.Cmd
		m.search, cmd = m.search.Update(msg)
		m.applyFilter()
		return m, cmd
	}

	var cmd tea.Cmd
	m.search, cmd = m.search.Update(msg)
	return m, cmd
}

// run quits the TUI, arranging for main to run `git <args...> <branch>` on
// the selected branch in the terminal. Nothing is validated here (current
// branch, worktree branch, unmerged branch): git gets to print its own
// messages, such as "Already on '...'" or "not fully merged".
func (m *model) run(args ...string) tea.Cmd {
	i := m.indexOf(m.selected)
	if m.loading || i < 0 || m.filtered[i].Pseudo {
		return nil
	}
	m.gitArgs = append(args, m.filtered[i].Name)
	m.quitting = true
	return tea.Quit
}

// move shifts the selection by delta, wrapping at both ends.
func (m *model) move(delta int) {
	n := len(m.filtered)
	if n == 0 {
		return
	}
	i := m.indexOf(m.selected)
	if i < 0 {
		i = 0
	} else {
		i = ((i+delta)%n + n) % n
	}
	m.selected = m.filtered[i].Name
	m.ensureVisible()
}

// applyFilter recomputes the visible branches from the search text, keeping
// the selection on the same branch when it is still visible and otherwise
// falling back to the first one.
//
// With no search text the branches stay in recency order. Otherwise they are
// fuzzy-matched (the typed characters must appear in order, not necessarily
// adjacent) and sorted best match first, recency breaking ties.
func (m *model) applyFilter() {
	query := m.search.Value()
	m.filtered = m.filtered[:0:0]
	if query == "" {
		for _, b := range m.all {
			b.matched = nil
			m.filtered = append(m.filtered, b)
		}
	} else {
		names := make([]string, len(m.all))
		for i, b := range m.all {
			names[i] = b.Name
		}
		for _, match := range fuzzy.Find(query, names) {
			b := m.all[match.Index]
			b.matched = match.MatchedIndexes
			m.filtered = append(m.filtered, b)
		}
	}
	if m.indexOf(m.selected) < 0 {
		m.selected = ""
		if len(m.filtered) > 0 {
			m.selected = m.filtered[0].Name
		}
	}
	m.ensureVisible()
}

func (m *model) indexOf(name string) int {
	if name == "" {
		return -1
	}
	for i, b := range m.filtered {
		if b.Name == name {
			return i
		}
	}
	return -1
}

// listRows is how many branch rows fit on screen under the search bar.
func (m *model) listRows() int {
	if m.height == 0 {
		return 20 // no size known yet
	}
	// top padding, search bar, blank line, and the trailing newline
	return max(1, m.height-4)
}

func (m *model) ensureVisible() {
	i := m.indexOf(m.selected)
	if i < 0 {
		m.offset = 0
		return
	}
	rows := m.listRows()
	if i < m.offset {
		m.offset = i
	}
	if i >= m.offset+rows {
		m.offset = i - rows + 1
	}
	m.offset = max(0, min(m.offset, len(m.filtered)-rows))
}

func (m model) View() string {
	if m.quitting {
		return ""
	}
	var b strings.Builder
	b.WriteString(labelStyle.Render(strings.TrimSpace(searchLabel)))
	b.WriteString(" ")
	b.WriteString(m.search.View())
	b.WriteString("\n\n")

	switch {
	case m.loading:
		b.WriteString("Loading branches...\n")
	case len(m.filtered) == 0:
		b.WriteString("No branches\n")
	default:
		end := min(m.offset+m.listRows(), len(m.filtered))
		for _, br := range m.filtered[m.offset:end] {
			cursor := " "
			if br.Name == m.selected {
				cursor = ">"
			}
			marker, style := " ", plainStyle
			switch {
			case br.Current:
				marker, style = "*", currentStyle
			case br.Worktree:
				marker, style = "+", worktreeStyle
			}
			fmt.Fprintf(&b, "%s %s %s\n", cursor, marker, highlight(br.Name, br.matched, style))
		}
	}

	return frameStyle.Render(strings.TrimRight(b.String(), "\n")) + "\n"
}

// highlight renders name in style, underlining the characters at the given
// byte offsets (the ones the search matched).
func highlight(name string, matched []int, style lipgloss.Style) string {
	if len(matched) == 0 {
		return style.Render(name)
	}
	hit := style.Underline(true).Bold(true)
	var b strings.Builder
	next := 0 // index into matched, which is sorted ascending
	for i, r := range name {
		if next < len(matched) && matched[next] == i {
			b.WriteString(hit.Render(string(r)))
			next++
		} else {
			b.WriteString(style.Render(string(r)))
		}
	}
	return b.String()
}

func main() {
	final, err := tea.NewProgram(newModel()).Run()
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	m := final.(model)
	if m.fatal != nil {
		fmt.Fprintln(os.Stderr, m.fatal)
		os.Exit(1)
	}
	if len(m.gitArgs) == 0 {
		return
	}
	// The TUI has restored the terminal, so run git attached to it exactly as
	// if typed at the prompt: same output, same colours, same exit status.
	cmd := exec.Command("git", m.gitArgs...)
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			os.Exit(exitErr.ExitCode())
		}
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
