package main

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
)

func main() {
	fmt.Println("Lorem impsum other latin stuff")

	r := gin.New()
	r.GET("/healthcheck", func(c *gin.Context) { c.JSON(http.StatusOK, map[string]bool{"ok": true}) })
}
