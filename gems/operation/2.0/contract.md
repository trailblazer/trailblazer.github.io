---
layout: operation2
title: Operation Contract
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0", "1.1"]
---

A *contract* is an abstraction to handle validation of arbitrary data or object state. It is a fully self-contained object that is orchestrated by the operation.

The actual validation can be implemented using Reform with `ActiveModel::Validation` or dry-validation, or a [`Dry::Schema` directly](#dry-schema) without Reform.

The `Contract` macros helps you defining contracts and assists with instantiating and validating data with those contracts at runtime.

## Overview: Reform

Most contracts are [Reform](/gems/reform) objects that you can define and validate in the operation. Reform is a fantastic tool for deserializing and validating deeply nested hashes, and then, when valid, writing those to the database using your persistence layer such as ActiveRecord.

{{  "contract_test.rb:constant-contract" | tsnippet }}

The contract then gets hooked into the operation.

{{  "contract_test.rb:constant" | tsnippet }}

As you can see, using contracts consists of five steps.

1. Define the contract class (or multiple of them) for the operation.
2. Plug the contract creation into the operation's pipe using `Contract::Build`.
3. Run the contract's validation for the params using `Contract::Validate`.
4. If successful, write the sane data to the model(s). This will usually happen in the `Contract::Persist` macro.
5. After the operation has been run, [interpret the result](#result-object). For instance, a controller calling an operation will render a erroring form for invalid input.

{% callout %}
You don't have to use any of the TRB macros to deal with contracts, and do everything yourself. They are an abstraction that will save code and bugs, and introduce strong conventions. However, feel free to use your own code.
{% endcallout %}

Here's what the result would look like after running the `Create` operation with invalid data.

{{  "contract_test.rb:constant-result" | tsnippet }}

## Definition

Trailblazer offers a few different ways to define contract classes and use them in an operation.

### Definition: Explicit

The preferred way of defining contracts is to use a separate file and class, such as the example below.

{{  "contract_test.rb:constant-contract" | tsnippet }}

This is called *explicit contract*.

The contract file could be located just anywhere, but it's clever to follow the Trailblazer conventions.

Using the contract happens via `Contract::Build`, and the `:constant` option.

{{  "contract_test.rb:constant" | tsnippet }}

Since both operations and contracts grow during development, the completely encapsulated approach of the explicit contract is what we recommend.

### Definition: Inline

Contracts can also be defined in the operation itself.

{{  "contract_test.rb:overv-reform" | tsnippet }}

Defining the contract happens via the `contract` block. This is called an *inline contract*. Note that you need to extend the class with the `Contract::DSL` module. You don't have to specify anything in the `Build` macro.

While this is nice for a quick example, this usually ends up quite convoluted and we advise you to use the [explicit style](#definition-explicit).

## Build

The `Contract::Build` macro helps you to instantiate the contract.
It is both helpful for a complete workflow, or to create the contract, only, without validating it, e.g. when presenting the form.
{{  "contract_test.rb:constant-new" | tsnippet }}

This macro will grab the model from `options["model"]` and pass it into the contract's constructor. The contract is then saved in `options["contract.default"]`.

{{  "contract_test.rb:constant-new-result" | tsnippet }}

The `Build` macro accepts [the `:name` option](#name) to change the name from `default`.

## Validate

The `Contract::Validate` macro is responsible for validating the incoming params against its contract. That means you have to use `Contract::Build` beforehand, or create the contract yourself. The macro will then grab the params and throw then into the contract's `validate` (or `call`) method.

{{  "contract_test.rb:validate-only" | tsnippet }}

Depending on the outcome of the validation, it either stays on the right track, or deviates to left, skipping the remaining steps.

{{  "contract_test.rb:validate-only-result-false" | tsnippet }}

Note that `Validate` really only validates the contract, nothing is written to the model, yet. You need to push data to the model manually, e.g. [with `Contract::Persist`](#persist).

{{  "contract_test.rb:validate-only-result" | tsnippet }}

`Validate` will use `options["params"]` as the input. You can change the nesting with [the `:key` option](#key).

{% callout %}
Internally, this macro will simply call `Form#validate` on the Reform object.

Note that Reform comes with sophisticated deserialization semantics for nested forms, it might be worth reading [a bit about Reform](/gems/reform) to fully understand what you can do in the `Validate` step.
{% endcallout %}

## Key

Per default, `Contract::Validate` will use `options["params"]` as the data to be validated. Use the `key:` option if you want to validate a nested hash from the original params structure.

{{  "contract_test.rb:key" | tsnippet }}

This automatically extracts the nested `"song"` hash.

{{  "contract_test.rb:key-res" | tsnippet }}

If that key isn't present in the params hash, the operation fails before the actual validation.

{{  "contract_test.rb:key-res-false" | tsnippet }}

Note that string vs. symbol do matter here since the operation will simply do a hash lookup using the key you provided.

## Persist

To push validated data from the contract to the model(s), use `Persist`. Like `Validate`, this requires a contract to be set up beforehand.

{{  "contract_test.rb:constant" | tsnippet }}

After the step, the contract's attribute values are written to the model, and the contract will call `save` on the model.

{{  "contract_test.rb:constant-result-true" | tsnippet }}

You can also configure the `Persist` step to call `sync` instead of Reform's `save`.

    step Persist( method: :sync )

This will only write the contract's data to the model without calling `save` on it.

## Name

Explicit naming for the contract is possible, too.

{{  "contract_test.rb:constant-name" | tsnippet }}

You have to use the `name:` option to tell each step what contract to use. The contract and its result will now use your name instead of `default`.

{{  "contract_test.rb:name-res" | tsnippet }}

Use this if your operation has multiple contracts.

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


### Manual Extraction

You can plug your own complex logic to extract params for validation into the pipe.

{{  "contract_test.rb:key-extr" | tsnippet }}

Note that you have to set the `self["params.validate"]` field in your own step, and - obviously - this has to happen before the actual validation.

Keep in mind that `&` will deviate to the left track if your `extract_params!` logic returns falsey.


## Dependency Injection

In fact, the operation doesn't need any reference to a contract class at all.

{{  "contract_test.rb:di-constant" | tsnippet }}

The contract can be injected when calling the operation.

A prerequisite for that is that the contract class is defined.

{{  "contract_test.rb:di-constant-contract" | tsnippet }}

When calling, you now have to provide the default contract class as a dependency.

{{  "contract_test.rb:di-contract-call" | tsnippet }}

This will work with any name if you follow [the naming conventions](#name).

## Manual Build

To manually build the contract instance, e.g. to inject the current user, use `builder:`.

{{  "contract_test.rb:builder-option" | tsnippet }}

Note how the contract's class and the appropriate model are offered as kw arguments. You're free to ignore these options and use your own assets.

As always, you may also use a proc.

{{  "contract_test.rb:builder-proc" | tsnippet }}

## Result Object

The operation will store the validation result for every contract in its own result object.

The path is `result.contract.#{name}`.

{{  "contract_test.rb:result" | tsnippet }}

Each result object responds to `success?`, `failure?`, and `errors`, which is an `Errors` object. TODO: design/document Errors. WE ARE CURRENTLY WORKING ON A UNIFIED API FOR ERRORS (FOR DRY AND REFORM).
