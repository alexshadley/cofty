FROM golang AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY main.go ./
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main .

FROM scratch AS server
COPY --from=builder /app/main /
CMD ["/main"]