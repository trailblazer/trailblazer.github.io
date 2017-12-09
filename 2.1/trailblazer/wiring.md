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

Ignoring the actual implementation of those steps, here's the corresponding circuit diagram for this operation.

<img src="/images/2.1/trailblazer/memo-basic.png">

If you follow the diagram's flow from left to right, you will see that the order of the DSL calls reflects the order of the tasks (the _boxes_) in the circuit. The three DSL methods have the following characteristics.

* **`step`** always puts the task on the upper, "right" track, but with two outputs per box: one to the next successful step, one to the nearest fail box. The chain of "successful" boxes in the top is the _right track_. The lower chain is the infamous _left track_.
* **`pass`** is on the right track, but without an outgoing connection to the left track. It is always assumed successful, as seen in the `uuid` task.
* **`fail`** puts the box on the lower track and doesn't connect it back to the right track.

It becomes obvious that the circuit has well-defined properties. This model is [called a _railway_](https://fsharpforfunandprofit.com/rop/) and we shamelessly stole this concept. The great idea here is that error handling comes for free via the left track since you do not need to orchestrate your code with `if` and `else` but simply **implement the tasks** and **Trailblazer takes over flow control**.

## Task Implementation (?)

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
