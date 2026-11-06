//go:build darwin

package notify

import (
	"fmt"
	"os/exec"
)

func Send(title, message string) {
	script := fmt.Sprintf(`display notification %q with title %q`, message, title)
	_ = exec.Command("osascript", "-e", script).Run()
}

func PlaySound(name string) {
	sounds := map[string]string{
		"start":    "/System/Library/Sounds/Ping.aiff",
		"break":    "/System/Library/Sounds/Glass.aiff",
		"complete": "/System/Library/Sounds/Sosumi.aiff",
	}
	if path, ok := sounds[name]; ok {
		_ = exec.Command("afplay", path).Run()
	}
}
