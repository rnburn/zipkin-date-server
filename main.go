package main

import (
	"flag"
	"fmt"
	"github.com/opentracing-contrib/go-stdlib/nethttp"
	zipkin "github.com/openzipkin/zipkin-go-opentracing"
	"net/http"
	"os"
	"time"
)

const (
	serviceName   = "date-server"
	hostPort      = "0.0.0.0:0"
	debug         = false
	sameSpan      = false
	traceID128Bit = true
)

func timeHandler(w http.ResponseWriter, r *http.Request) {
	tm := time.Now().Format(time.RFC1123)
	w.Write([]byte("The time is " + tm))
}

func main() {
	collectorHost := os.Getenv("ZIPKIN_COLLECTOR_HOST")
	if collectorHost == "" {
		collectorHost = "localhost"
	}
	collectorPort := os.Getenv("ZIPKIN_COLLECTOR_PORT")
	if collectorPort == "" {
		collectorPort = "9411"
	}
	flag.Parse()
	zipkinHTTPEndpoint := "http://" + collectorHost + ":" + collectorPort + "/api/v1/spans"
	collector, err := zipkin.NewHTTPCollector(zipkinHTTPEndpoint)
	if err != nil {
		fmt.Printf("unable to create Zipkin HTTP collector: %+v\n", err)
		os.Exit(-1)
	}

	recorder := zipkin.NewRecorder(collector, debug, hostPort, serviceName)

	tracer, err := zipkin.NewTracer(
		recorder,
		zipkin.ClientServerSameSpan(sameSpan),
		zipkin.TraceID128Bit(traceID128Bit))
	if err != nil {
		fmt.Printf("unable to create Zipkin tracer: %+v\n", err)
		os.Exit(-1)
	}

	handler := nethttp.Middleware(
		tracer,
		http.HandlerFunc(timeHandler))
	http.ListenAndServe(":8080", handler)
}
