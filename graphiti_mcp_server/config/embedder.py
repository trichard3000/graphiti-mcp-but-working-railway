"""
Embedder client configuration for Graphiti MCP Server.
"""

import os

from graphiti_core.embedder.client import EmbedderClient
from graphiti_core.embedder.openai import OpenAIEmbedder, OpenAIEmbedderConfig
from pydantic import BaseModel

from graphiti_mcp_server.config.settings import DEFAULT_EMBEDDER_MODEL


class GraphitiEmbedderConfig(BaseModel):
    """Configuration for the embedder client.

    Centralizes all embedding-related configuration parameters.
    """

    model: str = DEFAULT_EMBEDDER_MODEL
    api_key: str | None = None
    base_url: str | None = None   # NEW

    @classmethod
    def from_env(cls) -> 'GraphitiEmbedderConfig':
        """Create embedder configuration from environment variables."""

        # Get model from environment, or use default if not set or empty
        model_env = os.environ.get('EMBEDDER_MODEL_NAME', '')
        model = model_env if model_env.strip() else DEFAULT_EMBEDDER_MODEL

        # Prefer EMBEDDER_BASE_URL; fall back to OPENAI_BASE_URL for backward compat
        base_url_env = os.environ.get('EMBEDDER_BASE_URL', '') or os.environ.get('OPENAI_BASE_URL', '')
        base_url = base_url_env.strip() if base_url_env.strip() else None

        return cls(
            model=model,
            api_key=os.environ.get('OPENAI_API_KEY'),
            base_url=base_url,
        )

    def create_client(self) -> EmbedderClient | None:
        if not self.api_key:
            return None

        embedder_config = OpenAIEmbedderConfig(
            api_key=self.api_key,
            embedding_model=self.model,
            **({"base_url": self.base_url} if self.base_url else {})
        )

        return OpenAIEmbedder(config=embedder_config)
