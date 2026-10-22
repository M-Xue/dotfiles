// Command branch is an interactive local-branch switcher for git.
//
// It lists local branches the same way `git branch` does (current branch
// marked with "*" in green, branches checked out in another worktree marked
// with "+" in cyan), lets you fuzzy-filter them with a search bar (best match
// first, matched characters underlined), and switches to the selected branch
// when you press Enter.
package main

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
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
	errStyle      = lipgloss.NewStyle().Foreground(lipgloss.Color("1"))
	// Applied on top of the row's own colour to the characters the query hit.
	matchStyle = lipgloss.NewStyle().Bold(true).Underline(true)
)

// branch is one line of `git branch` output.
type branch struct {
	Name     string
	Current  bool // checked out in this worktree ("*")
	Worktree bool // checked out in another worktree ("+")
	Pseudo   bool // e.g. "(HEAD detached at abc123)"; not switchable
}

// hit is a branch that survived the filter, with the byte offsets in Name
// that the query matched (empty when there is no query).
type hit struct {
	branch
	matched []int
}

// branchSource lets fuzzy search over []branch without copying the names out.
type branchSource []branch

func (s branchSource) String(i int) string { return s[i].Name }
func (s branchSource) Len() int            { return len(s) }

type branchesMsg struct {
	branches []branch
	err      error
}

type switchedMsg struct {
	output string
	err    error
}

type model struct {
	search   textinput.Model
	all      []branch
	filtered []hit
	selected string // name of the selected branch, "" when nothing is selected
	offset   int    // first visible row, for scrolling long lists

	loading   bool
	switching bool
	quitting  bool
	errMsg    string // non-fatal error shown under the list
	fatal     error  // fatal error reported after the program exits
	output    string // git's output after a successful switch
	width     int
	height    int
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

// loadBranches asks git for the local branches, in git's own order.
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
	return branchesMsg{branches: parseBranches(string(out))}
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

func switchBranch(name string) tea.Cmd {
	return func() tea.Msg {
		var buf bytes.Buffer
		cmd := exec.Command("git", "switch", name)
		cmd.Stdout = &buf
		cmd.Stderr = &buf
		err := cmd.Run()
		return switchedMsg{output: strings.TrimSpace(buf.String()), err: err}
	}
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

	case switchedMsg:
		m.switching = false
		if msg.err != nil {
			m.errMsg = msg.output
			if m.errMsg == "" {
				m.errMsg = msg.err.Error()
			}
			return m, nil
		}
		m.output = msg.output
		m.quitting = true
		return m, tea.Quit

	case tea.KeyMsg:
		m.errMsg = ""
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
			return m, m.enter()
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

// enter switches to the selected branch, if that makes sense.
func (m *model) enter() tea.Cmd {
	i := m.indexOf(m.selected)
	if m.loading || m.switching || i < 0 {
		return nil
	}
	b := m.filtered[i]
	if b.Pseudo {
		return nil
	}
	if b.Current {
		// Nothing to do; behave like `git switch` would and just report it.
		m.output = fmt.Sprintf("Already on '%s'", b.Name)
		m.quitting = true
		return tea.Quit
	}
	m.switching = true
	return switchBranch(b.Name)
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
// Matching is fuzzy: the query's characters must appear in the name in order,
// not necessarily together, case-insensitively. Results are ranked best match
// first - word starts, consecutive runs and short gaps score higher - with
// ties kept in git's order. An empty query shows everything in git's order.
func (m *model) applyFilter() {
	query := m.search.Value()
	m.filtered = m.filtered[:0:0]
	if query == "" {
		for _, b := range m.all {
			m.filtered = append(m.filtered, hit{branch: b})
		}
	} else {
		for _, match := range fuzzy.FindFrom(query, branchSource(m.all)) {
			m.filtered = append(m.filtered, hit{branch: m.all[match.Index], matched: match.MatchedIndexes})
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
	// top padding, search bar, blank line, and one line kept for error messages
	return max(1, m.height-5)
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
			marker, style := " ", lipgloss.NewStyle()
			switch {
			case br.Current:
				marker, style = "*", currentStyle
			case br.Worktree:
				marker, style = "+", worktreeStyle
			}
			fmt.Fprintf(&b, "%s %s %s\n", cursor, marker, highlight(br.Name, br.matched, style))
		}
	}

	if m.errMsg != "" {
		b.WriteString("\n")
		b.WriteString(errStyle.Render(m.errMsg))
	}
	return frameStyle.Render(strings.TrimRight(b.String(), "\n")) + "\n"
}

// highlight renders name in base, with the bytes at the matched offsets (sorted
// ascending, as fuzzy returns them) additionally in matchStyle. Runs of
// adjacent matches are rendered as one segment to keep the escape codes down.
func highlight(name string, matched []int, base lipgloss.Style) string {
	if len(matched) == 0 {
		return base.Render(name)
	}
	hot := base.Inherit(matchStyle)
	var out strings.Builder
	pos := 0
	for i := 0; i < len(matched); {
		start := matched[i]
		end := start + 1
		for i++; i < len(matched) && matched[i] == end; i++ {
			end++
		}
		if start > pos {
			out.WriteString(base.Render(name[pos:start]))
		}
		out.WriteString(hot.Render(name[start:end]))
		pos = end
	}
	if pos < len(name) {
		out.WriteString(base.Render(name[pos:]))
	}
	return out.String()
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
	if m.output != "" {
		// git prints "Switched to branch '...'" on stderr; do the same.
		fmt.Fprintln(os.Stderr, m.output)
	}
}
