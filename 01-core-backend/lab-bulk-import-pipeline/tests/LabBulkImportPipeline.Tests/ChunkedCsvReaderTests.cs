using System.Threading.Channels;
using LabBulkImportPipeline.Import;
using Xunit;

namespace LabBulkImportPipeline.Tests;

public class ChunkedCsvReaderTests
{
    [Fact]
    public async Task ReadIntoChannelAsync_ValidCsv_ProducesOneRowPerDataLine()
    {
        var filePath = Path.GetTempFileName();
        await File.WriteAllTextAsync(filePath, "Name,Email,Amount\nAda,ada@example.com,100\nAlan,alan@example.com,200\n");

        try
        {
            var channel = Channel.CreateUnbounded<ImportRowDto>();
            await new ChunkedCsvReader().ReadIntoChannelAsync(filePath, channel.Writer, CancellationToken.None);

            var rows = new List<ImportRowDto>();
            await foreach (var row in channel.Reader.ReadAllAsync())
            {
                rows.Add(row);
            }

            Assert.Equal(2, rows.Count);
            Assert.Equal("Ada", rows[0].Name);
            Assert.Equal(1, rows[0].RowNumber);
            Assert.Equal("Alan", rows[1].Name);
            Assert.Equal(2, rows[1].RowNumber);
        }
        finally
        {
            File.Delete(filePath);
        }
    }

    [Fact]
    public async Task ReadIntoChannelAsync_RowWithMissingField_DoesNotThrowAndYieldsEmptyValue()
    {
        var filePath = Path.GetTempFileName();
        await File.WriteAllTextAsync(filePath, "Name,Email,Amount\nAda,ada@example.com\n");

        try
        {
            var channel = Channel.CreateUnbounded<ImportRowDto>();
            await new ChunkedCsvReader().ReadIntoChannelAsync(filePath, channel.Writer, CancellationToken.None);

            var rows = new List<ImportRowDto>();
            await foreach (var row in channel.Reader.ReadAllAsync())
            {
                rows.Add(row);
            }

            Assert.Single(rows);
            Assert.Equal(string.Empty, rows[0].Amount);
        }
        finally
        {
            File.Delete(filePath);
        }
    }
}
