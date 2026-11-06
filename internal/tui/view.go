package tui

import (
	"fmt"
	"time"

	"github.com/charmbracelet/lipgloss"
)

func durMinutes(n int) time.Duration {
	return time.Duration(n) * time.Minute
}

func (m Model) View() string {
	content := m.renderContent()
	box := styleBox.Render(content)
	if m.width > 0 && m.height > 0 {
		return lipgloss.Place(m.width, m.height, lipgloss.Center, lipgloss.Center, box)
	}
	return box + "\n"
}

func (m Model) renderContent() string {
	rows := []string{
		styleTitle.Render("🍅  Pomodoro Timer"),
		"",
		m.phaseLabel(),
		"",
		m.progressRow(),
		"",
		m.timeRow(),
		"",
		m.statusRow(),
		"",
		styleHint.Render("[space] pause  [s] skip  [r] reset  [q] quit"),
	}
	return lipgloss.JoinVertical(lipgloss.Center, rows...)
}

func (m Model) phaseLabel() string {
	switch m.state {
	case stateComplete:
		return styleComplete.Render("✓  " + m.completionMsg)
	}

	switch m.phase {
	case phaseWork:
		return styleWork.Render(fmt.Sprintf("Work Session  ·  %d of %d", m.cycle, m.cfg.Cycles))
	case phaseShortBreak:
		return styleBreak.Render("Short Break")
	case phaseLongBreak:
		return styleBreak.Render("Long Break")
	}
	return ""
}

func (m Model) progressRow() string {
	var pct float64
	if m.totalDur > 0 {
		elapsed := m.totalDur - m.remaining
		pct = float64(elapsed) / float64(m.totalDur)
	}
	if pct > 1 {
		pct = 1
	}
	return m.bar.ViewAs(pct)
}

func (m Model) timeRow() string {
	if m.state == stateComplete {
		return styleComplete.Render("00:00")
	}
	mins := int(m.remaining / time.Minute)
	secs := int(m.remaining/time.Second) % 60
	return styleTime.Render(fmt.Sprintf("%02d:%02d", mins, secs))
}

func (m Model) statusRow() string {
	if m.state == statePaused {
		return stylePaused.Render("⏸  Paused")
	}
	return ""
}
