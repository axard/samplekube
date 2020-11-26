package handlers

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"

	"github.com/axard/samplekube/internal/cfg"
)

func TestRoot(t *testing.T) {
	type want struct {
		status int
		body   []byte
	}

	tests := []struct {
		name string
		want want
	}{
		{
			name: "Обработчик Root возвращает HTTP статус 200 и строку 'Hello World' в теле ответа",
			want: want{
				status: http.StatusOK,
				body:   []byte("Hello World\n"),
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			recorder := httptest.NewRecorder()
			Root().ServeHTTP(recorder, nil)

			resp := recorder.Result()

			if resp.StatusCode != tt.want.status {
				t.Errorf("got = %v, want = %v", resp.StatusCode, tt.want.status)
			}

			got, err := ioutil.ReadAll(resp.Body)
			resp.Body.Close()
			if err != nil {
				t.Errorf("unexpected error: %v", err)
			}

			if !reflect.DeepEqual(got, tt.want.body) {
				t.Errorf("got = %v, want = %v", got, tt.want.body)
			}
		})
	}
}

func TestHealthz(t *testing.T) {
	tests := []struct {
		name string
		want int
	}{
		{
			name: "Обработчик health возвращает HTTP статус 200",
			want: http.StatusOK,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			recorder := httptest.NewRecorder()
			Healthz().ServeHTTP(recorder, nil)

			resp := recorder.Result()

			got := resp.StatusCode
			if got != tt.want {
				t.Errorf("got = %v, want = %v", got, tt.want)
			}
		})
	}
}

func TestReadyz(t *testing.T) {
	type args struct {
		ready bool
	}

	tests := []struct {
		name string
		args args
		want int
	}{
		{
			name: "Обработки Readyz возвращает HTTP статус 503, когда флаг по умолчанию",
			want: http.StatusServiceUnavailable,
		},
		{
			name: "Обработчик Readyz возвращает HTTP статус 200, при установке флага готовности",
			args: args{
				ready: true,
			},
			want: http.StatusOK,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cfg.SetReady(tt.args.ready)

			recorder := httptest.NewRecorder()
			Readyz().ServeHTTP(recorder, nil)

			resp := recorder.Result()

			got := resp.StatusCode
			if got != tt.want {
				t.Errorf("got = %v, want = %v", got, tt.want)
			}
		})
	}
}
