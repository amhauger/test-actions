module test-actions

go 1.15

require (
	github.com/gin-contrib/cors v1.3.1
	github.com/gin-contrib/logger v0.2.2
	github.com/gin-gonic/gin v1.8.1
	github.com/jinzhu/configor v1.2.1
	github.com/rs/zerolog v1.27.0
	go.opentelemetry.io/otel v1.7.0
	go.opentelemetry.io/otel/exporters/otlp/otlptrace v1.7.0
	go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc v1.7.0
	go.opentelemetry.io/otel/sdk v1.7.0
	go.opentelemetry.io/otel/trace v1.7.0
	google.golang.org/grpc v1.47.0
)
