#!/usr/bin/env bash
# patches/patch-cartservice.sh
set -euo pipefail
DEMO_DIR="${1:-../microservices-demo}"
DOCKERFILE="$DEMO_DIR/src/cartservice/src/Dockerfile"

cat > "$DOCKERFILE" <<'DOCKERFILE'
# ── Cart Service · .NET 8 · arm64 ──────────────────────────────
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS builder
WORKDIR /src
COPY . .
RUN dotnet publish cartservice.csproj -c Release -r linux-arm64 --self-contained true \
    -p:PublishSingleFile=true -p:PublishTrimmed=true -p:TrimMode=full -o /publish

FROM mcr.microsoft.com/dotnet/runtime-deps:8.0
WORKDIR /app
ADD https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/v0.4.18/grpc_health_probe-linux-arm64 /bin/grpc_health_pro

RUN chmod +x /bin/grpc_health_pro
ENV ASPNETCORE_URLS=http://*:7070
COPY --from=builder /publish .
EXPOSE 7070
ENTRYPOINT ["/app/cartservice"]
DOCKERFILE

echo "✓ Cart Service Dockerfile replaced with arm64 .NET 8 version"