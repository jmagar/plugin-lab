#!/usr/bin/env node

import express from "express";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { z } from "zod";
import { MyPluginClient } from "./client.js";

const serverName = "my-plugin-mcp";
const version = "0.1.0";
const transport = process.env.MY_SERVICE_MCP_TRANSPORT ?? "http";
const host = process.env.MY_SERVICE_MCP_HOST ?? "0.0.0.0";
const port = Number(process.env.MY_SERVICE_MCP_PORT ?? "9000");
const client = new MyPluginClient(
  process.env.MY_SERVICE_URL ?? "",
  process.env.MY_SERVICE_API_KEY,
);

function createServer(): McpServer {
  const server = new McpServer({ name: serverName, version });

  server.tool("my_service_help", "Show available actions.", {}, async () => ({
    content: [
      {
        type: "text",
        text:
          "# My Plugin MCP Server\n\n" +
          "Use `my_service` with `action` and optional `subaction`.\n\n" +
          "Built-in actions: `help`, `health`.",
      },
    ],
  }));

  server.tool(
    "my_service",
    "Unified tool using action + subaction routing.",
    {
      action: z.string(),
      subaction: z.string().optional(),
    },
    async ({ action, subaction }) => {
      if (action === "help") {
        return {
          content: [{ type: "text", text: "Use action=health to validate the scaffolded server." }],
        };
      }

      if (action === "health") {
        const upstream = await client.health();
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify({ ok: true, action, subaction: subaction ?? "", upstream }, null, 2),
            },
          ],
        };
      }

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                ok: false,
                error: `Unsupported action: ${action}`,
                hint: "Call my_service_help for the supported action list.",
              },
              null,
              2,
            ),
          },
        ],
      };
    },
  );

  return server;
}

async function runStdio(): Promise<void> {
  const server = createServer();
  await server.connect(new StdioServerTransport());
}

async function runHttp(): Promise<void> {
  const mcpServer = createServer();
  const app = express();
  app.use(express.json());
  app.get("/health", (_req, res) => {
    res.json({ status: "ok", service: serverName });
  });
  app.all("/mcp", async (req, res) => {
    const transport = new StreamableHTTPServerTransport({
      sessionIdGenerator: undefined,
    });
    await mcpServer.connect(transport);
    await transport.handleRequest(req, res, req.body);
  });
  app.listen(port, host, () => {
    console.error(`${serverName} listening on http://${host}:${port}/mcp`);
  });
}

const runner = transport === "stdio" ? runStdio : runHttp;
runner().catch((error) => {
  console.error(error);
  process.exit(1);
});
