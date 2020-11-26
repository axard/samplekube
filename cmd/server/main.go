package main

import (
	"net/http"
	"time"

	"github.com/axard/samplekube/internal/cfg"
	"github.com/axard/samplekube/internal/log"
	"github.com/axard/samplekube/internal/router"
	"github.com/axard/samplekube/internal/version"
	"go.uber.org/zap"
)

const (
	defaultReadyDelay = 50 * time.Millisecond
)

func main() {
	log.Logger.Info(
		"start",
		zap.String("verions", version.Version),
	)

	go func() {
		<-time.After(defaultReadyDelay)
		cfg.SetReady(true)
	}()

	err := http.ListenAndServe(cfg.Address(), router.New())
	if err != nil {
		log.Logger.Fatal(
			"Server failed",
			zap.String("error", err.Error()),
		)
	}
}
