# lab-docker-dotnet-sdk

## Objectives

- Manage Docker containers and images programmatically from C# using the Docker.DotNet SDK
- Build images from a Dockerfile in code (without shelling out to the CLI)
- Pass environment variables, port bindings, and volume mounts to containers
- Stream container logs in real time from a running container
- Understand the architecture behind GUI systems that let users create images and trigger container runs

## Key Concepts

`Docker.DotNet` · `IDockerClient` · `DockerClientConfiguration` · `CreateContainerAsync` · `StartContainerAsync` · `StopContainerAsync` · `RemoveContainerAsync` · `CreateImageAsync` · `BuildImageFromDockerfileAsync` · `ExecCreateContainerAsync` · `GetContainerLogsAsync` · `ContainerCreateParameters` · `HostConfig` · `PortBindings` · `Environment variables` · `Streaming logs`

## Tasks

- [ ] Install `Docker.DotNet` NuGet package; connect to the local Docker daemon via `DockerClientConfiguration(new Uri("npipe://./pipe/docker_engine"))`
- [ ] List all running containers and print their IDs, names, and status
- [ ] Pull the `mcr.microsoft.com/dotnet/aspnet:8.0` image using `CreateImageAsync` with a progress stream
- [ ] Create a container from the pulled image, passing environment variables (`APP_ENV=development`) and a port binding (`8080:8080`)
- [ ] Start the container; poll until it is in `running` state; stream its logs to the console in real time using `GetContainerLogsAsync`
- [ ] Exec a command inside the running container (`dotnet --version`) using `ExecCreateContainerAsync` + `StartContainerExecAsync`
- [ ] Stop and remove the container; verify it no longer appears in the list
- [ ] Build an image from a local Dockerfile using `BuildImageFromDockerfileAsync` (pass the build context as a TAR archive); tag it
- [ ] Implement a `ContainerOrchestrator` service class with methods: `BuildImageAsync(dockerfilePath, tag)`, `RunContainerAsync(image, envVars, ports)`, `StopContainerAsync(id)`, `GetLogsAsync(id)`
- [ ] Write an ADR: why programmatic Docker management (Docker.DotNet) vs Docker CLI subprocess vs Kubernetes Job for on-demand container workloads

## Expected Output

A C# console application and a `ContainerOrchestrator` service that can build, run, log, and remove containers — the foundation for a user-facing container management GUI.
