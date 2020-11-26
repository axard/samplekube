package main

import (
	"context"
	"errors"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/axard/samplekube/internal/cfg"
	"github.com/axard/samplekube/internal/log"
	"github.com/axard/samplekube/internal/router"
	"github.com/axard/samplekube/internal/version"
	"go.uber.org/zap"
)

const (
	defaultReadyDelay = 50 * time.Millisecond

	numberOfSignals = 2
)

func main() {
	log.Logger.Info(
		"start",
		zap.String("verions", version.Version),
	)

	server := http.Server{
		Addr:    cfg.Address(),
		Handler: router.New(),
	}

	go func() {
		<-time.After(defaultReadyDelay)
		cfg.SetReady(true)
	}()

	go func() {
		interrupt := make(chan os.Signal, numberOfSignals)
		signal.Notify(interrupt, syscall.SIGINT, syscall.SIGTERM)

		<-interrupt

		if err := server.Shutdown(context.Background()); err != nil {
			log.Logger.Error(
				"Server shutdown failed",
				zap.String("error", err.Error()),
			)
		}
	}()

	err := server.ListenAndServe()
	if err != nil {
		if errors.Is(err, http.ErrServerClosed) {
			log.Logger.Info("server closed")
		} else {
			log.Logger.Fatal(
				"Server start failed",
				zap.String("error", err.Error()),
			)
		}
	}
}
