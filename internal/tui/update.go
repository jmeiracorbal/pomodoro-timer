package tui

import (
	"fmt"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/jmeiracorbal/pomodoro-timer/internal/notify"
)

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {

	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "q", "Q", "ctrl+c":
			return m, tea.Quit
		case " ":
			return m.togglePause()
		case "s", "S":
			return m.skipPhase()
		case "r", "R":
			if m.state == stateRunning || m.state == statePaused {
				m.remaining = m.totalDur
				m.state = stateRunning
				return m, tickCmd()
			}
		}

	case tickMsg:
		if m.state != stateRunning {
			return m, nil
		}
		m.remaining -= 1e9 // 1 second in nanoseconds
		if m.remaining <= 0 {
			m.remaining = 0
			return m.onPhaseComplete()
		}
		return m, tickCmd()

	case phaseAdvanceMsg:
		if msg.gen != m.transitionGen {
			return m, nil
		}
		return m.advancePhase()
	}

	return m, nil
}

func (m Model) togglePause() (Model, tea.Cmd) {
	switch m.state {
	case stateRunning:
		m.state = statePaused
		return m, nil
	case statePaused:
		m.state = stateRunning
		return m, tickCmd()
	}
	return m, nil
}

func (m Model) skipPhase() (Model, tea.Cmd) {
	m.remaining = 0
	return m.onPhaseComplete()
}

func (m Model) onPhaseComplete() (Model, tea.Cmd) {
	m.state = stateComplete
	m.transitionGen++

	switch m.phase {
	case phaseWork:
		m.stats.Add("work", m.cfg.WorkMinutes)
		_ = m.stats.Save()

		if m.cfg.Notifications {
			go notify.Send("Pomodoro", "Work session complete!")
		}
		if m.cfg.Sound {
			go notify.PlaySound("complete")
		}

		if m.cycle >= m.cfg.Cycles {
			m.completionMsg = fmt.Sprintf("Session %d complete — long break starting…", m.cycle)
		} else {
			m.completionMsg = fmt.Sprintf("Session %d complete — short break starting…", m.cycle)
		}

	case phaseShortBreak, phaseLongBreak:
		if m.cfg.Notifications {
			go notify.Send("Pomodoro", "Break over — back to work!")
		}
		if m.cfg.Sound {
			go notify.PlaySound("start")
		}
		m.completionMsg = "Break complete — work session starting…"
	}

	return m, phaseAdvanceCmd(m.transitionGen)
}

func (m Model) advancePhase() (Model, tea.Cmd) {
	switch m.phase {
	case phaseWork:
		if m.cycle >= m.cfg.Cycles {
			m.phase = phaseLongBreak
			m.cycle = 1
			m.totalDur = durMinutes(m.cfg.LongBreak)
		} else {
			m.phase = phaseShortBreak
			m.cycle++
			m.totalDur = durMinutes(m.cfg.ShortBreak)
		}
	case phaseShortBreak, phaseLongBreak:
		m.phase = phaseWork
		m.totalDur = durMinutes(m.cfg.WorkMinutes)
	}

	m.remaining = m.totalDur
	m.state = stateRunning
	m.completionMsg = ""
	return m, tickCmd()
}
