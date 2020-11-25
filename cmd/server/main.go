package main

import (
	"net/http"

	"github.com/axard/samplekube/internal/cfg"
	"github.com/axard/samplekube/internal/log"
	"github.com/axard/samplekube/internal/router"
	"go.uber.org/zap"
)

func main() {
	err := http.ListenAndServe(cfg.Address(), router.New())
	if err != nil {
		log.Logger.Fatal(
			"Server failed",
			zap.String("error", err.Error()),
		)
	}
}
