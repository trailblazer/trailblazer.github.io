---
layout: operation-2-1
title: "Wiring API"
gems:
  - ["trailblazer-operation", "trailblazer/trailblazer-operation", "2.1"]
code: ../trailblazer-operation/test/docs,wiring_test.rb,master
---

<i class="fa fa-download" aria-hidden="true"></i> Where's the [**EXAMPLE CODE?**](https://github.com/trailblazer/trailblazer-operation/blob/master/test/docs/wiring_test.rb)

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

The easiest way to nest operations or activities is to use the `Nested` macro.

{% callout %}
Note that the `Nested()` macro currently comes with the `trailblazer` gem (**not** the `operation` gem) but its behavior might be moved to the DSL in the future so this macro might become obsolete.
{% endcallout %}

A nestable object can be anything, for example an `Operation`.

{{ "fast_test.rb:ft-nested:../trailblazer/test/docs:master" | tsnippet : "ign" }}

Note that the first step, if unsuccessful, will error out on the `fail_fast` track and stop in its `End.fail_fast` end.

<img src="/images/2.1/trailblazer/ft-nested.png">

When nesting this operation into another `Memo::Create`, the `Nested` macro helps connecting the nested outputs.

{{ "fast_test.rb:ft-create:../trailblazer/test/docs:master" | tsnippet : "igncr" }}

All ends with known semantics will be automatically connected to its corresponding tracks in the outer operation.

<img src="/images/2.1/trailblazer/ft-create.png">

As you can see, per default, if the nested operation ends on its `End.fail_fast`, it will also skip the rest of the outer operation and error out on the outer fail_fast track.

You can use the wiring API to reconnect outputs of nested activities.

{{ "fast_test.rb:ft-rewire:../trailblazer/test/docs:master" | tsnippet : "ignrw" }}

In this example, we reconnect the inner's `End.fail_fast` to the `failure` track on the outside.

<img src="/images/2.1/trailblazer/ft-rewire.png">

This wiring will result in the user of `Memo::Create` not "seeing" that the inner operation errored out via fail_fast and will instead use the outer `failure` track that could contain additional error handlers, recover, etc.

You may use the entire wiring API to connect nested outputs at your convenience.

## Connections

The four standard tracks in an operation represent an _extended railway_. While they allow to handle many situations, they sometimes can be confusing as they create hidden semantics. This is why you can also define explicit, custom connections between tasks and even attach task not related to the railway model.

### Connections: By ID

If you need to connect two tasks or events explicitly, you may do so by defining an `Output` from the outgoing task.

{{ "target-id" | tsnippet : "target-id-methods" }}

This operation uploads a file. In the first step, it figures out whether or not that file already exists, and skips the upload part if it has seen the file before. Here's the circuit.

<img src="/images/2.1/trailblazer/target-id.png">

The existing output can be reconnected by using `Output` and specifying a semantic, only. For a normal `step` task, this means the output supposed to go on the left track will be rewired, or in other words, a falsey value returned from `new?` will go straight to `index`.

Referencing an explicit target must happen by id, and can both point forward or backward.

Note that you can also reference `Start.default`, and end events like `End.success`.

## Recover

