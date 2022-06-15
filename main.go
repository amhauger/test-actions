package main

import (
	"os"

	"github.com/jinzhu/configor"
	"github.com/rs/zerolog/log"
)

type Config struct {
	Honeycomb HoneycombConfig `default:"" yaml:"honeycomb"`
}

type HoneycombConfig struct {
	APIKey  string `default:"" yaml:"apiKey"`
	Dataset string `default:"" yaml:"dataset"`
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
	log.Info().Interface("config", c).Msg("honeycomb configs")
}
