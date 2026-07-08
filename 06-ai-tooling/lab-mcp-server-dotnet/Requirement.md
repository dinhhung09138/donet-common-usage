# lab-mcp-server-dotnet

Build a Model Context Protocol (MCP) server in .NET that exposes custom tools and resources to Claude and Cursor IDE.

## Objectives

- Understand MCP protocol: tools, resources, and prompts spec
- Build an MCP server using the official `ModelContextProtocol` .NET SDK
- Expose a `query_database` tool callable by Claude Desktop / Cursor
- Expose a `read_logs` resource returning structured log data
- Configure the server in Cursor's MCP settings (`.cursor/mcp.json`)
- Test tool invocation end-to-end from Cursor's AI chat

## Key Concepts

MCP protocol, `McpServerOptions`, `[McpServerTool]`, `[McpServerResource]`, `stdio` transport, JSON-RPC 2.0, tool schema (JSON Schema auto-generated from C# signatures), resource URI (`logs://recent`), `mcp.json` Cursor config, Claude Desktop `claude_desktop_config.json`

## Tasks

1. Create a .NET console app and add `ModelContextProtocol.Server` NuGet package
2. Define a `DatabaseTools` class with `[McpServerTool]` annotated methods
3. Implement `QueryOrders(string customerId)` that returns mock order data
4. Define a `LogResource` that serves the last 100 log lines as a resource
5. Wire up stdio transport in `Program.cs` and build the executable
6. Add the server to Cursor's `.cursor/mcp.json` and verify it appears in the AI tools panel
7. Test by asking Cursor's AI: "Query orders for customer C-001"

## Expected Output

- Working MCP server executable consumed by Cursor IDE
- Cursor AI correctly calls `QueryOrders` and displays the result in chat
