package tui

import (
	"time"

	"github.com/charmbracelet/bubbles/progress"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/jmeiracorbal/pomodoro-timer/internal/config"
	"github.com/jmeiracorbal/pomodoro-timer/internal/stats"
)

type phase int

const (
	phaseWork phase = iota
	phaseShortBreak
	phaseLongBreak
)

type state int

const (
	stateRunning state = iota
	statePaused
	stateComplete
)

type tickMsg time.Time

type phaseAdvanceMsg struct{ gen int }

type Model struct {
	cfg   config.Config
	stats *stats.Stats

	phase phase
	state state
	cycle int // current work session within the cycle (1-based)

	totalDur  time.Duration
	remaining time.Duration

	transitionGen int
	completionMsg string

	bar    progress.Model
	width  int
	height int
}

func New(cfg config.Config, s *stats.Stats) Model {
	bar := progress.New(
		progress.WithScaledGradient("#E06C75", "#E5C07B"),
		progress.WithWidth(42),
		progress.WithoutPercentage(),
	)
	m := Model{
		cfg:      cfg,
		stats:    s,
		phase:    phaseWork,
		state:    stateRunning,
		cycle:    1,
		totalDur: time.Duration(cfg.WorkMinutes) * time.Minute,
		bar:      bar,
	}
	m.remaining = m.totalDur
	return m
}

func (m Model) Init() tea.Cmd {
	return tickCmd()
}

func tickCmd() tea.Cmd {
	return tea.Tick(time.Second, func(t time.Time) tea.Msg {
		return tickMsg(t)
	})
}

func phaseAdvanceCmd(gen int) tea.Cmd {
	return tea.Tick(2*time.Second, func(_ time.Time) tea.Msg {
		return phaseAdvanceMsg{gen: gen}
	})
}
