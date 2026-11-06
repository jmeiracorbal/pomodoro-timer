//go:build linux

package notify

import "os/exec"

func Send(title, message string) {
	_ = exec.Command("notify-send", title, message).Run()
}

func PlaySound(name string) {
	sounds := map[string]string{
		"start":    "/usr/share/sounds/freedesktop/stereo/message.oga",
		"break":    "/usr/share/sounds/freedesktop/stereo/complete.oga",
		"complete": "/usr/share/sounds/freedesktop/stereo/bell.oga",
	}
	path, ok := sounds[name]
	if !ok {
		return
	}
	if exec.Command("paplay", path).Run() != nil {
		_ = exec.Command("aplay", path).Run()
	}
}
