# Flutter se instala desde el archivo oficial en vez de usar una imagen ya
# hecha. La imagen que se usaba (ghcr.io/cirruslabs/flutter) llega hasta la
# 3.44.0 y no publica la 3.47.5; tomar su etiqueta `stable` haría que la demo
# cambiara de Flutter sola, sin que nadie lo decidiera. Así la versión es la
# misma que en local y en CI, y la suma SHA-256 impide que el archivo cambie
# por debajo: si no coincide, la construcción se detiene.
FROM debian:bookworm-slim AS builder

ARG FLUTTER_VERSION=3.47.5
ARG FLUTTER_SHA256=2132e990f236f8d22e7c6314b29a191a95b10d7cbcfec9b4e2e303d996652cbb

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/flutter.tar.xz \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory /opt/flutter

ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config --no-analytics --enable-web && flutter precache --web

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
