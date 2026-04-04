from __future__ import annotations

import os

from fastmcp import FastMCP

from .client import MyPluginClient

MY_SERVICE_URL = os.getenv("MY_SERVICE_URL", "")
MY_SERVICE_API_KEY = os.getenv("MY_SERVICE_API_KEY")
MY_SERVICE_MCP_HOST = os.getenv("MY_SERVICE_MCP_HOST", "0.0.0.0")
MY_SERVICE_MCP_PORT = int(os.getenv("MY_SERVICE_MCP_PORT", "9000"))
MY_SERVICE_MCP_TRANSPORT = os.getenv("MY_SERVICE_MCP_TRANSPORT", "http").lower()

client = MyPluginClient(base_url=MY_SERVICE_URL, api_key=MY_SERVICE_API_KEY)
mcp = FastMCP(
    name="My Plugin MCP Server",
    instructions="Use my_service_help first to see supported actions.",
)


@mcp.tool()
async def my_service_help() -> str:
    return (
        "# My Plugin MCP Server\n\n"
        "Use the `my_service` tool with `action` and optional `subaction`.\n\n"
        "## Built-in actions\n"
        "- `help`\n"
        "- `health`\n"
    )


@mcp.tool()
async def my_service(action: str, subaction: str = "") -> dict[str, object]:
    if action == "help":
        return {"ok": True, "action": action, "subaction": subaction, "message": await my_service_help()}
    if action == "health":
        return {"ok": True, "action": action, "subaction": subaction, "upstream": await client.health()}
    return {
        "ok": False,
        "error": f"Unsupported action: {action}",
        "hint": "Call my_service_help for the supported action list.",
    }


def main() -> None:
    if MY_SERVICE_MCP_TRANSPORT == "stdio":
        mcp.run(transport="stdio")
        return

    mcp.run(
        transport="streamable-http",
        host=MY_SERVICE_MCP_HOST,
        port=MY_SERVICE_MCP_PORT,
        path="/mcp",
    )


if __name__ == "__main__":
    main()
