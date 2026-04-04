package core

import (
	"fmt"
	"strings"
	"sync/atomic"
	"time"
)

var idCounter atomic.Uint64

func NextID(prefix string) string {
	prefix = strings.TrimSpace(prefix)
	if prefix == "" {
		prefix = "id"
	}
	n := idCounter.Add(1)
	return fmt.Sprintf("%s_%s_%03d", prefix, time.Now().UTC().Format("20060102T150405.000000000"), n)
}
