package main

import (
	"net/http"

	"github.com/axard/samplekube/internal/log"
	"github.com/axard/samplekube/internal/middleware"
	"github.com/axard/samplekube/internal/router"
	"go.uber.org/zap"
)

func main() {
	router := router.Router()
	router.Use(middleware.Log)

	err := http.ListenAndServe(":8080", router)
	if err != nil {
		log.Logger.Fatal(
			"Server failed",
			zap.String("error", err.Error()),
		)
	}
}
