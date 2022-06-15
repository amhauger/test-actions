# test-actions

### Build Container
docker buildx build -t test-actions:latest .

### Run Container
docker run -p 127.0.0.1:8080:8080 test-actions:latest