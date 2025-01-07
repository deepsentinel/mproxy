# Build stage
FROM golang:1.21 AS builder

WORKDIR /go/src/mproxy

# Set environment variables for Go modules
ENV GOPROXY=direct
ENV GOSUMDB=off
ENV GO111MODULE=on

# Copy go mod files first for better cache
COPY go.mod go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY . .

# Build the application with static linking
RUN CGO_ENABLED=0 make

# Final stage
FROM debian:bookworm-slim

WORKDIR /app

# Install necessary runtime dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy the binary and config files from builder
COPY --from=builder /go/src/mproxy/build/mproxy /app/
COPY .env /app/

# Create directory for certificates
RUN mkdir -p /app/ssl/certs

# Expose all necessary ports
# MQTT
EXPOSE 1883
EXPOSE 1884
EXPOSE 8081
EXPOSE 8080
# MQTT/TLS
EXPOSE 8883
# MQTT/mTLS
EXPOSE 8884
# MQTT/WS
EXPOSE 8083
# MQTT/WSS
EXPOSE 8084
# MQTT/WSS/mTLS
EXPOSE 8085
EXPOSE 8443

WORKDIR /app
ENTRYPOINT ["/app/mproxy"] 