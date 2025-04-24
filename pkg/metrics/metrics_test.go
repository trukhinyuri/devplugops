package metrics

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestNewHandler(t *testing.T) {
	handler := NewHandler()
	if handler == nil {
		t.Error("NewHandler returned nil")
	}
}

func TestInstrumentHandler(t *testing.T) {
	// Create a test handler
	testHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("test"))
	})

	// Wrap it with our instrumentation
	instrumentedHandler := InstrumentHandler("/test", testHandler)

	// Create a request to pass to our handler
	req, err := http.NewRequest("GET", "/test", nil)
	if err != nil {
		t.Fatal(err)
	}

	// Create a ResponseRecorder to record the response
	rr := httptest.NewRecorder()

	// Call the handler
	instrumentedHandler.ServeHTTP(rr, req)

	// Check the status code
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v",
			status, http.StatusOK)
	}

	// Check the response body
	expected := "test"
	if rr.Body.String() != expected {
		t.Errorf("handler returned unexpected body: got %v want %v",
			rr.Body.String(), expected)
	}
}

func TestResponseWriter_WriteHeader(t *testing.T) {
	// Create a test ResponseWriter
	rw := &responseWriter{
		ResponseWriter: httptest.NewRecorder(),
		statusCode:     http.StatusOK,
	}

	// Call WriteHeader with a different status code
	rw.WriteHeader(http.StatusNotFound)

	// Check that the status code was updated
	if rw.statusCode != http.StatusNotFound {
		t.Errorf("WriteHeader did not update statusCode: got %v want %v",
			rw.statusCode, http.StatusNotFound)
	}
}