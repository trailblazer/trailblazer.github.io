---
layout: operation-2-1
title: "Trailblazer 2.1: What you need to know."
code: ../operation/test/docs,wiring_test.rb,master
---

After almost one year of development, the 2.1 release is very near, and we're proud to tell you everything about the new features we were adding, and some internals we've changed.

Overall, the public APIs haven't changed, or there are soft deprecations to explain what you need to do.

## 1. New `call` API

In versions before 2.1, the automatic merging of the `params` part and the additional options was confusing many new users and an unnecessary step.

    # old style
    result = Memo::Create.( params, "current_user" => current_user )

The first argument (`params`) was merged into the second argument using the key `"params"`. You now pass one hash to `call` and hence do the merging yourself.

    # new style
    result = Memo::Create.( params: params, current_user: current_user )

Your steps use the existing API, and everything here is as it used to be before.

    class Memo::Create < Trailblazer::Operation
      step :create_model

      def create_model(options, params:, **)
        # ..
      end
    end

The new `call` API is much more consistent and takes away another thing we kept explaining to new users - an indicator for a flawed API.

{% callout %}
For a soft deprecation, do this in an initializer:

    require "trailblazer/deprecation/call"

You will get a bunch of warnings, so fix all `Operation.()` calls and remove the `require` again.
{% endcallout %}

## 2. Symbol vs. String Keys

If you mixed up `:symbol` and `"string"` keys when accessing the `options` context object, there are good news for you: we use symbol keys now wherever possible. Only namespaced keys like `"contract.default.class"` are still strings, but `:model`, `:params` or `:current_user` are all symbols.

    result = Memo::Create.( params: params, current_user: current_user )

As always, you can still access the arguments via keyword arguments, as [shown above](#new-call-api). Nevertheless, these arguments must now be accessed and overridden with a symbol.

    def my_step(options, **)
      options[:model] = OpenStruct.new
    end

Nothing has changed in the implementation; we just changed the convention.

{% callout %}
For a soft deprecation, do this in an initializer:

    require "trailblazer/deprecation/context"

It will generate hundreds of warnings where you still use string keys but mustn't, so change them and then remove the `require`.

{% endcallout %}


## 2. Unlimited Wiring

Besides the fact that you can now use operations and activities in more complex compounds [to model realistic applications](#application-workflows) and state machines, with 2.1 it's possible to model flows in operations that go beyond the railway. This is often necessary when the control flow needs more than two track, or when extracting more complex flows into new operations is too complicated and thus not desirable.

Check the new [→ wiring docs](/2.1/trailblazer/wiring.html).

For example, you can now actually _use_ the `failure` track for logic, and easily deviate back to the right `success` track.

{{ "fail-success" | tsnippet : "fail-success-methods" }}

This will result in the following diagram.

<img src="/images/2.1/trailblazer/recover.png">

We call this the [_recover_ pattern](/2.1/trailblazer/wiring.html#recover).

However, you're not limited to left and right track, you can connect arbitrary tasks, or solve more complex problems with branching circuits.

examples coming

{% callout %}
  For a more streamlined readability, we aliased the step DSL methods.

    step :my_step
    pass :always_success # alias success
    fail :error_handler  # alias failure

  Looking better, right?
{% endcallout %}

...


## 3. Simpler `Nested`

in/out
rewire

## 4. Tracing

The coolest feature.

## 4. Extended Macro API

## 6. Application Workflows

## 10. New Gems