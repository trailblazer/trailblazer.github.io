---
layout: operation2
title: Operation Model
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0"]
---

## Cheatsheet

## Result

The operation will store the model retrieval result when used with `find_by`.

    result = Create.({ id: 1 })

    result["result.model"].success? #=> true

The model is saved in `["model"]`.

    result["model"] #=> <Song id:1>
