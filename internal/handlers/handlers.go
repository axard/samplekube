package handlers

import (
	"io"
	"net/http"
)

func Root() http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, _ *http.Request) {
		io.WriteString(rw, "Hello World\n")
	})
}
