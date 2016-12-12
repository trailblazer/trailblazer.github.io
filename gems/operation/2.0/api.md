---
layout: operation2
title: Operation API
gems:
  - ["trailblazer", "trailblazer/trailblazer", "2.0"]
---





The generic logic can be found in the trailblazer-operation gem. Higher-level abstractions, such as form object or policy integration is implemented in the trailblazer gem.

* Overview
* Papi::Operation extend Contract::DSL


<hr>


An operation is a Ruby object that embraces all logic needed to implement one function, or *use case*, of your application. It does so by orchestrating various objects like form objects for validations, models for persistence or callbacks to implement post-processing logic.

While you could do all that in a nested, procedural way, the Trailblazer operation uses a pipetree to structure the control flow and error handling.

    class Create < Trailblazer::Operation
    end

## Invocation

An operation is designed like a function and it can only be invoked in one way: via `Operation::call`.

    Song::Create.call( name: "Roxanne" )

Ruby allows a shorthand for this which is commonly used throughout Trailblazer.

    Song::Create.( name: "Roxanne" )

The absence of a method name here is per design: this object does only one thing, and hence *what it does is reflected in the class name*.

Running an operation will always return its result object. It is up to you to interpret the content of it or push data onto the result object during the operation's cycle.

    result = Create.call( name: "Roxanne" )

    result["model"] #=> #<Song name: "Roxanne">

