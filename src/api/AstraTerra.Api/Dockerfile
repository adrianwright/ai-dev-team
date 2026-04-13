FROM node:20-alpine AS frontend-build
WORKDIR /web
COPY src/web/package.json src/web/package-lock.json* ./
RUN npm ci
COPY src/web/ .
RUN npm run build

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY src/api/AstraTerra.Api/AstraTerra.Api.csproj ./
RUN dotnet restore ./AstraTerra.Api.csproj

COPY src/api/AstraTerra.Api/ .
RUN dotnet publish ./AstraTerra.Api.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

# Install nginx
RUN apt-get update && apt-get install -y --no-install-recommends nginx && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy .NET app
COPY --from=build /app/publish .

# Copy SPA into nginx html root
COPY --from=frontend-build /web/dist /usr/share/nginx/html

# Copy nginx config and entrypoint
COPY src/web/nginx.conf /etc/nginx/conf.d/default.conf
COPY src/web/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# .NET listens on 5000 internally, nginx on 8080 externally
ENV ASPNETCORE_URLS=http://+:5000
EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]
