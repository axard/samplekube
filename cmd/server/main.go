package main

import (
	"io"
	"net/http"

	"github.com/axard/samplekube/internal/log"
	"go.uber.org/zap"
)

func main() {
	handler := func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, "Hello World!\n")
		log.Logger.Info(
			"New request",
			zap.String("URL", r.URL.String()),
			zap.String("Method", r.URL.String()),
		)
	}

	http.HandleFunc("/", handler)

	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Logger.Fatal(
			"Server failed",
			zap.String("error", err.Error()),
		)
	}
}
