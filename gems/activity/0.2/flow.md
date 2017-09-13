---
layout: operation2
title: Activity API
gems:
  - ["trailblazer-activity", "trailblazer/trailblazer-activity", "0.2"]
---

## Trace

To track the path of a running activity (also called _trailing_) along with the variables before and after each task, use tracing.

Tracing works with any level of nesting. Please consider this simple example.

{{ "activity_test.rb:trace-act:../trailblazer-activity/test/docs" | tsnippet }}

Instead of `call`ing the activity directly, let the `Trace` module take care of setting up tracing and call the activity via `Trace.call`.

{{ "activity_test.rb:trace-call:../trailblazer-activity/test/docs" | tsnippet }}

All arguments to `Trace.call` are directly passed to the activity's call.

Internally, tracing is implemented by adding two steps to every [task's task wrap](task_wrap.html): one before and one after `task_wrap.call_task`. These will store various data, such as the runtime data going in and out of the task.

Note that you could also invoke tracing only for selected tasks, in case you want to debug some specific part, only (we will add docs shortly).

### Trace: Present

The `Trace.call` method returns a `Stack` instance, followed by the original return values of the activity's `call`.

To quickly visualize the traced path, use `Present.tree`.

{{ "activity_test.rb:trace-res:../trailblazer-activity/test/docs" | tsnippet }}

This prints a more or less cryptic representation of the path the activity took.

{% callout %}
In future versions, tracing will also display variables with improved configurability. This will be added very very shortly.

Very soon, you can debug your code in real-time visually using the [PRO editor](http://pro.trailblazer.to).
{% endcallout %}
