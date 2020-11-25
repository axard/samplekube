package router

import (
	"github.com/axard/samplekube/internal/handlers"
	"github.com/gorilla/mux"
)

func Router() *mux.Router {
	r := mux.NewRouter()

	r.Handle("/", handlers.Root())

	return r
}
