using System.Text;
using AutoMapper;
using AutoMapper.QueryableExtensions;
using LabAutoMapper.Data;
using LabAutoMapper.Domain;
using LabAutoMapper.Dtos;
using LabAutoMapper.Mapping;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace LabAutoMapper.Tests;

public class ProjectToSqlTests : IDisposable
{
    private readonly SqliteConnection _connection;
    private readonly AppDbContext _dbContext;
    private readonly StringBuilder _log = new();

    public ProjectToSqlTests()
    {
        _connection = new SqliteConnection("DataSource=:memory:");
        _connection.Open();

        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite(_connection)
            .LogTo(line => _log.AppendLine(line), LogLevel.Information)
            .Options;

        _dbContext = new AppDbContext(options);
        _dbContext.Database.EnsureCreated();

        var customer = new Customer { Name = "Acme Corp" };
        _dbContext.Orders.Add(new Order
        {
            Customer = customer,
            Subtotal = 100m,
            Status = OrderStatus.Paid,
            InternalNotes = "should never be selected by ProjectTo"
        });
        _dbContext.SaveChanges();
        _log.Clear();
    }

    public void Dispose()
    {
        _dbContext.Dispose();
        _connection.Dispose();
    }

    [Fact]
    public void ProjectTo_Generates_Sql_That_Excludes_Unmapped_Columns()
    {
        var configuration = new MapperConfiguration(cfg => cfg.AddProfile<OrderProfile>(), NullLoggerFactory.Instance);

        var results = _dbContext.Orders
            .ProjectTo<OrderDto>(configuration)
            .ToList();

        var sql = _log.ToString();

        Assert.Single(results);
        Assert.Contains("\"o\".\"Subtotal\"", sql);
        Assert.Contains("\"o\".\"Status\"", sql);
        Assert.Contains("\"c\".\"Name\"", sql);
        Assert.DoesNotContain("InternalNotes", sql);
    }
}