Error handlers on the left track are the perfect place to "fix things". This means you might want to return to the right track. We call this a _recover_ task. For example, if you need to upload a file to S3, if that doesn't work, try with Azure, and if that still doesn't play, with Backblaze. This is a [common pattern when dealing with external APIs](https://github.com/trailblazer/trailblazer/issues/190).

You can simply put recover steps on the left track, and wire their `:success` output back to the right track (which the operation knows as `:success`).

{{ "fail-success" | tsnippet : "fail-success-methods" }}

The resulting circuit looks as follows.

<img src="/images/2.1/trailblazer/recover.png">

The `Output(:success)` DSL call will find the task's `:success`-colored output and connect it to the right (`:success`) track. The recover tasks themselves can now return a boolean to direct the flow.

    class Memo::Upload < Trailblazer::Operation
      def upload_to_s3(options, s3:, file:, **)
        s3.upload_file(file) # returns true or false
      end
    end

## Decider

If you want to stay on one path but need to branch-and-return to model a decision, use the decider pattern.

{{ "decider" | tsnippet : "decm" }}

In this example, the success track from `find_model` will go to `update` whereas the `failure` output gets connected to `create`, giving the circuit a diamond-shaped flow.

<img src="/images/2.1/trailblazer/decider.png">

Note that we're using properties of the _magnetic_ API here: by polarizing (or _coloring_) the `failure` output of `find_model` to `:create_route` (which is a random name we picked), and making `create` being attracted to that very polarization, the failure output "snaps" to that task automatically.

The cool feature with the magnetic API in this example is that you don't need to know what is the specific target of a connection, allowing to push multiple tasks onto that new `:create_route` track, if you needed that.

## End

When traversing the railway, per default the circuit will deviate to the error track (`:failure`) when a `step` returns a falsey value. You can also wire the step's error output to a custom end. This is incredibly helpful if your operation needs to communicate what exactly happened inside to the outer world, [a pattern used in Endpoint](endpoint.html).

{{ "end" | tsnippet : "methods" }}

The `End` DSL method will create a new end event, the first argument being the name, the second the semantic.

The diagram now has a new "error" track.

<img src="/images/2.1/trailblazer/end.png">

The `find_model` step now has its dedicated failure end. This allows to detect a `404` error without having to guess what might have happened. Please note how that new "error track" does not interfere with other `fail` tasks.

## Path


## Task Implementation (?)

## Terminology

TRB flows, you implement

delete

## Doormat Step

Very often, you want to have one or multiple "last steps" in an operation, for instance to generically log errors or success messages. We call this a _doormat step_.

### Doormat Step: Before

The most elementary way to achieve this is using the `:before` option.

{{ "doormat_test.rb:doormat-before" | tsnippet : "im" }}

Note that `:before` is a DSL option and not exactly related to the wiring API. Using this option, the inserted step will be "moved up" as if you had actually called it before the targeted `:before` step.

<img src="/images/2.1/trailblazer/doormat-before.png">

### Doormat Step: Group

An easier way to place particular steps always into the end section is to use the `:group` option.

{{ "doormat_test.rb:doormat-group" | tsnippet : "methods" }}


The resulting `Memo::Create`'s circuit is identical to the [last example](#doormat-step-before).

Note how this can be used for ["template operations"](#group) where the inherited class really only adds its concrete steps into the existing layout.

## Sequence Options

In addition to wiring options, there are a handful of other options known as _sequence options_. They configure where a task goes when inserted, and helps with introspection and tracing.

### Sequence Options: id

You can name each step using the `:id` option.

{{ "id" | tsnippet : "id-methods" }}

This is advisable when planning to override a step via a module or inheritance or when reconnecting it. Naming also shows up in tracing and introspection. Defaults names are given to steps without the `:id` options, but these might be awkward sometimes.

{{ "id-inspect" | tsnippet }}

### Sequence Options: delete

When it's necessary to remove a task, you can use `:delete`.

{{ "delete" | tsnippet }}

The `:delete` option can be helpful when using modules or inheritance to build concrete operations from base operations. In this example, a very poor one, the `validate` task gets removed, assuming the `Admin` won't need a validation

{{ "delete-inspect" | tsnippet }}

All steps are inherited, then the deletion is applied, as the introspection shows.

<img src="/images/2.1/trailblazer/memo-delete.png">

### Sequence Options: before

To insert a new task before an existing one, for example in a subclass, use `:before`.

{{ "before" | tsnippet : "before-methods"}}

The circuit now yields a new `policy` step before the inherited tasks.

<img src="/images/2.1/trailblazer/memo-before.png">

### Sequence Options: after

To insert after an existing task, you might have guessed it, use the `:after` option with the exact same semantics as `:before`.

{{ "after" | tsnippet : "after-methods" }}

The task is inserted after, as the introspection shows.

{{ "after-inspect" | tsnippet }}

### Sequence Options: replace

Replacing an existing task is done using `:replace`.

{{ "replace" | tsnippet : "replace-methods" }}

Replacing, obviously, only replaces in the applied class, not in the superclass.

{{ "replace-inspect" | tsnippet }}

## Group

The `:group` option is the ideal solution to create template operations, where you declare a basic circuit layout which can then be enriched by subclasses.

{{ "doormat_test.rb:template" | tsnippet : "tmethods" }}

The resulting circuit, admittedly rather useless, will look as follows.

<img src="/images/2.1/trailblazer/group-template.png">

Subclasses can now insert their actual steps without any sequence options needed.

{{ "doormat_test.rb:template-user" | tsnippet : "meths" }}

Since all logging steps defined in the template operation are placed into groups, the concrete steps sit in the middle.

<img src="/images/2.1/trailblazer/doormat-before.png">

It is perfectly fine to use the `:group` and other sequence options again, in subclasses. Also, multiple inheritance levels will work.
