FROM golang:alpine as builder

ENV TIME_ZONE=America/Lost_Angeles
WORKDIR /app
COPY ./ /app
RUN GOOS=linux go build

FROM alpine:3

ENV API_PORT 8080

COPY --from=builder /usr/lib/lib* /usr/lib
WORKDIR /app

COPY --from=builder /app ./

EXPOSE $API_PORT

CMD ["/app/test-actions", "run"]