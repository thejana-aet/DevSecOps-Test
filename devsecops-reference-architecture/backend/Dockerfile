# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Ensure go.mod and go.sum are in sync
RUN go mod tidy

# Build the binary
# CGO_ENABLED=0 for static binary
# -ldflags="-w -s" to strip debug info and reduce size
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -a -installsuffix cgo \
    -ldflags="-w -s" \
    -o server ./cmd/server

# Final stage - distroless for minimal size (~5MB)
FROM gcr.io/distroless/static-debian12:nonroot

# Copy binary from builder
COPY --from=builder /build/server /server

# Use non-root user (already set in distroless:nonroot)
# USER nonroot:nonroot is already the default

# Expose port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["/server"]
