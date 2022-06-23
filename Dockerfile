FROM golang:1.15-alpine as builder

RUN apk --no-cache add ca-certificates && \
    rm -Rf /var/cache/apk/*

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

ARG LDFLAGS

# Copy the go source
COPY version/ version/
COPY cmd/ cmd/
COPY pkg/ pkg/
COPY main.go main.go

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "${LDFLAGS}" -o aliyun-exporter main.go
# Run
FROM alpine:3.10
WORKDIR /
RUN addgroup -S juloinfra && adduser -S juloinfra -G juloinfra
USER juloinfra

EXPOSE 9527

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /workspace/aliyun-exporter /usr/local/bin/aliyun-exporter

ENTRYPOINT ["/usr/local/bin/aliyun-exporter "]