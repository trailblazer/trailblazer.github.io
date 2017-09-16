---
layout: operation-2-1
title: "Activity API"
gems:
  - ["trailblazer-activity", "trailblazer/trailblazer-activity", "0.2"]
---

An _activity_ is a collection of connected _tasks_ with one _start event_ and one (or many) _end_ events.

## Overview

{% callout %}
Since TRB 2.1, we use [BPMN](http://www.bpmn.org/) lingo and concepts for describing workflows and processes.
{% endcallout %}

An activity is a workflow that contains one or several tasks. It is the main concept to organize control flow in Trailblazer.

The following diagram illustrates an exemplary workflow where a user writes and publishes a blog post.

<img src="/images/diagrams/blog-bpmn1.png">

After writing and spell-checking, the author has the chance to publish the post or, in case of typos, go back, correct, and go through the same flow, again. Note that there's only a handful of defined transistions, or connections. An author, for example, is not allowed to jump from "correct" into "publish" without going through the check.

The `activity` gem allows you to define this *activity* and takes care of implementing the control flow, running the activity and making sure no invalid paths are taken.

Your job is solely to implement the tasks and deciders put into this activity - Trailblazer makes sure it is executed it in the right order, and so on.

To eventually run this activity, three things have to be done.

1. The activity needs be defined. Easiest is to use the [Activity.from_hash builder](#activity-fromhash).
2. It's the programmer's job (that's you!) to implement the actual tasks (the "boxes"). Use [tasks for that](#task).
3. After defining and implementing, you can run the activity with any data [by `call`ing it](#activity-call).

## Operation vs. Activity

An `Activity` allows to define and maintain a graph, that at runtime will be used as a "circuit". Or, in other words, it defines the boxes, circles, arrows and signals between them, and makes sure when running the activity, the circuit with your rules will be executed.

Please note that an `Operation` simply provides a neat DSL for creating an `Activity` with a railway-oriented wiring (left and right track). An operation _always_ maintains an activity internally.


<pre>
  <code>class Create < Trailblazer::Operation
  step :exists?, pass_fast: true
  step :policy
  step :validate
  fail :log_err
  step :persist
  fail :log_db_err
  step :notify
end
</code>
</pre>

Check the operation above. The DSL to create the activity with its graph is very different to `Activity`, but the outcome is a simple activity instance.

<img src="/images/graph/op-vs-activity.png">


When `call`ing an operation, several transformations on the arguments are applied, and those are passed to the `Activity#call` invocation. After the activity finished, its output is transformed into a `Result` object.

## Activity

To understand how an activity works and what it performs in your application logic, it's easiest to see how activities are defined, and used.

## Activity: From_Hash

Instead of using an operation, you can manually define activities by using the `Activity.from_hash` builder.

{{ "test/docs/activity_test.rb:basic:../trailblazer-activity:master" | tsnippet }}

The block yields a generic start and end event instance. You then connect every _task_ in that hash (hash keys) to another task or event via the emitted _signal_.

## Activity: Call

To run the activity, you want to `call` it.

    my_options = {}
    last_signal, options, flow_options, _ = activity.( nil, my_options, {} )

1. The `start` event is `call`ed and per default returns the generic _signal_`Trailblazer::Circuit::Right`.
2. This emitted (or returned) signal is connected to the next task `Blog::Write`, which is now `call`ed.
3. `Blog::Write` emits another `Right` signal that leads to `Blog::SpellCheck` being `call`ed.
4. `Blog::SpellCheck` defines two outgoing signals and hence can decide what next task to call by emitting either `Right` if the spell check was ok, or `Left` if the post contains typos.
5. ...and so on.

{% row %}
~~~6
<img src="/images/graph/blogpost-activity.png">

~~~6
Visualizing an activity as a graph makes it very straight-forward to understanding the mechanics of the flow.


Note how signals translate to edges (or connections) in the graph, and tasks become vertices (or nodes).
{% endrow %}

The return values are the `last_signal`, which is usually the end event (they return themselves as a signal), the last `options` that usually contains all kinds of data from running the activity, and additional args.

## Activity: From_Wirings

TODO: currently, this is not relevant for normal use cases.

## Signal

Signals are objects emitted or returned by tasks and activities. Every signal returned by a task needs to be wired to a follow-up task or event in the circuit. Otherwise, you will see a `IllegalOutputSignalError` from the circuit at run-time.

Please note that a signal can be any object, it doesn't necessarily have to be `Circuit::Right` or `Circuit::Left`. These are simple generic library signals, but you can use strings, your own classes or whatever else makes sense for you.

The decoupling of return values (signals) and the actual wiring in the activity is by design and allows to reconnect tasks and their outputs without having to change the implementation.

## Task

Every "box" in a circuit is called _task_ in Trailblazer. This is [adopted from the BPMN standard](https://camunda.org/bpmn/reference/#activities-task). A task can be any object with a `call` method: a lambda, a callable object, an operation, an activity, etc. As long as it follows the _task interface_, anything can be plugged into an activity's circuit.

## Task Interface

The task interface is the low-level interface for tasks in activities. It is identical to `call` in the [Activity interface](##activity-interface-call).

    task = lambda do | signal, options, flow_options, *args |
      puts "Hey, I was called!"

      options["model"] = Song.new

      [ Trailblazer::Circuit::Right, options, flow_options, *args ]
    end

While `signal` as the emitted signal from the previous task is usually to be ignored, `options` represents the incoming run-time data, `flow_options` is a library-level data structure, and an arbitrary number of additional incoming arguments need to be accepted **and returned**.

It's up to the task whether to write to `options`, create a new object, etc.

The returned signal (e.g. `Right`) is crucial as it is used to determine the next task after this one.

All returned data is directly passed as input arguments to the next task or event.

{% callout %}
Always remember that the **task interface** is the pure, low-level form for tasks. It allows to access and return any data that is available and relevant for running activities.

The **step interface** is a higher level interface for "tasks" that is [introduced by `trailblazer-operation`](/gems/operation/2.1/api.html#step-interface). It is more convenient to use for developers but gives you a limited number of run-time arguments, only.
{% endcallout %}

Tasks can also be any callable object, for example a class with a `call` class method.

    class MyTask
      def self.call( signal, options, flow_options, *args )
        puts "Hey, I was called!"

        options["model"] = Song.new

        [ Trailblazer::Circuit::Right, options, flow_options, *args ]
      end
    end

## Activity Interface

The _Activity interface_ allows you to use any kind of object as an activity, as long as it follows this interface. This is especially helpful when composing complex workflows where activities call activities, etc. as it doesn't limit you to operations, only.

You need to expose two public methods, only.

* `Activity#call`
* `Activity#outputs`

### Activity Interface: Call

The `call` method runs the instance's circuit with a provided set of arguments.

    results = activity.call( last_signal, options, flow_options, *args )

The inbound arguments are

1. `last_signal` The signal emitted from the previous activity/task. Usually, this is ignored, but it allows you to start the activity from some other point, depending on that `last_signal`. Sometimes, that signal is also called _direction_ in the code base.
2. `options` is runtime data from the caller. Depending on your mutation strategy, this should be treated as immutable.
3. `flow_options` contains additional framework data for flow control, the task wraps, tracing, etc. Leave this alone unless you know what you're doing.
4. `*args` The activity interface requires any additional numbers of arguments to be accepted (and returned!).

The returned objects from the `call` are almost identical to the incoming.

    results #=>

    [ last_signal, options, flow_options, *args ]

Here, `last_signal` is your last signal emitted, and `options` are all old options plus whatever your activity added. All additional arguments must be returned in the same order.

The signature of an activity (`call` arguments and returned objects) is also known as _Task interface_.

### Activity Interface: Outputs

An activity also has to expose the `outputs` method that defines its end events with semantic data.

    activity.outputs #=>

    {
      <Event::End::Success xxx> => {
        role: :success
      },
      <Event::End::Failure xxx> => {
        role: :failure
      },
      <Event::End::Failure 0x1> => {
        role: :unauthorized
      },
    }

Any `last_signal` returned from `call` must be a key in the `outputs` hash. The value hash must contain the key `:role` that specifies a semantical purpose what this end event represents.

{% callout %}
Currently, only `:success` and `:failure` are canonically understood, but with the emerge of the `activity` gem, we expect more standardized ends to come.
{% endcallout %}

The `:role` key makes sure that nested activities' ends can automatically be connected in the composing, outer activity.

## Subprocess

A major concept of both BPMN and Trailblazer is to be able to compose activities with activities. What is a function or a method in programming is a _subprocess_ in BPMN: a nested activity.

__call__
omits start event

