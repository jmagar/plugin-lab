from __future__ import annotations

from dataclasses import dataclass


@dataclass(slots=True)
class MyPluginClient:
    """Thin upstream client placeholder for scaffolded plugins."""

    base_url: str
    api_key: str | None = None

    async def health(self) -> dict[str, str]:
        return {"status": "ok", "base_url": self.base_url}
