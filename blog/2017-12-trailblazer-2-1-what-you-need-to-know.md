---
layout: operation-2-1
title: "Trailblazer 2.1: What you need to know."
code: ../trailblazer-operation/test/docs,wiring_test.rb,master
---

After almost one year of development, the 2.1 release is very near, and we're proud to tell you everything about the new features we were adding, and some internals we've changed.

Overall, the public APIs haven't changed, or there are soft deprecations to explain what you need to do.

## Functional

All of Trailblazer's internals have been refactored to a more functional, stateless architecture, where only a handful of mutable objects are left. This is not due to us jumping any the hipster band-wagon, or just for the sake of "being functional", it's because we need it.

extend for tracing? no!

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

    |-- #<Workflow::Admin::Resume:0x0000000006ad8b20>
    |-- >ready_for_user_create
    |   |-- #<Trailblazer::Activity::Start:0x0000000006c3a248>
    |   |-- Nested(Root::Admin::Prepare::Present)
    |   |   |-- #<Trailblazer::Activity::Start:0x0000000006c37700>
    |   |   |-- model.build
    |   |   |-- contract.build
    |   |   `-- #<Trailblazer::Operation::Railway::End::Success:0x0000000006c64250>
    |   |-- contract.default.validate
    |   |   |-- #<Trailblazer::Activity::Start:0x0000000006bd7850>
    |   |   |-- contract.default.params_extract
    |   |   |-- contract.default.call
    |   |   `-- #<Trailblazer::Operation::Railway::End::Failure:0x0000000006bd7e40>
    |   `-- #<Trailblazer::Operation::Railway::End::Failure:0x0000000006c3a8b0>
    `-- ready_for_user_create


## 4. Extended Macro API

## 6. Application Workflows and BPMN

Thanks to the refactored circuit engine in Trailblazer 2.1 and the new (`activity`)[https://github.com/trailblazer/trailblazer-activity] gem, any business process can be modeled and implemented now. Since we allow unlimited nesting of activities, it's possible to start modeling from the domain level down to super low-level technical details.

Instead of reinventing, we make use of a subset of the [BPMN standard](http://www.bpmn.org/) that defines and structures workflows in hundred-thousands of applications world-wide. And, don't you worry, you do not have to [read 538 pages](http://www.omg.org/spec/BPMN/2.0/PDF) in order to use Trailblazer's BPMN extension.

<img src="/images/2.1/trailblazer/signup-process.png">

In this diagram, you can see a one-time-password signup process where the user needs to change the initial password after the first login, and then must log in again using those new credentials. Our new visual workflow editor and the `trailblazer-workflow` gem will help to plan, implement and maintain diagrams and logic. Both components are part of the new PRO plan launched in early 2018.

While you can model activities purely in Ruby, our editor will take away the pain of setting up application-wide workflows. And, naturally, all those "boxes" will still be Ruby code, exactly the way it is now, allowing you to focus on the implementation and us doing the control flow for you.

{% callout %}
Once the new PRO version is ready for sign up, we will notify you on our [Facebook page](http://fb.me/trailblazer.to) and link to it here.
{% endcallout %}

## New steps

Create.method(:set_user)

## 10. New Gems
