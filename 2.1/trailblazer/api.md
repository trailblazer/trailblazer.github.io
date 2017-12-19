---
layout: operation-2-1
title: Operation 2.1 API
gems:
  - ["trailblazer-operation", "trailblazer/trailblazer-operation", "2.1"]
code: ../trailblazer/test/docs,trace_test.rb,master
---

## Overview

An operation or an activity provides two APIs: The wiring API focuses on defining the tasks and their connections. It is so versatile that it [deserves its own document](wiring.html). The other part is about actually _implementing_ those tasks (or "boxes") and is called the _operation API_, and this document describes it.

## Control Flow

As already discussed briefly, designing connections and tasks happens through the [wiring API](wiring.html). The goal of the separation is that tasks can focus on one thing: implementing the actual business logic without having to worry about the control flow. To do so, they simply emit (or `return`) special objects called _signals_, which are then translated into a connection. After this, the circuit engine will move on to the next task that is targeted by the connection.

## Task API

## Step API

## Result

### Primary Binary State

The primary state is decided by the activity's end event superclass. If derived from `Railway::End::Success`, it will be interpreted as successful, and `result.success?` will return true, whereas a subclass of `Railway::End::Failure` results in the opposite outcome. Here, `result.failure?` is true.

### Result: End Event

You can access the end event the Result wraps via `event`. This allows to interpret the outcome on a finer level and without having to guess from data in the options context. (See Endpoint)

    result = Create.( params )

    result.event #=> #<Railway::FastTrack::PassFast ...>

## Trace

For debugging or understanding the flows of activities, you can use tracing.

With operations, the simplest way is to use the `trace` method. It has the exact same signature as `call`.

{{ "trace" | tsnippet }}

Use `Result#wtf?` to render a simple view of all steps that were involved in the run.

Tracing starts to make things a lot easier for more complex, nested operations.

{{ "trace-cpx" | tsnippet }}

Please refer to the activity docs for a [low-level interface tracing](/gems/activity/0.2/flow.html#trace).

{% callout %}
In future versions, tracing will also display variables with improved configurability. This will be added very very shortly.

Very soon, you can debug your code in real-time visually using the [PRO editor](http://pro.trailblazer.to).
{% endcallout %}
