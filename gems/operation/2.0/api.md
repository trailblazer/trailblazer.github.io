---
layout: operation2
title: Operation API
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0"]
---

#call

Override call to return an arbitrary result. Per default, the result object (the operation) is returned.

## Result Object

In Trailblazer 2.0, calling an operation returns a `Result` object. Sometimes we also called it a *context object* as it's available throughout the call. This is basically only a hash with some helpful added behavior. It is created before the operation and then passed through the entire flow to the very end.

    result = Create.(..)
    result.success? #=> true
    result.failure? #=> false

You can ask about its *binary state* via `success?` and `failure?`.

### Result: Adding State

Besides the result's binarity, you can add any state or data to it to inform the outer world about the happenings on the inside.

Adding data works by simply using `Operation#[]=` at any point in the flow.

    class Create < Trailblazer::Operation
      def process(params)
        self["my.message"] = "Process was run!" # write to result object.
      end
    end

You can then read via `Operation#[]` in other steps of your flow.

    class Create < Trailblazer::Operation
      # ..
      self.> :after_process

      def after_process
        puts self["my.message"] # read from result object.
      end

Of course, this message is also available after running the operation.

    result = Create.(..)
    result["my.message"] #=> "Process was run!"

### Result: Naming

Every piece in the operation adds its own data to the result object, so it's clever to namespace your data with something like `my.`.

Some steps, such as [`Contract`](contract.html) or [`Policy`](policy.html) will add nested result objects under their own keys, like `["result.policy"]`. It's a convention to add binary `Result` objects to the "global" result under the `["result.XXX"]` key.

Please note that the result object is also used to transport externally [injected dependencies and class dependencies.](#dependencies).

### Result: Interpretation

The result object represents the interface between the operation's inner happenings and the outer world, or, in other worlds, between implementation and user.

It's up to you how you interpret all this available data. The binary state will help you, but arbitrary state can be transported. For a generic handling in HTTP context (Rails controllers or Rack routes), see [→ `Endpoint`](endpoint.html).

inspect("attr")

## Dependencies

## Nested

It is possible to nest operations, as in running an operation in another. This is the common practice for "presenting" operations and "altering" operations, such as `Edit` and `Update`.

{{  "nested_test.rb:edit" | tsnippet }}

Note how `Edit` only defines the model builder (via `:find`) and builds the contract.

Running `Edit` will allow you to grab the model and contract, for presentation and rendering the form.

{{  "nested_test.rb:edit-call" | tsnippet }}

This operation could now be leveraged in `Update`.

{{  "nested_test.rb:update" | tsnippet }}

The `Nested` macro helps you invoking an operation at any point in the pipe.

After running the nested `Edit` operation its runtime data (e.g. `"model"`) is available in the `Update` operation.

{{  "nested_test.rb:update-call" | tsnippet }}

Should the nested operation fail, for instance because its model couldn't be found, then the outer pipe will also jump to the left track.
