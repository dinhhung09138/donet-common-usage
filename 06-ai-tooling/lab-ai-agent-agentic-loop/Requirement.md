# lab-ai-agent-agentic-loop

Build an agentic loop with multi-step tool calling, state management, and stopping conditions.

## Objectives

- Implement the observe → plan → act → reflect agentic loop pattern
- Register a tool registry and dispatch tool calls from LLM responses
- Enforce a maximum step limit to prevent infinite loops
- Maintain agent state across steps (scratchpad, memory)
- Use Semantic Kernel's auto-invocation as a higher-level alternative
- Handle agent errors: tool exceptions, LLM refusal, max steps exceeded

## Key Concepts

Agentic loop, tool registry (`Dictionary<string, Func<JsonNode, Task<string>>>`), step counter, scratchpad pattern, `StopReason` (max steps, final answer, error), Semantic Kernel `FunctionChoiceBehavior.Auto`, `KernelFunction` exception handling, agent state machine, `[DONE]` sentinel detection

## Tasks

1. Define 3 tools: `search_web(query)`, `read_file(path)`, `write_summary(text)`
2. Implement the agentic loop: call LLM → parse tool calls → execute → feed results back
3. Add a `maxSteps = 10` guard and surface a graceful error when exceeded
4. Log each step (step number, tool called, result preview)
5. Implement the same loop using Semantic Kernel auto-invocation for comparison
6. Add a reflection step: after final answer, ask LLM to score its own reasoning quality

## Expected Output

- Console agent that researches a topic using chained tool calls
- Step-by-step log showing the full reasoning trace
- Graceful timeout message when max steps is hit
