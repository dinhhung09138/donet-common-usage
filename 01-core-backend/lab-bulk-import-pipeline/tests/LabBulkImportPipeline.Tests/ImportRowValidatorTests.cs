using LabBulkImportPipeline.Import;
using LabBulkImportPipeline.Validation;
using Xunit;

namespace LabBulkImportPipeline.Tests;

public class ImportRowValidatorTests
{
    private readonly ImportRowValidator _validator = new();

    [Fact]
    public void Validate_ValidRow_ReturnsNoErrors()
    {
        var row = new ImportRowDto { RowNumber = 1, Name = "Ada Lovelace", Email = "ada@example.com", Amount = "100.50" };

        var result = _validator.Validate(row);

        Assert.True(result.IsValid);
    }

    [Theory]
    [InlineData("", "ada@example.com", "100")]
    [InlineData("Ada", "not-an-email", "100")]
    [InlineData("Ada", "ada@example.com", "not-a-number")]
    [InlineData("Ada", "ada@example.com", "-5")]
    [InlineData("Ada", "ada@example.com", "")]
    public void Validate_InvalidRow_ReturnsErrors(string name, string email, string amount)
    {
        var row = new ImportRowDto { RowNumber = 1, Name = name, Email = email, Amount = amount };

        var result = _validator.Validate(row);

        Assert.False(result.IsValid);
        Assert.NotEmpty(result.Errors);
    }
}
