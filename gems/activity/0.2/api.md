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
