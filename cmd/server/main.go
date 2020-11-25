package main

import (
	"fmt"
	"io"
	"net/http"
)

func main() {
	handler := func(w http.ResponseWriter, _ *http.Request) {
		io.WriteString(w, "Hello World!\n")
	}

	http.HandleFunc("/", handler)

	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		fmt.Println(err.Error())
	}
}
