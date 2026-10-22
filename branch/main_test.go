package main

import (
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
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

func TestEnterOnCurrentAndPseudo(t *testing.T) {
	m := newModel()
	next, _ := m.Update(branchesMsg{branches: parseBranches("*\tmain\t\n \tdev\t\n")})
	m = next.(model)
	next, cmd := m.Update(tea.KeyMsg{Type: tea.KeyEnter})
	m = next.(model)
	if cmd == nil || !m.quitting || m.output != "Already on 'main'" {
		t.Errorf("enter on current branch should quit with notice, got %+v", m)
	}

	m = newModel()
	next, _ = m.Update(branchesMsg{branches: parseBranches("*\t(HEAD detached at abc)\t\n")})
	m = next.(model)
	_, cmd = m.Update(tea.KeyMsg{Type: tea.KeyEnter})
	if cmd != nil {
		t.Errorf("enter on detached HEAD entry should do nothing")
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

func TestFuzzyRanking(t *testing.T) {
	m := loaded("prefix-stuff", "other", "feature/fix-login", "FIX-typo")
	m = typeKeys(m, "fix")
	got := make([]string, len(m.filtered))
	for i, h := range m.filtered {
		got[i] = h.Name
	}
	if len(got) != 3 || got[0] != "FIX-typo" || got[1] != "feature/fix-login" || got[2] != "prefix-stuff" {
		t.Errorf("want word-start matches first and no \"other\", got %v", got)
	}
	// The selection deliberately stays on the branch it was on while it is
	// still visible (see TestSelectionStableAcrossSearch), so ranking does not
	// move it; it was on prefix-stuff, the first branch in git order.
	if m.selected != "prefix-stuff" {
		t.Errorf("selection should stay put while still visible, got %q", m.selected)
	}

	// Subsequence match: letters in order but not adjacent.
	m = loaded("feature/fix-login", "main")
	m = typeKeys(m, "flog")
	if len(m.filtered) != 1 || m.filtered[0].Name != "feature/fix-login" {
		t.Errorf("\"flog\" should fuzzy-match feature/fix-login only, got %v", m.filtered)
	}
	if !strings.Contains(m.View(), "feature/fix-login") {
		t.Errorf("matched branch missing from view")
	}
}

func TestHighlightSegments(t *testing.T) {
	// Plain style so the output is inspectable: matched runs come out as one
	// styled segment each, unmatched text untouched.
	got := highlight("fix-login", []int{0, 1, 4}, lipgloss.NewStyle())
	want := matchStyle.Render("fi") + "x-" + matchStyle.Render("l") + "ogin"
	if got != want {
		t.Errorf("highlight = %q, want %q", got, want)
	}
	if highlight("main", nil, lipgloss.NewStyle()) != "main" {
		t.Errorf("no matches should render the name unchanged")
	}
}
