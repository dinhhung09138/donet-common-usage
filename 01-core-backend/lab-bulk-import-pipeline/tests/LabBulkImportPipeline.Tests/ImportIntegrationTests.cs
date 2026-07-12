using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using LabBulkImportPipeline.Import;
using Microsoft.AspNetCore.Http.Connections;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.SignalR.Client;
using Xunit;

namespace LabBulkImportPipeline.Tests;

public class ImportIntegrationTests(WebApplicationFactory<Program> factory) : IClassFixture<WebApplicationFactory<Program>>
{
    private const int RowCount = 10_000;
    private const int InvalidEvery = 50;

    [Fact]
    public async Task PostImport_LargeCsv_CompletesWithExpectedCountsAndIsIdempotentOnReupload()
    {
        var client = factory.CreateClient();
        var csvBytes = BuildCsv(RowCount, InvalidEvery);
        var expectedInvalidRows = RowCount / InvalidEvery;
        var expectedValidRows = RowCount - expectedInvalidRows;

        var jobId = await SubmitImportAsync(client, csvBytes);

        var result = await PollUntilCompleteAsync(client, jobId);

        Assert.Equal("Completed", result!.Status);
        Assert.Equal(RowCount, result.Total);
        Assert.Equal(expectedValidRows, result.Imported);
        Assert.Equal(expectedInvalidRows, result.Skipped);
        Assert.Equal(expectedInvalidRows, result.Errors.Count);
        Assert.False(result.FromCache);

        var reuploadResponse = await client.PostAsync("/imports?strategy=PartialCommit", BuildMultipartContent(csvBytes));
        reuploadResponse.EnsureSuccessStatusCode();
        var cachedResult = await reuploadResponse.Content.ReadFromJsonAsync<ImportResultDto>();

        Assert.NotNull(cachedResult);
        Assert.True(cachedResult!.FromCache);
        Assert.Equal(result.Imported, cachedResult.Imported);
        Assert.Equal(result.Skipped, cachedResult.Skipped);
    }

    [Fact]
    public async Task PostImport_AllOrNothingWithInvalidRows_ImportsNothing()
    {
        var client = factory.CreateClient();
        var csvBytes = BuildCsv(200, InvalidEvery: 10);

        var jobId = await SubmitImportAsync(client, csvBytes, strategy: "AllOrNothing");
        var result = await PollUntilCompleteAsync(client, jobId);

        Assert.Equal("Completed", result!.Status);
        Assert.Equal(0, result.Imported);
        Assert.True(result.Skipped > 0);
    }

    [Fact]
    public async Task PostImport_ClientSubscribedToHub_ReceivesProgressEvents()
    {
        var client = factory.CreateClient();
        var csvBytes = BuildCsv(20_000, InvalidEvery: 25);

        await using var connection = new HubConnectionBuilder()
            .WithUrl("http://localhost/hubs/import-progress", options =>
            {
                options.HttpMessageHandlerFactory = _ => factory.Server.CreateHandler();
                options.Transports = HttpTransportType.LongPolling;
            })
            .Build();

        var progressEvents = new List<JsonElement>();
        connection.On<JsonElement>("progress", payload => progressEvents.Add(payload));
        await connection.StartAsync();

        var jobId = await SubmitImportAsync(client, csvBytes);
        await connection.InvokeAsync("JoinJob", jobId);

        await PollUntilCompleteAsync(client, jobId);
        await Task.Delay(500);

        Assert.NotEmpty(progressEvents);
        Assert.All(progressEvents, e => Assert.Equal(jobId, e.GetProperty("jobId").GetString()));
    }

    private static async Task<string> SubmitImportAsync(HttpClient client, byte[] csvBytes, string strategy = "PartialCommit")
    {
        var response = await client.PostAsync($"/imports?strategy={strategy}", BuildMultipartContent(csvBytes));
        response.EnsureSuccessStatusCode();
        var payload = await response.Content.ReadFromJsonAsync<JsonElement>();
        return payload.GetProperty("jobId").GetString()!;
    }

    private static async Task<ImportResultDto?> PollUntilCompleteAsync(HttpClient client, string jobId)
    {
        for (var attempt = 0; attempt < 100; attempt++)
        {
            var response = await client.GetAsync($"/imports/{jobId}");
            if (response.StatusCode == System.Net.HttpStatusCode.OK)
            {
                return await response.Content.ReadFromJsonAsync<ImportResultDto>();
            }

            await Task.Delay(200);
        }

        throw new TimeoutException($"Import job {jobId} did not complete in time.");
    }

    private static MultipartFormDataContent BuildMultipartContent(byte[] csvBytes)
    {
        var content = new MultipartFormDataContent();
        var fileContent = new ByteArrayContent(csvBytes);
        fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue("text/csv");
        content.Add(fileContent, "file", "import.csv");
        return content;
    }

    private static byte[] BuildCsv(int rowCount, int InvalidEvery)
    {
        var sb = new StringBuilder();
        sb.Append("Name,Email,Amount\n");
        for (var i = 1; i <= rowCount; i++)
        {
            var isInvalid = i % InvalidEvery == 0;
            var email = isInvalid ? "not-an-email" : $"user{i}@example.com";
            sb.Append($"User{i},{email},{i}.00\n");
        }

        return Encoding.UTF8.GetBytes(sb.ToString());
    }
}
