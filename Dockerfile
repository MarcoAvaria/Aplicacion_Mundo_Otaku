FROM ghcr.io/cirruslabs/flutter:3.16.8 AS builder

ARG API_URL
ARG SOCKET_URL
WORKDIR /app

RUN case "$API_URL" in https://*) ;; *) echo "API_URL debe usar HTTPS" >&2; exit 1;; esac \
    && case "$SOCKET_URL" in https://*) ;; *) echo "SOCKET_URL debe usar HTTPS" >&2; exit 1;; esac

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN cp .env.template .env \
    && flutter build web --release --no-tree-shake-icons \
      --dart-define=API_URL="$API_URL" \
      --dart-define=SOCKET_URL="$SOCKET_URL"

FROM nginx:1.27-alpine AS runner

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 10000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD wget --quiet --tries=1 --spider http://127.0.0.1:10000/healthz || exit 1
