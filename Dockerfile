FROM golang:alpine as builder

ENV TIME_ZONE=America/Lost_Angeles
WORKDIR /app
COPY ./ /app
RUN GOOS=linux go build