---
layout: operation-2-1
title: "Wiring API"
gems:
  - ["trailblazer-operation", "trailblazer/trailblazer-operation", "2.1"]
code: ../operation/test/docs,wiring_test.rb
---

## Overview

When you run an operation like `Memo::Create.()`, it will internally execute its _circuit_. This simply means the operation will traverse its railway, call the `step`s you defined, deviate to different tracks, and so on. This document describes how those _circuits_ are created, the so called _wiring API_.

An operation provides three DSL methods to define the circuit.

* `step` is used when the result of the step logic is important.
* `pass` will always remain on the "right" track.
* `fail` is the opposite, and will stay on the "left" track.

To illustrate this, please take a look at the operation code along with a diagram of its circuit.

{{ "memo-op" | tsnippet : "memo-methods" }}


## Terminology

TRB flows, you implement

delete

## Doormat Step

Very often, you want to have one or multiple "last steps" in an operation, for instance to generically log errors or success messages. We call this a _doormat step_.

### Doormat Step: Before

The most elementary way to achieve this is using the `:before` option.


Note that `:before` is a DSL option and not related to the Graph API. It will move up steps using this option before `:log_success!`, as if you had actually called it before this step.

<img src="/images/graph/doormat-before.png">

### Doormat Step: Before with Inheritance

The same can be achieved using inheritance. In a generic base operation, you can define concept- or application-wide steps.


Concrete steps are added in the subclass.


The resulting `Create`'s activity is identical to the [last example](#doormat-step-before).
