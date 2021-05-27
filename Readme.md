# Apex DML Mocking

Welcome to the SFDX project home for blazing fast Apex unit tests! For your consideration, this is an _example_ of how to implement the full CRUD (Create Read Update Delete) mocking implementation within your own Salesforce orgs. You can find out more information by perusing:

- [force-app](/force-app) for implementation details
- [example-app](/example-app) for an example Account Handler with mocking set up

Writing tests that scale as the size of your organization grows is an increasingly challenging problem in the Salesforce world. It's not uncommon in large companies for deploys to last several hours; the vast majority of that time is spent running tests to verify that your code coverage is good enough for the deploy to succeed. Tests don't _need_ to take that long.

This repo shows you how you can mock your SOQL queries and DML statements in Apex by using lightweight wrappers that are dependency injected into your business logic objects. This allows you to replace expensive test setup and test teardown with a fake database. I've used this method to cut testing time down by 90%+ -- in a small org, with only a few hundred tests, running tests and deploying can be done in under five minutes (easily). In large orgs, with many hundreds or thousands of tests, overall testing time tends to scale more linearly with organizational complexity; there are additional optimizations that can be done in these orgs to keep deploys in the 10-15 minutes range.

## DML Mocking Basics

Try checking out the source code for the DML wrapping classes:

- [DML](/force-app/dml/DML.cls)
- [DMLMock](/force-app/dml/DMLMock.cls)

## SOQL Mocking Basics

Take a look at the following classes to understand how you can replace raw SOQL in your code with testable (and extendable) strongly typed queries:

- [Repository](/force-app/repository/Repository.cls)
- [Query](/force-app/repository/Query.cls)

I use many different iterations of these two classes when working with customers. These are simple implementations meant to show you what's possible; at different times, I have implemented parent/child queries, using FieldSets to populate fields for queries, etc ... these classes are not meant to be inclusive of everything that is possible in dynamic SOQL!

## Dependency Injection Basics

The "Factory" pattern is of particular importance for DML-mocking, because it allows you to have only _one_ stub in your code for deciding whether or not to use mocks when running tests; crucially, the stub is only available when tests are being run: you cannot mock things in production-grade code.

You can have as many Factories as you'd like. I like to break my Factories out by responsibility:

- A factory for TriggerHandlers
- A [factory](/force-app/factory/Factory.cls) for basic classes
- The [RepoFactory](/force-app/factory/RepoFactory.cls) for CRUD related objects

It's a pretty standard approach. You might choose to break things down by (business) domain. There's no right way.

---

## More Information

For more information on these patterns and how to use them, consider the free resources I've published under [The Joys Of Apex](https://www.jamessimone.net/blog/joys-of-apex/). Thanks for your time!
