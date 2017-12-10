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

## Fast Track

You can "short-circuit" specific tasks using a built-in mechanism called _fast track_.

### Fast Track: pass_fast

To short-circuit the successful connection of a task use `:pass_fast`.

{{ "pf-op" | tsnippet : "pf-methods" }}

If `validate` turned out to be successful, no other task won't be invoked, as visible in the diagram.

<img src="/images/2.1/trailblazer/memo-pass-fast.png">

As you can see, `validate` will still be able to deviate to the left track, but all following success tasks like `index` can't be reached anymore, so this option has its limits. You might use `:pass_fast` with multiple steps.

### Fast Track: fail_fast

The `:fail_fast` option comes in handy when having to early-out from the error (left) track.

{{ "ff-op" | tsnippet : "ff-methods" }}

The marked task(s) will be connected to the fail-fast end.

<img src="/images/2.1/trailblazer/memo-fail-fast.png">

There won't be an ongoing connection to the next left track task. As always, you can use that option multiple times, all fail_fast connections will end on the same `End.fail_fast` end.

### Fast Track: fail_fast with step

You can also use `:fail_fast` with `step` tasks.

{{ "ff-step-op" | tsnippet : "ff-step-methods" }}

The resulting diagram shows that `index` won't hit any other left track boxes in case of failure, but errors-out directly.

<img src="/images/2.1/trailblazer/memo-fail-fast-step.png">

All fail_fast connections will end on the same `End.fail_fast` end.

### Fast Track: fast_track

Instead of hard-wiring the success or failure output to the respective fast-track end, you can decide what output to take dynamically, in the task. However, this implies you configure the task using the `:fast_track` option.

{{ "ft-step-op" | tsnippet : "ft-step-methods"}}

By marking a task with `:fast_track`, you can create up to four different outputs from it.

<img src="/images/2.1/trailblazer/memo-fast-track.png">

Both `create_model` and `assign_errors` have two more outputs in addition to their default ones: one to `End.pass_fast`, one to `End.fail_fast` (note that this option works with `pass`, too). To make the execution take one of the fast-track paths, you need to emit a special signal from that task, though.

{{ "ft-create" | tsnippet }}

In this example, the operation would end successfully with an instantiated `Memo` model and no other steps taken, if called with an imaginary option `create_empty_model: true`. This is because it then returns the `Railway.pass_fast!` signal. Here's what the invocation could look like.

{{ "ft-call" | tsnippet }}

Identically, the task on the left track `assign_errors`, could pick what path it wants the token to travel.

{{ "ft-call-err" | tsnippet }}

This time, the second error handler `log_errors` won't be hit.

## Signals

A _signal_ is the object that is returned from a task. It can be any kind of object, but per convention, we derive signals from `Trailblazer::Activity::Signal`. When using the wiring API with `step` and friends, your tasks will automatically get wrapped so the returned boolean [gets translated into a signal](https://github.com/trailblazer/trailblazer-operation/blob/master/lib/trailblazer/operation/railway/task_builder.rb).

You can bypass this by returning a signal directly.

{{ "signal-validate" | tsnippet }}

Historically, the signal name for taking the success track is `Right` whereas the signal for the error track is `Left`. Instead of using the signal constants directly (which some users, for whatever reason, prefer), you may use signal helpers. The following snippet is identical to the one above.

{{ "signalhelper-validate" | tsnippet }}

Available signal helpers per default are `Railway.pass!`, `Railway.fail!`, `Railway.pass_fast!` and `Railway.fail_fast!`.

{% callout %}
Note that those signals **must have outputs that are connected to the next task**, otherwise you will get a `IllegalOutputSignalError` exception. The PRO editor or tracing can help understanding.

Also, keep in mind that the more signals you use, the harder it will be to understand. This is why the operation [enforces the `:fast_track` option](#fast-track-fasttrack) when you want to use `pass_fast!` and `fail_fast!` - so both the developer reading your operation and the framework itself know about the implications upfront.
{% endcallout %}

## Nested Activities

## Custom Connections

The four standard tracks in an operation represent an _extended railway_. While they allow to handle many situations, they sometimes can be confusing as they create hidden semantics. This is why you can also define explicit, custom connections between tasks and even attach task not related to the railway model.

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
