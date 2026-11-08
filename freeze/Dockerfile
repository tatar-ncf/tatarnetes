# Built from the repository root: docker build -f freeze/Dockerfile .
FROM golang:1.26 AS build
WORKDIR /src
COPY go.mod assets.go ./
COPY data ./data
COPY locale ./locale
COPY freeze ./freeze
COPY cmd/tatarnetes-freeze ./cmd/tatarnetes-freeze
RUN CGO_ENABLED=0 go build -trimpath -ldflags=-s -o /tatarnetes-freeze ./cmd/tatarnetes-freeze

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /tatarnetes-freeze /tatarnetes-freeze
USER 65532:65532
ENTRYPOINT ["/tatarnetes-freeze"]
