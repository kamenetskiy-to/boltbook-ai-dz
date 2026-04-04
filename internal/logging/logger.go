package logging

import (
	"io"
	"log/slog"
	"os"
)

func NewJSONLogger(level slog.Level, w io.Writer) *slog.Logger {
	if w == nil {
		w = os.Stdout
	}
	return slog.New(slog.NewJSONHandler(w, &slog.HandlerOptions{Level: level}))
}
