# syntax=docker/dockerfile:1.9
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install uv using the installer script (to /usr/local/bin so it is accessible by the non-root user)
ENV UV_INSTALL_DIR="/usr/local/bin"
#ADD https://astral.sh/uv/install.sh /uv-installer.sh
#RUN sh /uv-installer.sh && rm /uv-installer.sh
ARG UV_INSTALLER_SHA256
RUN curl -fsSL https://astral.sh/uv/install.sh -o /tmp/uv-installer.sh && \
    echo "${UV_INSTALLER_SHA256}  /tmp/uv-installer.sh" | sha256sum -c - && \
    sh /tmp/uv-installer.sh && \
    rm /tmp/uv-installer.sh

# Configure uv for optimal Docker usage
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    MCP_SERVER_HOST="0.0.0.0" \
    PYTHONUNBUFFERED=1

# Create non-root user
RUN groupadd -r app && useradd -r -d /app -g app app

# Copy project file
#COPY pyproject.toml ./
# Copy dependency manifests
COPY pyproject.toml uv.lock ./

# Generate lockfile and install dependencies
#RUN uv lock --upgrade && \
#    uv sync --no-dev
RUN uv sync --frozen --no-dev

# Copy application code
COPY graphiti_mcp_server/ ./graphiti_mcp_server/

# Change ownership to app user
RUN chown -Rv app:app /app

# Switch to non-root user
USER app

# Expose port
EXPOSE 8000

# Command to run the application
CMD ["uv", "run", "python", "-m", "graphiti_mcp_server"]
