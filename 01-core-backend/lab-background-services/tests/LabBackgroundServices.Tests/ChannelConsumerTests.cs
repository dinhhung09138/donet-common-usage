using System.Threading.Channels;
using LabBackgroundServices.Data;
using Xunit;

namespace LabBackgroundServices.Tests;

/// <summary>
/// Exercises the exact Channel&lt;T&gt; producer/consumer mechanics <see cref="LabBackgroundServices.Workers.ChannelConsumerService"/>
/// relies on: unbounded writer, ReadAllAsync draining, and cancellation propagation.
/// </summary>
public class ChannelConsumerTests
{
    [Fact]
    public async Task ReadAllAsync_DrainsAllProducedItemsInOrder()
    {
        var channel = Channel.CreateUnbounded<WorkItem>();
        var produced = Enumerable.Range(1, 5)
            .Select(i => new WorkItem { Id = i, Payload = $"item-{i}" })
            .ToList();

        foreach (var item in produced)
        {
            await channel.Writer.WriteAsync(item);
        }
        channel.Writer.Complete();

        var consumed = new List<WorkItem>();
        await foreach (var item in channel.Reader.ReadAllAsync())
        {
            consumed.Add(item);
        }

        Assert.Equal(produced.Select(i => i.Id), consumed.Select(i => i.Id));
    }

    [Fact]
    public async Task ReadAllAsync_StopsWhenCancellationTokenIsTriggered()
    {
        var channel = Channel.CreateUnbounded<WorkItem>();
        await channel.Writer.WriteAsync(new WorkItem { Id = 1, Payload = "first" });

        using var cts = new CancellationTokenSource();
        var consumed = new List<WorkItem>();

        var consumeTask = Task.Run(async () =>
        {
            await foreach (var item in channel.Reader.ReadAllAsync(cts.Token))
            {
                consumed.Add(item);
                cts.Cancel(); // simulate shutdown being requested mid-processing
            }
        });

        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => consumeTask);
        Assert.Single(consumed);
    }
}
