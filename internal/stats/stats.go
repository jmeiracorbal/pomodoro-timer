package stats

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

type Session struct {
	Type        string    `json:"type"`
	Minutes     int       `json:"minutes"`
	CompletedAt time.Time `json:"completed_at"`
}

type Stats struct {
	Sessions []Session `json:"sessions"`
}

func dataDir() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(home, ".local", "share", "pomodoro"), nil
}

func Load() (*Stats, error) {
	d, err := dataDir()
	if err != nil {
		return &Stats{}, nil
	}
	data, err := os.ReadFile(filepath.Join(d, "stats.json"))
	if err != nil {
		return &Stats{}, nil
	}
	var s Stats
	if err := json.Unmarshal(data, &s); err != nil {
		return &Stats{}, nil
	}
	return &s, nil
}

func (s *Stats) Save() error {
	d, err := dataDir()
	if err != nil {
		return err
	}
	if err := os.MkdirAll(d, 0o755); err != nil {
		return err
	}
	data, err := json.MarshalIndent(s, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(d, "stats.json"), data, 0o644)
}

func (s *Stats) Add(sessionType string, minutes int) {
	s.Sessions = append(s.Sessions, Session{
		Type:        sessionType,
		Minutes:     minutes,
		CompletedAt: time.Now(),
	})
}

func (s *Stats) TodaySummary() (count, minutes int) {
	today := time.Now().Format("2006-01-02")
	for _, sess := range s.Sessions {
		if sess.CompletedAt.Format("2006-01-02") == today && sess.Type == "work" {
			count++
			minutes += sess.Minutes
		}
	}
	return
}

func (s *Stats) Print() {
	count, mins := s.TodaySummary()
	fmt.Printf("Today  %d work session(s)  ·  %d minutes of focus\n", count, mins)
	if len(s.Sessions) == 0 {
		return
	}
	fmt.Println()
	limit := 10
	start := len(s.Sessions) - limit
	if start < 0 {
		start = 0
	}
	for _, sess := range s.Sessions[start:] {
		fmt.Printf("  %s  %-12s  %d min\n",
			sess.CompletedAt.Format("2006-01-02 15:04"),
			sess.Type,
			sess.Minutes,
		)
	}
}
