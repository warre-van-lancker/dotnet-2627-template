#!/bin/bash
set -euo pipefail

# 1. Setup temporary build directory
echo "Creating temporary build workspace..."
mkdir -p tempdir

# 2. Stage the solution and source files
# Copy the solution file and the entire src directory to preserve project references
echo "Staging source files..."
cp Rise.sln tempdir/
cp -r src tempdir/
cp -r tests tempdir/

# 3. Generate the Multi-Stage Dockerfile
echo "Generating Dockerfile..."
cat > tempdir/Dockerfile << '_EOF_'
# Build and Publish stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /app

# Copy solution and project definitions first to leverage layer caching for restore
COPY Rise.sln ./
COPY src/ ./src/
COPY tests/ ./tests/

# Restore dependencies for all projects in the solution
RUN dotnet restore Rise.sln

# Publish the Rise.Server startup project (which builds dependent projects & hosts Blazor WASM)
WORKDIR /app/src/Rise.Server
RUN dotnet publish -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Copy published artifacts from build stage
COPY --from=build /app/publish .

# Configure ASP.NET to listen on port 5001 inside the container
ENV ASPNETCORE_URLS=http://+:5001
ENV ASPNETCORE_ENVIRONMENT=Development

EXPOSE 5001

# Entry point starts the compiled Rise.Server assembly
ENTRYPOINT ["dotnet", "Rise.Server.dll"]
_EOF_

# 4. Build Docker image
cd tempdir || exit
echo "Building .NET 10 Docker image..."
docker build -t rise-app .

# 5. Stop and remove existing container if running
if [ "$(docker ps -aq -f name=rise-running)" ]; then
    echo "Stopping and removing existing container..."
    docker rm -f rise-running
fi

# 6. Run container with mapped port 5001 and persistent volume for SQLite
echo "Starting container on http://localhost:5001..."
docker run -t -d \
  -p 5001:5001 \
  -v rise_sqlite_data:/app/data \
  --name rise-running \
  rise-app

# 7. Check container status
docker ps -a --filter "name=rise-running"

# Clean up local staged temp directory (optional)
cd ..
rm -rf tempdir
echo "Done! Rise.Server is accessible at http://localhost:5001"