[→ Result object](#result-object)


## Flow Control: Procedural

There's nothing wrong with implementing your operation's logic in a procedural, nested stack of method calls, the way Trailblazer 1.x worked. The behavior here was orchestrated from within the `process` method.

    class Create < Trailblazer::Operation
      self.> Process

      def process(params)
        model = Song.new

        if validate(params)
          unless contract.save
            handle_persistence_errors!
          end
          after_save!
        else
          handle_errors!
        end
      end
    end

Even though this might seem to be more "readable" at first glance, it is impossible to extend without breaking the code up into smaller methods that are getting called in a predefined order - sacrificing its aforementioned readability.

Also, error handling needs to be done manually at every step. This is the price you pay for procedural, statically nested code.

## Flow Control: Pipetree

You can also use TRB2's new *pipetree*. Instead of nesting code statically, the code gets added sequentially to a pipeline in a functional style. This pipeline is processed top-to-bottom when the operation is run.

    class Create < Trailblazer::Operation
      self.> :model!
      self.> :validate!
      self.> :persist!

      def model!(options)
        Song.new
      end
      # ...
    end

Logic can be added using the `Operation::>` operator. The logic you add is called *step* and can be [an instance method, a callable object or a proc](api.html).

Under normal conditions, those steps are simply processed in the specified order. Imagine that as a track of tasks. The track we just created, with steps being applied when things go right, is called the *right track*.

The operation also has a *left track* for error handling. Steps on the right side can deviate to the left track and remaining code on the right track will be skipped.

    class Create < Trailblazer::Operation
      self.> :model!
      self.> :validate!
      self.< :validate_error!
      self.> :persist!
      self.< :persist_error!
      # ...
    end

Adding steps to the left track happens via the `Operation::<` operator.

## Pipetree Visualization

Visualizing the pipetree you just created makes is very obvious what is going to happen when you run this operation. Note that you can render any operation's pipetree anywhere in your code for a better understanding.

    Create["pipetree"].inspect

     0 =======================>>operation.new
     1 ===============================>:model
     2 ============================>:validate
     3 <:validate_error!=====================
     4 ============================>:persist!
     5 <:persist_error!======================

Once deviated to the left track, the pipetree processing will skip any steps remaining on the right track. For example, should `validate!` deviate, the `persist!` step is never executed (unless you want that).

Now, how does a step make the pipetree change tracks, e.g. when there's a validation error?

## Track Deviation

The easiest way for changing tracks is letting the pipetree interpret the return value of a step. This is accomplished with the `Operation::&` operator.

    class Create < Trailblazer::Operation
      self.> :model!
      self.& :validate!
      self.< :validate_error!
      # ...
    end

Should the `validate!` step return a falsey value, the pipetree will change tracks to the left.

    class Create < Trailblazer::Operation
      # ...
      def validate!(*)
        self["params"].has_key?(:title) # returns true of false.
      end
    end

Check the [API docs for pipetree](pipetree.html) to learn more about tracks.

## Step Macros

Trailblazer provides predefined steps to for all kinds of business logic.

* [Contract](contract.html) implements contracts, validation and persisting verified data using the model layer.

## Orchestration

## Result Object

Calling an operation returns a `Result` object. Sometimes we also called it a *context object* as it's available throughout the call. It is passed from step to step, and the steps can read and write to it.

Consider the following operation.

{{  "operation_test.rb:step-options" | tsnippet }}

All three steps add data to the `options` object. That data can be used in the following steps.

{{  "operation_test.rb:step-val" | tsnippet }}

It is a convention to use a `"namespaced.key"` on the result object. This will help you structuring and managing the data. It's clever to namespace your data with something like `my.`.

<div class="callout">
  In future versions of Trailblazer, the <em>Hash Explore API™</em> will allow to search for fragments or namespace paths on the result object. That's why it's a good idea to follow our namespacing convention.
</div>

Some steps, such as [`Contract`](contract.html) or [`Policy`](policy.html) will add nested result objects under their own keys, like `["result.policy"]`. It's a convention to add binary `Result` objects to the "global" result under the `["result.XXX"]` key.

### Result: API

After running the operation, the result object can be used for reading state.

{{  "operation_test.rb:step-res" | tsnippet }}

You can ask about the outcome of the operation via `success?` and `failure?`.

{{  "operation_test.rb:step-binary" | tsnippet }}

Please note that the result object is also used to transport externally [injected dependencies and class dependencies.](#dependencies).

{{  "operation_test.rb:step-dep" | tsnippet }}

Use `Result#inspect` to test a number of dependencies.

{{  "operation_test.rb:step-inspect" | tsnippet }}

### Result: Interpretation

The result object represents the interface between the operation's inner happenings and the outer world, or, in other words, between implementation and user.

It's up to you how you interpret all this available data. The binary state will help you, but arbitrary state can be transported. For a generic handling in HTTP context (Rails controllers or Rack routes), see [→ `Endpoint`](endpoint.html).

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

## Wrap

Steps can be wrapped by an embracing step. This is necessary when defining a set of steps to be contained in a database transaction or a database lock.

{{  "wrap_test.rb:sequel-transaction" | tsnippet }}

The `Wrap` macro helps you to define the wrapping code (such as a `Sequel.transaction` call) and allows you defining the wrapped steps.

{{  "wrap_test.rb:sequel-transaction" | tsnippet : "wrap-only" }}

As always, you can have steps before and after `Wrap` in the pipe. The block passed to `Wrap` allows defining the nested steps (you need to use `{...}` instead of `do...end`).

The proc passed to `Wrap` will be called when the pipe is executed, and receives `block`. `block.call` will execute the nested pipe.

All nested steps will simply be executed as if they were on the "top-level" pipe, but within the wrapper code. Steps may deviate to the left track, and so on.

The return value of the wrap block is crucial: If it returns falsey, the pipe will deviate to left after `Wrap`.

You may have any number of `Wrap` nesting.

### Wrap: Callable

For reusable wrappers, you can also use a `Callable` object.

{{  "wrap_test.rb:callable-t" | tsnippet  }}

This can then be passed to `Wrap`, making the pipe extremely readable.

{{  "wrap_test.rb:sequel-transaction-callable" | tsnippet : "wrap-onlyy" }}

## Rescue

While you can write your own `begin/rescue/end` mechanics using [`Wrap`](#wrap), Trailblazer offers you the `Rescue` macro to catch and handle exceptions that might occur while running the pipe.

{{  "rescue_test.rb:simple" | tsnippet  }}

Any exception raised during a step in the `Rescue` block will stop the nested pipe from being executed, and continue after the block on the left track.

You can specify what exceptions to catch and an optional handler that is called when an exception is encountered.

{{  "rescue_test.rb:name" | tsnippet  }}

Alternatively, you can use a  `Callable` object for `:handler`.

## Full Example

The  `Nested`, `Wrap` and `Rescue` macros can also be nested, allowing an easily extendable business workflow with error handling along the way.

{{  "rescue_test.rb:example" | tsnippet : "ex" }}
