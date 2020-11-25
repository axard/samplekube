package cfg

import (
	"os"
	"sync"

	"github.com/axard/samplekube/internal/log"
	"go.uber.org/zap"
)

type setting struct {
	value string
	sync.Once
}

var (
	port setting
)

const (
	defaultPort = "8080"
)

func Port() string {
	port.Do(func() {
		value := os.Getenv("SK_HTTP_PORT")
		if value == "" {
			value = defaultPort
		}

		log.Logger.Info(
			"configuration",
			zap.String("http_port", value),
		)

		port.value = value
	})

	return port.value
}

func Address() string {
	return ":" + Port()
}
