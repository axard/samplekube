package router

import (
	"net/http"

	"github.com/axard/samplekube/internal/handlers"
	"github.com/axard/samplekube/internal/middleware"
	"github.com/gorilla/mux"
)

func New() http.Handler {
	r := mux.NewRouter()

	r.Handle("/", handlers.Root())
	r.Use(middleware.Log)

	return r
}
