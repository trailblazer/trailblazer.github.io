---
layout: operation-2-1
title: "Activity API"
---

The Activity API defines interfaces to steps, tasks, circuits and activities.

## Operation vs. Activity

An `Activity` allows to define and maintain a graph, that at runtime will be used as a circuit. It defines the boxes, arrows and signals and makes sure when running the activity, the circuit with your rules will be run.

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

## Activity Interface

The _Activity interface_ allows you to use any kind of object as an activity, as long as it follows this interface. This is especially helpful when composing complex workflows where activities call activities, etc. as it doesn't limit you to operations, only.

You need to expose two public methods, only.

### Activity Interface: Call

The `call` method runs the instance with a provided set of arguments.

    results = activity.call( last_signal, options, flow_options, *args )

The ingoing arguments are

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
