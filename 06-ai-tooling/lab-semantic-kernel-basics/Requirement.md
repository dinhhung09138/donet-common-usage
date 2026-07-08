# lab-semantic-kernel-basics

Microsoft Semantic Kernel for .NET — kernel setup, native plugins, prompt functions, and chat history management.

## Objectives

- Configure `Kernel` with Azure OpenAI chat completion service
- Create native plugins using `[KernelFunction]` and `[Description]` attributes
- Build prompt functions from inline templates and YAML prompt files
- Manage `ChatHistory` for multi-turn conversations
- Enable automatic function invocation (`FunctionChoiceBehavior.Auto`)
- Chain multiple plugins in a single kernel invocation

## Key Concepts

`Kernel`, `KernelBuilder`, `KernelPlugin`, `[KernelFunction]`, `[Description]`, `IChatCompletionService`, `ChatHistory`, `KernelArguments`, prompt function, `PromptTemplateConfig`, auto-invoke, `FunctionChoiceBehavior`

## Tasks

1. Install `Microsoft.SemanticKernel` and configure kernel with Azure OpenAI
2. Create a `TimePlugin` native function that returns current UTC time
3. Create a prompt function that summarizes text using a Handlebars template
4. Build a chat loop using `ChatHistory` that maintains conversation context
5. Register both plugins and observe auto-invocation when the model decides to call them
6. Add a second plugin (`WeatherPlugin`) and show multi-plugin routing

## Expected Output

- Interactive console chat app with auto function calling
- Kernel log showing which plugins were invoked and with what arguments
