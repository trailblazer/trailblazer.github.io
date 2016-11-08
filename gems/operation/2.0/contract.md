---
layout: operation2
title: Operation Contract
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0"]
---

## Cheatsheet

## Result

The operation will store the validation result for every contract in its own result object.

    result = Create.({ id: 1 })

    result["result.contract"].success? #=> true
    result["result.contract"].errors #=> {}

The path is `result.contract[.name]`, e.g. `result["result.contract.params"]`.


## Dry-Schema

Show how to use schema for params even before op is instantiated (see contract_test).
