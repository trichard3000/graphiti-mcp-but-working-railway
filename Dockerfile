# syntax=docker/dockerfile:1.9
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install uv using official image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# For reproducibility, pin a version + SHA (best practice):
# COPY --from=ghcr.io/astral-sh/uv:0.11.20 /uv /uvx /usr/local/bin/
# Or with digest: COPY --from=ghcr.io/astral-sh/uv@sha256:xxxx... /uv /uvx /usr/local/bin/

# Configure uv for Docker
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never \
    MCP_SERVER_HOST="0.0.0.0" \
    PYTHONUNBUFFERED=1

# Create non-root user
RUN groupadd -r app && useradd -r -d /app -g app app

# Copy dependency files
COPY pyproject.toml uv.lock ./

# Install dependencies (frozen for reproducibility)
RUN uv sync --frozen --no-dev

# Copy application code
COPY graphiti_mcp_server/ ./graphiti_mcp_server/

# Change ownership
RUN chown -Rv app:app /app

USER app

EXPOSE 8000

CMD ["uv", "run", "python", "-m", "graphiti_mcp_server"]
