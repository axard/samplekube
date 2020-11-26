package cfg

import (
	"os"
	"sync"
	"sync/atomic"

	"github.com/axard/samplekube/internal/log"
	"go.uber.org/zap"
)

type setting struct {
	value string
	sync.Once
}

var (
	port setting

	readyFlag uint32
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

func SetReady(status bool) {
	if status {
		atomic.StoreUint32(&readyFlag, 1)
	} else {
		atomic.StoreUint32(&readyFlag, 0)
	}
}

func Ready() bool {
	value := atomic.LoadUint32(&readyFlag)

	if value == 1 {
		return true
	} else {
		return false
	}
}
