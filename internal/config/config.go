package config

import (
	"encoding/json"
	"os"
	"path/filepath"
)

type Config struct {
	WorkMinutes   int  `json:"work_minutes"`
	ShortBreak    int  `json:"short_break_minutes"`
	LongBreak     int  `json:"long_break_minutes"`
	Cycles        int  `json:"cycles"`
	Sound         bool `json:"sound"`
	Notifications bool `json:"notifications"`
}

func Default() Config {
	return Config{
		WorkMinutes:   25,
		ShortBreak:    5,
		LongBreak:     15,
		Cycles:        4,
		Sound:         true,
		Notifications: true,
	}
}

func configDir() (string, error) {
	base, err := os.UserConfigDir()
	if err != nil {
		return "", err
	}
	return filepath.Join(base, "pomodoro"), nil
}

func Load() (Config, error) {
	d, err := configDir()
	if err != nil {
		return Default(), nil
	}
	data, err := os.ReadFile(filepath.Join(d, "config.json"))
	if err != nil {
		return Default(), nil
	}
	cfg := Default()
	if err := json.Unmarshal(data, &cfg); err != nil {
		return Default(), nil
	}
	return cfg, nil
}

func Save(cfg Config) error {
	d, err := configDir()
	if err != nil {
		return err
	}
	if err := os.MkdirAll(d, 0o755); err != nil {
		return err
	}
	data, err := json.MarshalIndent(cfg, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(d, "config.json"), data, 0o644)
}
