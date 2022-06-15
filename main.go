package main

import (
	"fmt"
	"net/http"
	"os"

	"github.com/gin-contrib/cors"
	"github.com/gin-contrib/logger"
	"github.com/gin-gonic/gin"
	"github.com/jinzhu/configor"
	"github.com/rs/zerolog/log"
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

	log.Info().Msgf("Started server: %s", c.API.Port)
	log.Fatal().Err(r.Run(fmt.Sprintf(":%s", c.API.Port)))
}
