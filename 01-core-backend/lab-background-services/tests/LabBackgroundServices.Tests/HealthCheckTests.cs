using LabBackgroundServices.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Xunit;

namespace LabBackgroundServices.Tests;

public class HealthCheckTests
{
    [Fact]
    public async Task CheckHealthAsync_ReturnsUnhealthy_WhenNoRunHasSucceededYet()
    {
        var tracker = new LastRunTracker();
        var healthCheck = new PeriodicWorkerHealthCheck(tracker);

        var result = await healthCheck.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Unhealthy, result.Status);
    }

    [Fact]
    public async Task CheckHealthAsync_ReturnsHealthy_WhenLastRunIsWithinThreshold()
    {
        var tracker = new LastRunTracker();
        tracker.ReportSuccess();
        var healthCheck = new PeriodicWorkerHealthCheck(tracker, stalenessThreshold: TimeSpan.FromSeconds(15));

        var result = await healthCheck.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Healthy, result.Status);
        Assert.Contains("lastSuccessUtc", result.Data.Keys);
    }

    [Fact]
    public async Task CheckHealthAsync_ReturnsUnhealthy_WhenLastRunIsStale()
    {
        var tracker = new LastRunTracker();
        tracker.ReportSuccess();
        await Task.Delay(20);
        var healthCheck = new PeriodicWorkerHealthCheck(tracker, stalenessThreshold: TimeSpan.Zero);

        var result = await healthCheck.CheckHealthAsync(new HealthCheckContext());

        Assert.Equal(HealthStatus.Unhealthy, result.Status);
    }
}
