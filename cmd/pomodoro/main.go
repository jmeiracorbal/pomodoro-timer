package main

import (
	"flag"
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/jmeiracorbal/pomodoro-timer/internal/config"
	"github.com/jmeiracorbal/pomodoro-timer/internal/stats"
	"github.com/jmeiracorbal/pomodoro-timer/internal/tui"
)

var version = "2.0.0"

func main() {
	work    := flag.Int("w", 0, "work session `minutes` (default 25)")
	short   := flag.Int("s", 0, "short break `minutes` (default 5)")
	long    := flag.Int("l", 0, "long break `minutes` (default 15)")
	cycles  := flag.Int("c", 0, "`count` of work sessions before a long break (default 4)")
	noSound := flag.Bool("no-sound", false, "disable sound")
	noNotif := flag.Bool("no-notifications", false, "disable desktop notifications")
	ver     := flag.Bool("v", false, "print version and exit")
	showStats := flag.Bool("stats", false, "show today's statistics and exit")

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "pomodoro v%s\n\n", version)
		fmt.Fprintf(os.Stderr, "Usage: pomodoro [options]\n\n")
		fmt.Fprintf(os.Stderr, "Options:\n")
		flag.PrintDefaults()
		fmt.Fprintf(os.Stderr, "\nControls (while running):\n")
		fmt.Fprintf(os.Stderr, "  space  pause / resume\n")
		fmt.Fprintf(os.Stderr, "  s      skip current phase\n")
		fmt.Fprintf(os.Stderr, "  r      reset current phase\n")
		fmt.Fprintf(os.Stderr, "  q      quit\n")
	}
	flag.Parse()

	if *ver {
		fmt.Printf("pomodoro v%s\n", version)
		return
	}

	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "config: %v\n", err)
		os.Exit(1)
	}

	if *work > 0 {
		cfg.WorkMinutes = *work
	}
	if *short > 0 {
		cfg.ShortBreak = *short
	}
	if *long > 0 {
		cfg.LongBreak = *long
	}
	if *cycles > 0 {
		cfg.Cycles = *cycles
	}
	if *noSound {
		cfg.Sound = false
	}
	if *noNotif {
		cfg.Notifications = false
	}

	s, _ := stats.Load()

	if *showStats {
		s.Print()
		return
	}

	p := tea.NewProgram(
		tui.New(cfg, s),
		tea.WithAltScreen(),
	)
	if _, err := p.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}
