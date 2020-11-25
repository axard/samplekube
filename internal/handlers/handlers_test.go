package handlers

import (
	"io/ioutil"
	"net/http/httptest"
	"reflect"
	"testing"
)

func TestRoot(t *testing.T) {
	tests := []struct {
		name     string
		want     []byte
		wantResp bool
		wantBody bool
	}{
		{
			name:     "Проверка работы обработчика",
			want:     []byte("Hello World\n"),
			wantResp: true,
			wantBody: true,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			recorder := httptest.NewRecorder()
			Root().ServeHTTP(recorder, nil)

			resp := recorder.Result()
			if (resp != nil) != tt.wantResp {
				t.Errorf("got = %v, wantResp = %v", (resp == nil), tt.wantResp)
			}

			if (resp.Body != nil) != tt.wantBody {
				t.Errorf("got = %v, wantBody = %v", (resp.Body == nil), tt.wantBody)
			}

			got, err := ioutil.ReadAll(resp.Body)
			resp.Body.Close()
			if err != nil {
				t.Errorf("unexpected error: %v", err)
			}

			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("got = %v, want = %v", got, tt.want)
			}
		})
	}
}
