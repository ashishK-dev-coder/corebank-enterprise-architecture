# Stage 1: Build Binary
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod init corebank-identity-go && \
    go get github.com/golang-jwt/jwt/v5 && \
    go mod tidy
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o identity-service .

# Stage 2: Production Runtime
FROM alpine:3.19
RUN addgroup -S bankgroup && adduser -S bankuser -G bankgroup
WORKDIR /app
COPY --from=builder /app/identity-service .
USER bankuser
EXPOSE 5000
CMD ["./identity-service"]
