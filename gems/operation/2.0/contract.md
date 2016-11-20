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

## Cheatsheet

## Result

The operation will store the validation result for every contract in its own result object.

    result = Create.({ id: 1 })

    result["result.contract"].success? #=> true
    result["result.contract"].errors #=> {}

The path is `result.contract[.name]`, e.g. `result["result.contract.params"]`.


## Dry-Schema

Show how to use schema for params even before op is instantiated (see contract_test).
