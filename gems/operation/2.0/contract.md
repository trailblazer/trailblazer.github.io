---
layout: operation2
title: Operation Contract
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0", "1.1"]
---

The `Contract` module helps you defining contracts to validate incoming data and object states. It assists with instantiating and validating data using those contracts at runtime.

## Overview: Reform

Most contracts are [Reform](/gems/reform) objects that you can define and validate in the operation. Reform is a fantastic tool for deserializing and validating deeply nested hashes, and then, when valid, write those to the database using your persistence layer such as ActiveRecord.

{{  "contract_test.rb:overv-reform" | tsnippet }}

## Cheatsheet

## Result

The operation will store the validation result for every contract in its own result object.

    result = Create.({ id: 1 })

    result["result.contract"].success? #=> true
    result["result.contract"].errors #=> {}

The path is `result.contract[.name]`, e.g. `result["result.contract.params"]`.


## Dry-Schema

Show how to use schema for params even before op is instantiated (see contract_test).
