# lab-mongodb-basics

## Objectives

- Connect an ASP.NET Core API to MongoDB using the official C# driver
- Perform CRUD operations and understand BSON mapping
- Build aggregation pipelines and apply index strategies

## Key Concepts

`MongoDB.Driver` · `BsonDocument` · `IMongoCollection<T>` · `IMongoDatabase` · `Aggregation pipeline` · `$match` · `$group` · `$lookup` · `$unwind` · `Index strategies` · `LINQ provider`

## Tasks

- [ ] Configure `MongoClient` and register `IMongoDatabase` in DI
- [ ] Map a C# class to a MongoDB document using `[BsonId]`, `[BsonElement]`, `ObjectId`
- [ ] Implement Insert, FindById, UpdateOne (atomic field update with `$set`), DeleteOne
- [ ] Use `FindAsync` with a filter builder and projection
- [ ] Build an aggregation pipeline: group orders by customer and sum totals (`$match` → `$group`)
- [ ] Use `$lookup` to join two collections in a single pipeline stage
- [ ] Create a compound index and a TTL index; verify with `listIndexes`
- [ ] Run the same query via the LINQ provider and compare generated pipeline

## Expected Output

A minimal ASP.NET Core API backed by MongoDB with CRUD endpoints, an aggregation report endpoint, and documented index decisions.
