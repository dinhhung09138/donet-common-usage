# lab-claude-api-tooluse

Anthropic Claude Messages API in .NET — tool use (function calling), streaming, and multi-turn conversations.

## Objectives

- Send messages to Claude using `Anthropic.SDK` for .NET
- Define tools (functions) that Claude can call during a response
- Handle `tool_use` and `tool_result` blocks in the conversation loop
- Stream partial responses using server-sent events
- Design effective system prompts for a backend assistant persona
- Stay within token budgets and handle context window limits

## Key Concepts

`Anthropic.SDK`, `AnthropicClient`, `MessageRequest`, `MessageResponse`, `ContentBlock`, `ToolUseBlock`, `ToolResultBlock`, tool definition schema (JSON Schema), streaming `IAsyncEnumerable`, system prompt, multi-turn conversation loop, `max_tokens`, `InputTokens` / `OutputTokens`

## Tasks

1. Install `Anthropic.SDK` and authenticate with API key via `DefaultAzureCredential` alternative
2. Send a simple message and display Claude's response
3. Define a `search_database` tool with JSON Schema parameters
4. Implement the agentic loop: detect `tool_use` → execute tool → send `tool_result` → get final answer
5. Stream the final answer token-by-token to the console
6. Track and log token usage per turn

## Expected Output

- Console app demonstrating tool use: Claude calls a mock DB tool and uses the result
- Streamed final response with token count summary
