using AutoMapper;
using LabAutoMapper.Domain;
using LabAutoMapper.Dtos;
using LabAutoMapper.Mapping;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace LabAutoMapper.Tests;

public class OrderProfileTests
{
    private static IMapper CreateMapper()
    {
        var configuration = new MapperConfiguration(cfg => cfg.AddProfile<OrderProfile>(), NullLoggerFactory.Instance);
        return configuration.CreateMapper();
    }

    [Fact]
    public void Configuration_Is_Valid()
    {
        var configuration = new MapperConfiguration(cfg => cfg.AddProfile<OrderProfile>(), NullLoggerFactory.Instance);

        configuration.AssertConfigurationIsValid();
    }

    [Fact]
    public void Order_To_OrderDto_Flattens_CustomerName()
    {
        var mapper = CreateMapper();
        var order = new Order
        {
            Id = 1,
            Customer = new Customer { Id = 1, Name = "Acme Corp" },
            Subtotal = 100m,
            Status = OrderStatus.Paid,
            InternalNotes = "internal"
        };

        var dto = mapper.Map<OrderDto>(order);

        Assert.Equal("Acme Corp", dto.CustomerName);
    }

    [Fact]
    public void Order_To_OrderDto_Computes_TotalWithTax()
    {
        var mapper = CreateMapper();
        var order = new Order { Customer = new Customer { Name = "Acme" }, Subtotal = 100m };

        var dto = mapper.Map<OrderDto>(order);

        Assert.Equal(100m * (1 + TaxRates.FlatRate), dto.TotalWithTax);
    }

    [Fact]
    public void Order_To_OrderDto_Converts_Status_To_String()
    {
        var mapper = CreateMapper();
        var order = new Order { Customer = new Customer { Name = "Acme" }, Status = OrderStatus.Shipped };

        var dto = mapper.Map<OrderDto>(order);

        Assert.Equal("Shipped", dto.Status);
    }

    [Fact]
    public void CreateOrderDto_To_Order_Maps_Writable_Fields_Only()
    {
        var mapper = CreateMapper();
        var createDto = new CreateOrderDto { CustomerId = 5, Subtotal = 42m, Status = OrderStatus.Pending };

        var order = mapper.Map<Order>(createDto);

        Assert.Equal(5, order.CustomerId);
        Assert.Equal(42m, order.Subtotal);
        Assert.Equal(OrderStatus.Pending, order.Status);
        Assert.Equal(0, order.Id);
        Assert.Null(order.Customer);
    }

    [Fact]
    public void OrderStatusToStringConverter_Converts_Each_Status()
    {
        var mapper = CreateMapper();

        Assert.Equal("PAID", mapper.Map<string>(OrderStatus.Paid));
        Assert.Equal("PENDING", mapper.Map<string>(OrderStatus.Pending));
        Assert.Equal("SHIPPED", mapper.Map<string>(OrderStatus.Shipped));
        Assert.Equal("CANCELLED", mapper.Map<string>(OrderStatus.Cancelled));
    }

    [Fact]
    public void TotalWithTaxResolver_Computes_Total_In_Isolation()
    {
        var resolver = new TotalWithTaxResolver(new FlatTaxRateProvider());
        var order = new Order { Subtotal = 200m };

        var result = resolver.Resolve(order, new OrderDto(), 0m, null!);

        Assert.Equal(200m * (1 + TaxRates.FlatRate), result);
    }

    [Fact]
    public void TotalWithTaxResolver_Works_Through_AutoMapper_MapFrom()
    {
        // Demonstrates the resolver working end-to-end through AutoMapper's regular
        // object-to-object Map() - this mapping is NOT used for ProjectTo (see README
        // Common Pitfalls: custom resolvers can't be translated into SQL projections).
        var services = new ServiceCollection();
        services.AddSingleton<ITaxRateProvider, FlatTaxRateProvider>();
        services.AddTransient<TotalWithTaxResolver>();
        var provider = services.BuildServiceProvider();

        var configuration = new MapperConfiguration(cfg =>
        {
            cfg.ConstructServicesUsing(provider.GetService!);
            cfg.CreateMap<Order, OrderDto>()
                .ForMember(d => d.CustomerName, o => o.MapFrom(s => s.Customer.Name))
                .ForMember(d => d.TotalWithTax, o => o.MapFrom<TotalWithTaxResolver>())
                .ForMember(d => d.Status, o => o.MapFrom(s => s.Status.ToString()));
        }, NullLoggerFactory.Instance);

        var mapperWithDi = configuration.CreateMapper();
        var order = new Order { Customer = new Customer { Name = "Acme" }, Subtotal = 100m };

        var dto = mapperWithDi.Map<OrderDto>(order);

        Assert.Equal(100m * (1 + TaxRates.FlatRate), dto.TotalWithTax);
    }
}
