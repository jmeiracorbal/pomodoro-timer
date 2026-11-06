//go:build windows

package notify

import (
	"fmt"
	"os/exec"
)

func Send(title, message string) {
	script := fmt.Sprintf(
		`Add-Type -AssemblyName System.Windows.Forms; `+
			`[System.Windows.Forms.MessageBox]::Show('%s', '%s')`,
		message, title,
	)
	_ = exec.Command("powershell", "-Command", script).Run()
}

func PlaySound(_ string) {
	_ = exec.Command("powershell", "-Command", `[System.Console]::Beep(880, 400)`).Run()
}
