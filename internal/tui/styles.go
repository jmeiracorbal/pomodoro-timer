package tui

import "github.com/charmbracelet/lipgloss"

var (
	colorRed    = lipgloss.Color("#E06C75")
	colorGreen  = lipgloss.Color("#98C379")
	colorYellow = lipgloss.Color("#E5C07B")
	colorCyan   = lipgloss.Color("#56B6C2")
	colorGray   = lipgloss.Color("#5C6370")
	colorWhite  = lipgloss.Color("#ABB2BF")

	styleTitle = lipgloss.NewStyle().
			Bold(true).
			Foreground(colorCyan)

	styleWork = lipgloss.NewStyle().
			Bold(true).
			Foreground(colorRed)

	styleBreak = lipgloss.NewStyle().
			Bold(true).
			Foreground(colorGreen)

	styleComplete = lipgloss.NewStyle().
			Bold(true).
			Foreground(colorGreen)

	stylePaused = lipgloss.NewStyle().
			Bold(true).
			Foreground(colorYellow)

	styleTime = lipgloss.NewStyle().
			Bold(true).
			Foreground(colorWhite)

	styleHint = lipgloss.NewStyle().
			Foreground(colorGray)

	styleBox = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(colorGray).
			Padding(1, 4)
)
