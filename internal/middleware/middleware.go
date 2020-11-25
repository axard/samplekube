package middleware

import (
	"net/http"

	"github.com/axard/samplekube/internal/log"
	"go.uber.org/zap"
)

func Log(h http.Handler) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, r *http.Request) {
		log.Logger.Info(
			"http request",
			zap.String("URL", r.URL.String()),
			zap.String("Method", r.Method),
		)

		h.ServeHTTP(rw, r)
	})
}
