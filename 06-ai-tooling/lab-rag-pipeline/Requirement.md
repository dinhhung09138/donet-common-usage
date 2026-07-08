# lab-rag-pipeline

End-to-end RAG pipeline: document chunking, embedding generation, vector storage, retrieval, and grounded LLM answer.

## Objectives

- Implement fixed-size and recursive chunking strategies
- Generate embeddings using Azure OpenAI `text-embedding-3-small`
- Store and query vectors in Qdrant (local Docker) or Azure AI Search
- Retrieve top-K chunks with cosine similarity scoring
- Construct grounded prompts and measure hallucination reduction
- Add re-ranking step to improve retrieval precision

## Key Concepts

Chunking (fixed-size, recursive, semantic boundary), overlap window, `text-embedding-3-small`, 1536-dimension vectors, Qdrant `QdrantClient`, `Azure.Search.Documents`, cosine similarity, top-K retrieval, prompt grounding, `[CONTEXT]` injection pattern, re-ranking (cross-encoder), precision@K metric

## Tasks

1. Run Qdrant locally via Docker (`qdrant/qdrant`)
2. Load a 50-page PDF and split into chunks (size=500, overlap=50 tokens)
3. Generate embeddings for all chunks and upsert to Qdrant collection
4. Implement `RetrieveAsync(query, topK)` that returns ranked chunks
5. Build a grounded prompt template and call GPT-4o-mini for the final answer
6. Add a cross-encoder re-ranking step using a Hugging Face model via HTTP

## Expected Output

- CLI tool: `dotnet run -- "What is the refund policy?"` returns a grounded answer
- Retrieval log showing chunk scores before and after re-ranking
