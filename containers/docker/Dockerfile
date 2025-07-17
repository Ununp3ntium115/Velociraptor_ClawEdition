# Velociraptor Server Docker Container
# Multi-stage build for optimized container size

# Build stage
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04 AS builder

# Set working directory
WORKDIR /build

# Copy PowerShell modules and scripts
COPY modules/ ./modules/
COPY scripts/ ./scripts/
COPY templates/ ./templates/

# Install required PowerShell modules
RUN pwsh -Command "Install-Module -Name powershell-yaml -Force -Scope AllUsers"

# Runtime stage
FROM mcr.microsoft.com/powershell:7.4-ubuntu-22.04

# Metadata
LABEL maintainer="Velociraptor Community" \
      description="Containerized Velociraptor DFIR platform" \
      version="1.0.0" \
      org.opencontainers.image.title="Velociraptor Server" \
      org.opencontainers.image.description="Digital forensics and incident response platform" \
      org.opencontainers.image.vendor="Velociraptor Community" \
      org.opencontainers.image.licenses="Apache-2.0"

# Create velociraptor user and group
RUN groupadd -r velociraptor && \
    useradd -r -g velociraptor -d /opt/velociraptor -s /bin/bash velociraptor

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        wget \
        unzip \
        jq \
        openssl \
        dumb-init && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install PowerShell modules
RUN pwsh -Command "Install-Module -Name powershell-yaml -Force -Scope AllUsers"

# Create directory structure
RUN mkdir -p /opt/velociraptor/{bin,config,data,logs,artifacts,temp} && \
    chown -R velociraptor:velociraptor /opt/velociraptor

# Copy application files from builder
COPY --from=builder --chown=velociraptor:velociraptor /build/ /opt/velociraptor/scripts/

# Copy container-specific scripts
COPY containers/docker/scripts/ /opt/velociraptor/container-scripts/
RUN chmod +x /opt/velociraptor/container-scripts/*.sh

# Set working directory
WORKDIR /opt/velociraptor

# Expose ports
EXPOSE 8000 8080 9999

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /opt/velociraptor/container-scripts/healthcheck.sh

# Volume mounts
VOLUME ["/opt/velociraptor/config", "/opt/velociraptor/data", "/opt/velociraptor/logs"]

# Switch to non-root user
USER velociraptor

# Entry point
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/opt/velociraptor/container-scripts/entrypoint.sh"]