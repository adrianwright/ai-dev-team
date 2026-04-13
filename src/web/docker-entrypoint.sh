#!/bin/sh
set -e

# Start the .NET API in the background
cd /app && dotnet AstraTerra.Api.dll &

# Start nginx in the foreground
nginx -g 'daemon off;'
