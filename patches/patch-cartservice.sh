#!/usr/bin/env bash
set -euo pipefail
DEMO_DIR="${1:-../microservices-demo}"

echo "→ Patching Cart Service for arm64 and .NET 8 …"

# Dockerfile tweaks
apply_docker_patch() {
  perl -0777 -i -pe '
    s|mcr\.microsoft\.com/dotnet/sdk:.*|mcr.microsoft.com/dotnet/sdk:8.0 AS builder|;
    s|dotnet publish.*|dotnet publish cartservice.csproj -c Release -r linux-arm64 --self-contained true -o /publish|;
    s|FROM .*runtime-deps.*|FROM mcr.microsoft.com/dotnet/runtime-deps:8.0|;
    $_ .= "\nADD https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/v0.4.18/grpc_health_probe-linux-arm64 /bin/grpc_health_probe\nRUN chmod +x /bin/grpc_health_probe\nENV ASPNETCORE_URLS=http://*:7070" if $.==0
  ' "$DEMO_DIR/src/cartservice/src/Dockerfile"
}

# csproj tweaks
apply_csproj_patch() {
  perl -0777 -i -pe '
    s|</Project>|  <PropertyGroup>\n    <WarningsNotAsErrors>NU1605</WarningsNotAsErrors>\n  </PropertyGroup>\n  <ItemGroup>\n    <PackageReference Include="Grpc.AspNetCore" Version="2.60.0"/>\n    <PackageReference Include="Grpc.Tools" Version="2.60.0" PrivateAssets="All"/>\n  </ItemGroup>\n</Project>|s;
  ' "$DEMO_DIR/src/cartservice/src/cartservice.csproj"
}

apply_docker_patch
apply_csproj_patch
echo "✓ Cart Service patched"
