package main

import (
	"context"
	"fmt"
	"net/http"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-contrib/logger"
	"github.com/gin-gonic/gin"
	"github.com/jinzhu/configor"
	"github.com/rs/zerolog/log"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	"go.opentelemetry.io/otel/sdk/trace"
	t "go.opentelemetry.io/otel/trace"
	"google.golang.org/grpc/credentials"
)

type Config struct {
	API       APIConfig       `default:"" yaml:"api"`
	Honeycomb HoneycombConfig `default:"" yaml:"honeycomb"`
}

type APIConfig struct {
	Port string `default:"" yaml:"port"`
}

type HoneycombConfig struct {
	APIKey  string `default:"" yaml:"apiKey"`
	Dataset string `default:"" yaml:"dataset"`
}

func setupExporter(config HoneycombConfig) (*otlptrace.Exporter, context.Context, error) {
	ctx := context.Background()
	client := otlptracegrpc.NewClient(
		otlptracegrpc.WithEndpoint("api.honeycomb.io:443"),
		otlptracegrpc.WithHeaders(map[string]string{
			"x-honeycomb-team":    config.APIKey,
			"x-honeycomb-dataset": config.Dataset,
		}),
		otlptracegrpc.WithTLSCredentials(credentials.NewClientTLSFromCert(nil, "")),
	)

	exporter, err := otlptrace.New(ctx, client)
	if err != nil {
		return nil, ctx, err
	}

	return exporter, ctx, err
}

func createBatcher(exporter *otlptrace.Exporter, ServiceName string) *trace.TracerProvider {
	return trace.NewTracerProvider(
		trace.WithBatcher(exporter),
		trace.WithResource(resource.NewWithAttributes("", attribute.KeyValue{
			Key:   "service.name",
			Value: attribute.StringValue(ServiceName),
		})),
	)
}

func setupOTelAutoInstrumentation(ServiceName string, config HoneycombConfig) (func(), error) {
	if config.APIKey == "" {
		return nil, fmt.Errorf("missing required env QQ_HONEYCOMB_TOKEN or honecombConfig.apiKey in config.json")
	}

	if config.Dataset == "" {
		return nil, fmt.Errorf("missing required env QQ_HONEYCOMB_DATASET or honecombConfig.dataset in config.json")
	}
	log.Debug().Str("serviceName", ServiceName).Msg("critical informtion passed for service, continuing setup")

	// create exporter to send spans to Honeycomb
	exporter, ctx, err := setupExporter(config)
	if err != nil {
		return nil, err
	}
	log.Debug().Str("exportedDataset", config.Dataset).Msg("data set up to be exported to Honeycomb")

	// the span batcher is going to package up all our spans into a trace
	tracer := createBatcher(exporter, ServiceName)

	// register the tracer provider with otel, sets the W3C Trace Context propagator as a global
	otel.SetTracerProvider(tracer)

	// register the trace context and baggage propagators so data is propagated across services
	otel.SetTextMapPropagator(
		propagation.NewCompositeTextMapPropagator(
			propagation.TraceContext{},
			propagation.Baggage{},
		),
	)

	return func() { _ = tracer.Shutdown(ctx) }, nil
}

func healthcheck(c *gin.Context) {
	c.JSON(http.StatusOK, map[string]bool{"ok": true})
}

func main() {
	c := Config{}
	cf := configor.New(&configor.Config{
		Debug:     false,
		ENVPrefix: "",
		Verbose:   false,
	})
	if _, err := os.Stat("config.yml"); err == nil {
		if err = cf.Load(&c, "config.yml"); err != nil {
			log.Fatal().Err(err).Msg("couldn't find the config file")
		}
	} else {
		log.Fatal().Err(err).Msg("config.yml doesn't exist")
	}
	log.Info().Interface("config", c).Msg("configs for test-actions app")

	log.Debug().Str("service", "qqcrm").Msg("spooling up open telemetry to send data to Honeycomb")
	shutdownFunc, otelErr := setupOTelAutoInstrumentation("qqcrm", c.Honeycomb)
	if otelErr != nil {
		log.Fatal().Err(otelErr).Msg("error setting up open telemetry for monitoring")
	}
	defer shutdownFunc()

	tracer := otel.Tracer("test-actions/main")
	mainContext, mainSpan := tracer.Start(
		context.Background(),
		"main#main",
		t.WithAttributes(),
	)
	defer mainSpan.End()

	_, setupSpan := tracer.Start(
		mainContext,
		"main#setup",
		t.WithAttributes(),
	)

	// Setup cors
	corsConfig := cors.DefaultConfig()
	corsConfig.AllowAllOrigins = true
	corsConfig.AllowCredentials = true
	corsConfig.AllowWebSockets = true
	corsConfig.AllowHeaders = []string{"GET", "PUT", "PATCH", "POST", "DELETE", "HEADERS", "TRACE"}
	corsConfig.AllowHeaders = []string{"Content-Type", "Accept-Encoding", "Accept-Language", "Authorization"}

	r := gin.New()
	r.Use(logger.SetLogger())
	r.Use(cors.New(corsConfig))

	r.GET("/healthz", healthcheck)

	setupSpan.End()
	log.Info().Msgf("Started server: %s", c.API.Port)
	log.Fatal().Err(r.Run(fmt.Sprintf(":%s", c.API.Port)))
}
