# lab-semantic-kernel-rag

Semantic Kernel with memory and Azure AI Search as a vector store for Retrieval-Augmented Generation.

## Objectives

- Configure Azure AI Search as a vector store in Semantic Kernel
- Generate and store embeddings for a set of documents
- Perform semantic search with relevance scoring
- Ground LLM answers using retrieved context
- Compare results with and without RAG grounding

## Key Concepts

`IVectorStore`, `IVectorStoreRecordCollection`, `Azure.Search.Documents`, embedding model (`text-embedding-3-small`), vector index, cosine similarity, top-K retrieval, `TextMemoryPlugin`, `MemoryRecord`, prompt grounding, hallucination reduction

## Tasks

1. Set up Azure AI Search index with vector field (1536 dimensions)
2. Load 20 sample documents and generate embeddings via Azure OpenAI
3. Store documents + embeddings in the search index
4. Implement a `SearchPlugin` that retrieves top-3 relevant chunks
5. Build a Q&A prompt that injects retrieved chunks as context
6. Measure answer quality with vs without grounding

## Expected Output

- RAG-powered Q&A console app
- Side-by-side comparison showing grounded vs ungrounded answers
- Relevance scores logged per retrieved document
