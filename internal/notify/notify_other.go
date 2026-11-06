//go:build !darwin && !linux && !windows

package notify

func Send(_, _ string)  {}
func PlaySound(_ string) {}
