# lab-azure-openai-dotnet

Azure OpenAI Service integration in .NET — chat completions, streaming, function calling, and embeddings.

## Objectives

- Call Azure OpenAI chat completions endpoint using `Azure.AI.OpenAI` SDK
- Stream responses using `IAsyncEnumerable<StreamingChatCompletionsUpdate>`
- Define and invoke functions (tool use) from LLM responses
- Generate text embeddings for semantic similarity use cases
- Handle rate limits with Polly retry strategy
- Compare GPT-4o vs GPT-4o-mini for cost vs quality tradeoffs

## Key Concepts

`Azure.AI.OpenAI`, `OpenAIClient`, `ChatCompletionsOptions`, `ChatRequestMessage`, streaming `IAsyncEnumerable`, function / tool definition, `ChatCompletionsFunctionToolDefinition`, embeddings API, `EmbeddingsOptions`, token counting, `DefaultAzureCredential`

## Tasks

1. Set up Azure OpenAI resource and deploy a GPT-4o-mini model
2. Build a simple chat completion request and display the response
3. Implement streaming so tokens appear progressively
4. Define a `get_current_weather` tool and let the model call it
5. Generate embeddings for a list of strings and compute cosine similarity
6. Add Polly retry for 429 rate limit responses

## Expected Output

- Console app that streams a multi-turn conversation
- Function calling demo that resolves a mock tool call
- Embedding similarity score between two input sentences
