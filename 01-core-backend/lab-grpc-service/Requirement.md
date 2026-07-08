# Lab: gRPC Service

## Objectives

- Define a gRPC service with protobuf contracts
- Implement unary, server streaming, and client streaming calls
- Handle deadlines, cancellation, and error propagation
- Call the gRPC service from a .NET client and a REST facade

## Tasks

- [ ] Create .NET 9 gRPC project
- [ ] Define `.proto` file: unary + server streaming RPCs
- [ ] Implement server-side handlers
- [ ] Create a .NET gRPC client project
- [ ] Create a REST-to-gRPC facade (ASP.NET Core API that calls the gRPC service)
- [ ] Implement deadline and cancellation token propagation
- [ ] Handle gRPC status codes and map to HTTP equivalents

## Expected Output

Working gRPC server + client + REST facade. Demonstrate streaming with a sample "large dataset" query.

## Key Concepts Practiced

`gRPC` · `Protobuf` · `Streaming` · `Deadlines` · `Error handling`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
