package main

import (
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"
)

func loaded(names ...string) model {
	m := newModel()
	m.height = 30
	out := ""
	for _, n := range names {
		out += " \t" + n + "\t\n"
	}
	next, _ := m.Update(branchesMsg{branches: parseBranches(out)})
	return next.(model)
}

func typeKeys(m model, s string) model {
	for _, r := range s {
		next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{r}})
		m = next.(model)
	}
	return m
}

func key(m model, t tea.KeyType) model {
	next, _ := m.Update(tea.KeyMsg{Type: t})
	return next.(model)
}

func TestParseBranches(t *testing.T) {
	out := "*\tmain\t/repo\n \tfeature\t/wt\n \tzeta\t\n*\t(HEAD detached at abc)\t\n"
	bs := parseBranches(out)
	if len(bs) != 4 {
		t.Fatalf("got %d branches", len(bs))
	}
	if !bs[0].Current || bs[0].Worktree {
		t.Errorf("main should be current only: %+v", bs[0])
	}
	if bs[1].Current || !bs[1].Worktree {
		t.Errorf("feature should be worktree: %+v", bs[1])
	}
	if bs[2].Current || bs[2].Worktree {
		t.Errorf("zeta should be plain: %+v", bs[2])
	}
	if !bs[3].Pseudo {
		t.Errorf("detached HEAD should be pseudo: %+v", bs[3])
	}
}

func TestRecencyOrder(t *testing.T) {
	reflog := strings.Join([]string{
		"commit: tweak",
		"checkout: moving from feature to main",
		"checkout: moving from old to feature",
		"checkout: moving from main to abc1234", // detached; ignored below
		"checkout: moving from feature to old",
	}, "\n")
	order := checkoutOrder(reflog)
	if order["main"] != 0 || order["feature"] != 1 || order["old"] != 2 {
		t.Errorf("unexpected order: %v", order)
	}

	// git's order is alphabetical; "never" has no reflog entry; "feature" is
	// current in this worktree and so comes first regardless.
	bs := parseBranches(" \tabc1234\t\n*\tfeature\t\n \tmain\t\n \tnever\t\n \told\t\n")
	sortByRecency(bs, order)
	got := make([]string, len(bs))
	for i, b := range bs {
		got[i] = b.Name
	}
	want := "feature main old abc1234 never"
	if strings.Join(got, " ") != want {
		t.Errorf("sorted = %q, want %q", strings.Join(got, " "), want)
	}

	// No reflog at all leaves git's order alone.
	bs = parseBranches(" \tb\t\n \ta\t\n")
	sortByRecency(bs, checkoutOrder(""))
	if bs[0].Name != "b" || bs[1].Name != "a" {
		t.Errorf("empty reflog should keep order, got %v", bs)
	}
}

func TestLoadingAndEmpty(t *testing.T) {
	m := newModel()
	if !strings.Contains(m.View(), "Loading branches...") {
		t.Errorf("expected loading placeholder, got %q", m.View())
	}
	m = loaded()
	if !strings.Contains(m.View(), "No branches") {
		t.Errorf("expected 'No branches', got %q", m.View())
	}
	m = loaded("main")
	m = typeKeys(m, "zzz")
	if !strings.Contains(m.View(), "No branches") {
		t.Errorf("expected 'No branches' after filtering everything out")
	}
}

func TestWrapAround(t *testing.T) {
	m := loaded("a", "b", "c")
	if m.selected != "a" {
		t.Fatalf("initial selection %q", m.selected)
	}
	m = key(m, tea.KeyTab)
	m = key(m, tea.KeyTab)
	m = key(m, tea.KeyTab)
	if m.selected != "a" {
		t.Errorf("tab should wrap to top, got %q", m.selected)
	}
	m = key(m, tea.KeyShiftTab)
	if m.selected != "c" {
		t.Errorf("shift+tab should wrap to bottom, got %q", m.selected)
	}
}

func TestSelectionStableAcrossSearch(t *testing.T) {
	m := loaded("alpha", "beta", "gamma")
	m = key(m, tea.KeyTab) // beta
	m = typeKeys(m, "a")   // all still match
	if m.selected != "beta" {
		t.Errorf("selection should stay on beta, got %q", m.selected)
	}
	m = typeKeys(m, "m") // "am" -> gamma only
	if m.selected != "gamma" {
		t.Errorf("selection should fall back to first, got %q", m.selected)
	}
	m = key(m, tea.KeyBackspace) // "a" -> all again; stay on gamma
	if m.selected != "gamma" {
		t.Errorf("selection should stay on gamma when more appear, got %q", m.selected)
	}
	if !strings.Contains(m.View(), "> ") {
		t.Errorf("cursor missing from view")
	}
}

