using LabBackgroundServices.Reliability;
using Xunit;

namespace LabBackgroundServices.Tests;

public class BackoffPolicyTests
{
    [Theory]
    [InlineData(1, 1)]
    [InlineData(2, 2)]
    [InlineData(3, 4)]
    [InlineData(4, 8)]
    [InlineData(5, 16)]
    [InlineData(6, 30)] // capped: 2^5 = 32s would exceed the 30s max delay
    [InlineData(10, 30)]
    public void NextDelay_GrowsExponentiallyThenCaps(int attempt, double expectedSeconds)
    {
        var delay = BackoffPolicy.NextDelay(attempt);

        Assert.Equal(expectedSeconds, delay.TotalSeconds);
    }

    [Fact]
    public void NextDelay_ThrowsForNonPositiveAttempt()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => BackoffPolicy.NextDelay(0));
    }
}
