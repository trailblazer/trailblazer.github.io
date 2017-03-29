---
layout: operation2
title: "Workflow: Circuit"
---

Circuit provides a simplified [flowchart](https://en.wikipedia.org/wiki/Flowchart) implementation with terminals (for example, start or end state), connectors and tasks (processes). It allows to define the flow (the actual *circuit*) and execute it.

Circuit refrains from implementing deciders. The decisions are encoded in the output signals of tasks.

`Circuit` and `workflow` use [BPMN](http://www.bpmn.org/) lingo and concepts for describing processes and flows. This document can be found in the [Trailblazer documentation](http://trailblazer.to/gems/workflow/circuit.html), too.

{% callout %}
The `circuit` gem is the lowest level of abstraction and is used in `operation` and `workflow`, which both provide higher-level APIs for the Railway pattern and complex BPMN workflows.
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

In order to define an activity, you can use the BPMN editor of your choice and run it through the Trailblazer circuit generator, use our online tool (if you're a PRO member) or simply define it using plain Ruby.

{{ "test/docs/activity_test.rb:basic:../trailblazer-circuit" | tsnippet }}

The `Activity` function is a convenient tool to create an activity. Note that the yielded object allows to access *events* from the activity, such as the `Start` and `End` event that are created per default.

This defines the control flow - the next step is to actually implement the tasks in this activity. A *task* usually maps to a particular box in your diagram.

## Task



## Call



## Event

## Operation

## minimize Nil errors

* kw args guard input

## ARCHITECTURE

* Theoretically, you can build any network of circuits with `Circuit`, only.
* DSL: `Activity` helps you building circuits and wiring them by exposing its events.
* `Task` is Options::KW. It will be converted to be its own circuit, so you can override and change things like KWs, what is returned, etc. ==> do some benchmarks, and play with circuit-compiled.

* An `Operation` simply is a `circuit`, with a limited, linear-only flow.



## Activity

An `Activity` has start and end events. While *events* in BPMN have behavior and might trigger listeners, in `circuit` an event is simply a state. The activity always ends in an `End` state. It's up to the user to interpret and trigger behavior.



## TODO:

* oPTIONS::kW

