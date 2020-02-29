FROM golang AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./
RUN env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main .

FROM ubuntu AS server
WORKDIR /app

RUN apt-get update
RUN apt-get install -y ca-certificates

# set up CA certs?
COPY GIAG2.crt /usr/local/share/ca-certificates/
RUN /usr/sbin/update-ca-certificates

# copied from official postgrest Dockerfile -- postgrest needs these .so to run
# Install libpq5
RUN apt-get -qq update && \
    apt-get -qq install -y --no-install-recommends libpq5 && \
    apt-get -qq clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# also copied from official postgrest Dockerfile; probably should've just used that
ENV PGRST_DB_URI= \
    PGRST_DB_SCHEMA=public \
    PGRST_DB_ANON_ROLE= \
    PGRST_DB_POOL=100 \
    PGRST_DB_EXTRA_SEARCH_PATH=public \
    PGRST_SERVER_HOST=*4 \
    PGRST_SERVER_PORT=3000 \
    PGRST_OPENAPI_SERVER_PROXY_URI= \
    PGRST_JWT_SECRET= \
    PGRST_SECRET_IS_BASE64=false \
    PGRST_JWT_AUD= \
    PGRST_MAX_ROWS= \
    PGRST_PRE_REQUEST= \
    PGRST_ROLE_CLAIM_KEY=".role" \
    PGRST_ROOT_SPEC= \
    PGRST_RAW_MEDIA_TYPES=

COPY postgrest ./
COPY postgrest.conf ./
COPY cofty_firebase_creds.json ./
COPY container_startup.sh ./

COPY --from=builder /app/main ./
CMD ["./container_startup.sh"]
