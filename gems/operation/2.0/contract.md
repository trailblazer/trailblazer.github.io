---
layout: operation2
title: Operation Contract
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0", "1.1"]
---

A *contract* is an abstraction to handle validation of arbitrary data or object state. It is a fully self-contained object that is orchestrated by the operation.

The `Contract` module helps you defining contracts and assists with instantiating and validating data using those contracts at runtime.

## Overview: Reform

Most contracts are [Reform](/gems/reform) objects that you can define and validate in the operation. Reform is a fantastic tool for deserializing and validating deeply nested hashes, and then, when valid, writing those to the database using your persistence layer such as ActiveRecord.

{{  "contract_test.rb:overv-reform" | tsnippet }}

Using contracts consists of two steps.

* Defining the contract class(es) used in the operation.
* Plugging creation and validation into  the operation's pipetree.

## Contract Definition

Defining the contract can be done via the `contract` block as in the example above. This is called *inline contract* since it happens straight in the operation class.

An alternative approach is to reference an external Reform class from a separate file. This is called an *explicit contract*.

{{  "contract_test.rb:reform-inline" | tsnippet }}

This class can now be referenced in the operation.

{{  "contract_test.rb:reform-inline-op" | tsnippet }}


The explicit file/class convention is the preferred Trailblazer style as it keeps classes small and maximizes reusability. Please make sure you're following Trailblazer's naming convention to avoid friction. # TODO: link.

## Pipetree

After defining, you have to create and invoke the Reform object in your operation. The easiest way is to use `Contract`'s macros for that.

{{  "contract_test.rb:overv-reform" | tsnippet : "bla" }}

For a better understanding, here's the compiled pipetree.

{{  "contract_test.rb:overv-reform-pipe" | tsnippet }}

With a Reform contract the relevant steps are as follows.

1. Since every Reform object needs a model, use [the `Model` macro](model.html) to instantiate or find it.
2. Let the `Contract` macro instantiate the Reform object for you. The object will per default be pushed to `self["contract.default"]`.
3. Let `Contract::Validate` extract the correct hash from the params. If this fails because the params are not a hash or the specified key can't be found, it deviates to left track.
3. Instruct `Contract::Validate` to validate the params against this contract. When validation turns out to be successful, it will remain on the right track. Otherwise, when invalid, deviate to the left track.
4. Use the `Persist` macro to call `sync` or `save` on the contract in case of a successful validation.

## Default Contract

You don't have to assign a name for a contract when using only one per operation.

{{  "contract_test.rb:overv-reform" | tsnippet : "contractonly" }}

The name will be `default`. The contract class will be available via `self["contract.default.class"]`.

    Create["contract.default.class"] #=> Reform::Form subclass

After running the operation, the contract instance is available via `self["contract.default"]`.

    result = Create.(..)
    result["contract.default"] #=> <Reform::Form ...>

You can pass a name to `contract`.

{{  "contract_test.rb:contract-name" | tsnippet : "pipe" }}

## Multiple Contracts

Since `contract` can be called multiple times, this allows you to maintain as many contracts as you need per operation.

Naming also works when referencing constants.

{{  "contract_test.rb:contract-ref" | tsnippet }}

When using named contracts, you can still use the `Contract` macros, but now you need to say what contract you're referring to using the `name:` option.

{{  "contract_test.rb:contract-name" | tsnippet : "contract" }}


## Dry-Schema

It is possible to use a [Dry::Schema](dry-rb.org/gems/dry-validation/) directly as a contract. This is great for stateless, formal validations, e.g. to make sure the params have the right format.

{{  "contract_test.rb:dry-schema" | tsnippet : "form" }}

Schema validations don't need a model and hence you don't have to instantiate them.

### Dry: Guard Schema

Dry's schemas can even be executed **before** the operation gets instantiated, if you want that. This is called a *guard schema* and great for a quick formal check. If that fails, the operation won't be instantiated which will save time massively.

{{  "contract_test.rb:dry-schema-first" | tsnippet : "more" }}

Use schemas for formal, linear validations. Use Reform forms when there's a more complex deserialization with nesting and object state happening.

### Dry: Explicit Schema

As always, you can also use an *explicit* schema.

{{  "contract_test.rb:dry-schema-explsch" | tsnippet }}

Just reference the schema constant in the `contract` method.

{{  "contract_test.rb:dry-schema-expl" | tsnippet }}

## Extracting Params

Per default, `Contract::Validate` will use `self["params"]` as the data to be validated. Use the `key:` option if you want to validate a nested hash from the original params structure.

{{  "contract_test.rb:key" | tsnippet }}

Note that string vs. symbol do matter here since the operation will simply do a hash lookup using the key you provided.

### Manual Extraction

You can plug your own complex logic to extract params for validation into the pipe.

{{  "contract_test.rb:key-extr" | tsnippet }}

Note that you have to set the `self["params.validate"]` field in your own step, and - obviously - this has to happen before the actual validation.

Keep in mind that `&` will deviate to the left track if your `extract_params!` logic returns falsey.

## Naming Interface

You don't have to use the `contract` interface to register contract classes in your operation. Use the `constant:` option to point the `Contract` builder directly to a class.

{{  "contract_test.rb:constant" | tsnippet }}

No DSL is used here.

Instead, the `Contract` step will build the contract instance and register it under `self["contract.default"]`, which will then be used in the `Validate` step.

### Explicit Naming

Explicit naming for the contract is possible, too.

{{  "contract_test.rb:constant-name" | tsnippet }}

Here, you have to use the `name:` option to tell each step what dependency to use.

## Dependency Injection

In fact, the operation doesn't need any reference to a contract class at all.

{{  "contract_test.rb:di-constant" | tsnippet }}

The contract can be injected when calling the operation.

A prerequisite for that is that the contract class is defined.

{{  "contract_test.rb:di-constant-contract" | tsnippet }}

When calling, you now have to provide the default contract class as a dependency.

{{  "contract_test.rb:di-contract-call" | tsnippet }}

This will work with any name if you follow [the naming conventions](#explicit-naming).

## Cheatsheet

## Result

The operation will store the validation result for every contract in its own result object.

    result = Create.({ id: 1 })

    result["result.contract"].success? #=> true
    result["result.contract"].errors #=> {}

The path is `result.contract[.name]`, e.g. `result["result.contract.params"]`.


---- do it yourself
--- contract.default / result.
--- -procedural
