# Apex DML Mocking

Welcome to the SFDX project home for blazing fast Apex unit tests! For your consideration, this is an _example_ of how to implement the full CRUD (Create Read Update Delete) mocking implementation within your own Salesforce orgs. You can find out more information by perusing:

- [force-app](/force-app) for implementation details
- [example-app](/example-app) for an example Account Handler with mocking set up

Writing tests that scale as the size of your organization grows is an increasingly challenging problem in the Salesforce world. It's not uncommon in large companies for deploys to last several hours; the vast majority of that time is spent running tests to verify that your code coverage is good enough for the deploy to succeed. Tests don't _need_ to take that long.

This repo shows you how you can mock your SOQL queries and DML statements in Apex by using lightweight wrappers that are dependency injected into your business logic objects. This allows you to replace expensive test setup and test teardown with a fake database. I've used this method to cut testing time down by 90%+ -- in a small org, with only a few hundred tests, running tests and deploying can be done in under five minutes (easily). In large orgs, with many hundreds or thousands of tests, overall testing time tends to scale more linearly with organizational complexity; there are additional optimizations that can be done in these orgs to keep deploys in the 10 minute(s) range.

## Access Level & DML Option Setting

Both `IDML` and `IRepository` instances returned by the framework support the method `IDML setOptions(Database.DMLOptions options, System.AccessLevel accessLevel);`. Note that if DML options are not set by default, this framework uses true for the `allOrNone` value when performing DML, as that is consistent with the standard for calling DML operations without specifying that property. Please also note that DML options are not "expired" after having been set -- if you are using an instance of `IRepository` or `IDML` and are performing multiple DML operations using that same instance, the DML options that have been set will continue to apply to subsequent operations until `setOptions` is re-called, or a new instance is initialized. DML options are _not_ shared between instances; they are not statically set. Passing `null` for the DML options value will only update the access level.

By default, all operations are run using `System.AccessMode.SYSTEM_MODE`. You can either override this (for `IDML` and `IRepository` instances) by calling `setOptions`, as shown above, or by calling `IRepository setAccessLevel(System.AccessLevel accessLevel);` on `IRepository` instances. Like DML options, the access level that is set for an instance is then the one used for subsequent operations involving that repository instance.

## DML Mocking Basics

Try checking out the source code for the DML wrapping classes:

- [DML](force-app/dml/DML.cls)
- [DMLMock](force-app/dml/DMLMock.cls)

## SOQL Mocking Basics

Take a look at the following classes to understand how you can replace raw SOQL in your code with testable (and extendable) strongly typed queries:

- [Repository](force-app/repository/Repository.cls)
- [Query](force-app/repository/Query.cls)

Then, move on to the more complicated examples:

- [AggregateRepository](force-app/repository/AggregateRepository.cls)
- [Aggregation](force-app/repository/Aggregation.cls)
- [AggregateRepositoryTests](force-app/repository/AggregateRepositoryTests.cls) - a good example of how to use the above two classes
- [FieldLevelHistoryRepo](force-app/repository/FieldLevelHistoryRepo.cls)
- [FieldLevelHistory](force-app/repository/FieldLevelHistory.cls)

While opinionated in implementation, these classes are also just scratching the surface of what's possible when taking advantage of the Factory pattern in combination with the Repository pattern, including full support for:

- strongly typed subqueries (queries returning children records)
- strongly typed parent-level fields
- the ability to easily extend classes like `Repository` to include things like limits, order bys, etc ...

## Dependency Injection Basics

The "Factory" pattern is of particular importance for DML mocking, because it allows you to have only _one_ stub in your code for deciding whether or not to use mocks when running tests; crucially, the stub is only available when tests are being run: you cannot mock things in production-grade code.

You can have as many Factories as you'd like. I like to break my Factories out by responsibility:

- A factory for Trigger handlers
- A [factory](force-app/factory/Factory.cls) for basic classes
- The [RepoFactory](force-app/factory/RepoFactory.cls) for CRUD related objects

It's a pretty standard approach. You might choose to break things down by (business) domain. There's no right way.

## Package-Based Development

These repository (as of 18 May 2023) has been slightly reworked to provide better support for package-based development. The updates are primarily to show how the `example-app` folder can be in a completely separate package while still allowing for strongly-typed references (and package-specific factories and repo factories) to be referenced properly. For a concrete example, check out:

- [The unit tests in HistoryRepoTests](example-app/history/HistoryRepoTests.cls)
- [The extended factory](example-app/ExampleFactory.cls)
- [The extended repo factory](example-app/ExampleRepoFactory.cls)

---

## More Information

For more information on these patterns and how to use them, consider the free resources I've published under [The Joys Of Apex](https://www.jamessimone.net/blog/joys-of-apex/). Thanks for your time!
