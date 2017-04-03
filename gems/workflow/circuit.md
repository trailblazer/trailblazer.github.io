---
layout: operation2
title: "Workflow: Circuit"
---

_Everything's a Circuit._

Circuit provides a generic [flowchart](https://en.wikipedia.org/wiki/Flowchart) implementation for workflows.

A circuit is a flow composed of tasks with connections and terminals (for example, start or end state). Circuit refrains from implementing deciders. The decisions are encoded in the output signals of tasks.

`Circuit` and `workflow` use [BPMN](http://www.bpmn.org/) lingo and concepts for describing processes and flows. This document can be found in the [Trailblazer documentation](http://trailblazer.to/gems/workflow/circuit.html), too.

{% callout %}
The `circuit` gem is the lowest level of abstraction and is a very generic implemention. It is used in `operation` and `workflow`, which both provide higher-level APIs for the Railway pattern and complex BPMN workflows.
{% endcallout %}

## Installation

To use circuits, activities and nested tasks, you need one gem, only.

```ruby
gem "trailblazer-circuit"
```

The `trailblazer-circuit` gem is often just called the `circuit` gem. It ships with the `operation` gem and implements the internal Railway.

## Overview

The following diagram illustrates a common use-case for `circuit`, the task of publishing a blog post.

<img src="/images/diagrams/blog-bpmn1.png">

After writing and spell-checking, the author has the chance to publish the post or, in case of typos, go back, correct, and go through the same flow, again. Note that there's only a handful of defined transistions, or connections. An author, for example, is not allowed to jump from "correct" into "publish" without going through the check.

The `circuit` gem allows you to define this *activity* and takes care of implementing the control flow, running the activity and making sure no invalid paths are taken.

Your job is solely to implement the tasks and deciders put into this activity - you don't have to take care of executing it in the right order, and so on.

## Definition

In order to define an activity, you can use the BPMN editor of your choice and run it through the Trailblazer circuit generator, use our online tool (if [you're a PRO member](http://pro.trailblazer.to)) or simply define it using plain Ruby.

{{ "test/docs/activity_test.rb:basic:../trailblazer-circuit" | tsnippet }}

The `Activity` function is a convenient tool to create an activity. Note that the yielded object allows to access *events* from the activity, such as the `Start` and `End` event that are created per default.

This defines the control flow - the next step is to actually implement the tasks in this activity.

## Task

A *task* usually maps to a particular box in your diagram. Its API is very simple: a task needs to expose a `call` method, allowing it to be a lambda or any other callable object.

{{ "test/docs/activity_test.rb:write:../trailblazer-circuit" | tsnippet }}

It receives all arguments returned from the task run before. This means a task should return everything it receives.

To transport data across the flow, you can change the return value. In this example, we use one global hash `options` that is passed from task to task and used for writing.

The first return value is crucial: it dictates what will be the next step when executing the flow.

For example, the `SpellCheck` task needs to decide which route to take.

{{ "test/docs/activity_test.rb:spell:../trailblazer-circuit" | tsnippet }}

It's as simple as returning the appropriate signal.

{% callout %}
You can use any object as a direction signal and return it, as long as it's defined in the circuit.
{% endcallout %}

## Call

After defining circuit and implementing the tasks, the circuit can be executed using its very own `call` method.

{{ "test/docs/activity_test.rb:call:../trailblazer-circuit" | tsnippet }}

The first argument is where to start the circuit. Usually, this will be the activity's `Start` event accessable via `activity[:Start]`.

All options are passed straight to the first task, which in turn has to make sure it returns an appropriate result set.

The activity's return set is the last run task and all arguments from the last task.

{{ "test/docs/activity_test.rb:call-ret:../trailblazer-circuit" | tsnippet }}

As opposed to higher abstractions such as `Operation`, it is completely up to the developer what interfaces they provide to tasks and their return values. What is a mutable hash here could be an explicit array of return values in another implementation style, and so on.

## Tracing

For debugging or simply understanding the flows of circuits, you can use tracing.

{{ "test/docs/activity_test.rb:trace-act:../trailblazer-circuit" | tsnippet }}

The second argument to `Activity` takes debugging information, so you can set readable names for tasks.

When invoking the activity, the `:runner` option will activate tracing and write debugging information about any executed task onto the `:stack` array.

{{ "test/docs/activity_test.rb:trace-call:../trailblazer-circuit" | tsnippet }}

The `stack` can then be passed to a presenter.

{{ "test/docs/activity_test.rb:trace-res:../trailblazer-circuit" | tsnippet }}

Tracing is extremely efficient to find out what is going wrong and supersedes cryptic debuggers by many times. Note that tracing also works for deeply nested circuits.

{% callout %}
🌅 In future versions of Trailblazer, our own debugger will take advantage of the explicit, traceable nature of circuits and also integrate with Ruby's exception handling.

Also, more available tracing options will make debugging of complex, nested workflows easier.
{% endcallout %}

## Connection

A task is not limited to two outgoing connections.

{% row %}
  ~~~6
<img src="/images/diagrams/blog-bpmn-tolerate.png">
  ~~~6
 Tasks can emit different types of direction signals and maintain many connections. The only requirement is that all possible signals are wired in the circuit.
{% endrow %}

You can emit any direction signal you want, and even use it to transport additional state. Using `Right` and `Left` is simply a convention following the mental image of a binary flow.

{{ "test/docs/activity_test.rb:toll:../trailblazer-circuit" | tsnippet }}

For example, the `SpellCheck3` task here emits a `:maybe` symbol which is then wired to the follow-up task `Warn`. Its implementation contains the decider that returns the appropriate direction.

{{ "test/docs/activity_test.rb:toll-spell:../trailblazer-circuit" | tsnippet }}

The decoupling of return values (directions) and the actual wiring is by design and allows to reconnect tasks and their outputs without having to change the implementation.

## Event

Sometimes it is necessary to exit an activity using different end states, or *events*, as we call them in BPMN. An activity can have multiple end events.

{% row %}
  ~~~6
<img src="/images/diagrams/blog-bpmn-events.png">
  ~~~6
While *events* in BPMN have behavior and might trigger listeners, an event in `circuit` is simply a state. The activity always exits from an `End` state. It's up to the user to interpret and trigger behavior.

{% callout %}
The [`workflow` gem](/gems/workflow/index.html) adds additional semantics, real-time messaging, parallel activities, and suspend/resume events to the primitive circuit.
{% endcallout %}
{% endrow %}

Additional `End` events must be defined when creating the `Activity`.

{{ "test/docs/activity_test.rb:events:../trailblazer-circuit" | tsnippet }}

Events are provided as the second `Activity` argument. All `:end` events will be considered stop events that exit the circuit.

## Nested

## Operation

If you need a higher abstraction of `circuit`, check out Trailblazer's [operation](localhost:4000/gems/operation/2.0/api.html) implemenation which provides a simple Railway-oriented interface to create linear circuits.

<!-- ## minimize Nil errors

* kw args guard input

## ARCHITECTURE

* Theoretically, you can build any network of circuits with `Circuit`, only.
* DSL: `Activity` helps you building circuits and wiring them by exposing its events.
* `Task` is Options::KW. It will be converted to be its own circuit, so you can override and change things like KWs, what is returned, etc. ==> do some benchmarks, and play with circuit-compiled.

* An `Operation` simply is a `circuit`, with a limited, linear-only flow.



## TODO:

* oPTIONS::kW
 -->