func TestEnterQuitsWithTarget(t *testing.T) {
	m := newModel()
	next, _ := m.Update(branchesMsg{branches: parseBranches("*\tmain\t\n \tdev\t\n")})
	m = next.(model)
	// Enter on the current branch still hands over to git, which reports
	// "Already on 'main'" itself.
	next, cmd := m.Update(tea.KeyMsg{Type: tea.KeyEnter})
	m = next.(model)
	if cmd == nil || !m.quitting || strings.Join(m.gitArgs, " ") != "switch main" {
		t.Errorf("enter on current branch should quit with `switch main`, got %+v", m)
	}

	m = key(loaded("main", "dev"), tea.KeyTab)
	next, cmd = m.Update(tea.KeyMsg{Type: tea.KeyEnter})
	m = next.(model)
	if cmd == nil || !m.quitting || strings.Join(m.gitArgs, " ") != "switch dev" {
		t.Errorf("enter should quit with `switch dev`, got %+v", m)
	}
	if m.View() != "" {
		t.Errorf("view should be blank once quitting, got %q", m.View())
	}

	m = newModel()
	next, _ = m.Update(branchesMsg{branches: parseBranches("*\t(HEAD detached at abc)\t\n")})
	m = next.(model)
	_, cmd = m.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if cmd != nil {
		t.Errorf("enter on detached HEAD entry should do nothing")
	}
}

func TestFuzzyFilterRanksBestFirst(t *testing.T) {
	m := loaded("main", "feature/login-page", "fix/login", "release")
	m = typeKeys(m, "lgn")
	got := make([]string, len(m.filtered))
	for i, b := range m.filtered {
		got[i] = b.Name
	}
	want := "fix/login feature/login-page"
	if strings.Join(got, " ") != want {
		t.Errorf("fuzzy results = %q, want %q", strings.Join(got, " "), want)
	}
	if m.selected != "fix/login" {
		t.Errorf("selection should land on best match, got %q", m.selected)
	}
	if len(m.filtered[0].matched) != 3 {
		t.Errorf("expected 3 matched offsets, got %v", m.filtered[0].matched)
	}
	m = typeKeys(m, "zz")
	if len(m.filtered) != 0 {
		t.Errorf("non-matching query should empty the list, got %v", m.filtered)
	}
	m = key(m, tea.KeyCtrlU) // clear search
	if len(m.filtered) != 4 || m.filtered[0].Name != "main" {
		t.Errorf("empty query should restore git order, got %v", m.filtered)
	}
}

func TestDeleteKeys(t *testing.T) {
	base := key(loaded("main", "dev"), tea.KeyTab) // dev

	m := key(base, tea.KeyCtrlD)
	if !m.quitting || strings.Join(m.gitArgs, " ") != "branch -d dev" {
		t.Errorf("ctrl-d should quit with `branch -d dev`, got %+v", m)
	}

	m = typeKeys(base, "D")
	if !m.quitting || strings.Join(m.gitArgs, " ") != "branch -D dev" {
		t.Errorf("shift-d should quit with `branch -D dev`, got %+v", m)
	}

	// Lowercase d is ordinary search input.
	m = typeKeys(base, "d")
	if m.quitting || m.gitArgs != nil || m.search.Value() != "d" {
		t.Errorf("lowercase d should only filter, got %+v", m)
	}

	// Pasted text containing D is search input too.
	next, _ := base.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune("D"), Paste: true})
	m = next.(model)
	if m.quitting || m.search.Value() != "D" {
		t.Errorf("pasted D should only filter, got %+v", m)
	}
}

func TestScrollingKeepsSelectionVisible(t *testing.T) {
	names := make([]string, 50)
	for i := range names {
		names[i] = strings.Repeat("x", i+1)
	}
	m := loaded(names...)
	m.height = 10
	m = key(m, tea.KeyShiftTab) // wrap to last
	if !strings.Contains(m.View(), "> "+"  "+names[49]) {
		t.Errorf("last item should be visible after wrapping:\n%s", m.View())
	}
	m = key(m, tea.KeyTab) // wrap to first
	if !strings.Contains(m.View(), "> "+"  "+names[0]+" ") {
		t.Errorf("first item should be visible after wrapping:\n%s", m.View())
	}
}
