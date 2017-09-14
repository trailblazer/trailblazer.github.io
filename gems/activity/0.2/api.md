---
layout: operation-2-1
title: "Activity API"
---

The Activity API defines interfaces to steps, tasks, circuits and activities.

## Operation vs. Activity

An `Activity` allows to define and maintain a graph, that at runtime will be used as a circuit. Or, in other words, it defines the boxes, circles, arrows and signals between them, and makes sure when running the activity, the circuit with your rules will be executed.

Please note that an `Operation` simply provides a neat DSL for creating an `Activity` with a railway-oriented wiring (left and right track). An operation _always_ maintains an activity internally.

{% row %}
~~~6
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

~~~6
  Check the operation to the left. The DSL to create the activity with its graph is very different to `Activity`, but the outcome is a simple activity instance.

  <img src="/images/graph/op-vs-activity.png">

{% endrow %}

When `call`ing an operation, several transformations on the arguments are applied, and those are passed to the `Activity#call` invocation. After the activity finished, its output is transformed into a `Result` object.

## Activity: From_Hash

Instead of using an operation, you can manually define activities by using the `Activity.from_hash` builder.

{{ "test/docs/activity_test.rb:basic:../trailblazer-activity:master" | tsnippet }}

The block yields a generic start and end event instance. You then connect every _task_ in that hash (hash keys) to another task or event via the emitted _signal_.

When `call`ing that activity, here's what could happen.

    results = activity.( nil, {}, {} )

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

## Signal

Signals are objects emitted or returned by tasks and activities. Every signal a task returns needs to be wired to a following task or event in the circuit. Otherwise, you will see a `IllegalOutputSignalError` from the circuit at run-time.

Please note that a signal can be any object, it doesn't necessarily have to be `Circuit::Right` or `Circuit::Left`. These are simple generic library signals, but you can use strings, your own classes or whatever else makes sense for you.

## Task

## Step


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




