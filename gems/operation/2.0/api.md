---
layout: operation2
title: Operation API
gems:
  - ["trailblazer", "trailblazer/trailblazer", "2.0", "1.1"]
---


This document describes Trailblazer's operation API.

{% callout %}
  The generic implementation can be found in the [trailblazer-operation gem](https://github.com/trailblazer/trailblazer-operation). This gem only provides the pipe and dependency handling.

  Higher-level abstractions, such as form object or policy integration is implemented in the [trailblazer gem](https://github.com/trailblazer/trailblazer).
{% endcallout %}


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


<!-- ## Flow Control: Procedural

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

Also, error handling needs to be done manually at every step. This is the price you pay for procedural, statically nested code. -->

## Flow Control

The operation's sole purpose is to define the pipe with its steps that are executed when the operation [is run](#invocation). While traversing the pipe, each step orchestrates all necessary stakeholders like policies, contracts, models and callbacks.

The flow of an operation is defined by a two-tracked pipeline.

<section>
  <div class="row">
    <div class="column medium-4">
      <img src="/images/diagrams/overview-flow-animated.gif">
    </div>

    <div class="column medium-8">
      {{  "operation_test.rb:op-api" | tsnippet }}
    </div>
  </div>

</section>

Per default, the right track will be run from top to bottom. If an error occurs, it will deviate to the left track and continue executing error handler steps on this track.

The flow pipetree is a mix of the [`Either` monad](http://dry-rb.org/gems/dry-monads/) and ["Railway-oriented programming"](http://zohaib.me/railway-programming-pattern-in-elixir/), but not entirely the same.

The following high-level API is available.

* `step` adds a step to right track. If its return value is `falsey`, the pipe deviates to left track. Can be called with macros, which will run their own insertion logic.
* `success` always add step to the right. The return value is ignored.
* `failure` always add step to the left for error handling. The return value is ignored.

### Flow Control: Outcome

If the operation ends on the right track, the [result object](#result-object) will return true on `success?`.

    result = Song::Create({ title: "The Feeling Is Alright" }, "current_user": current_user)
    result.success? #=> true

Otherwise, when the run ends on the left track, `failure?` will return true.

    result = Song::Create({ })
    result.success? #=> false
    result.failure? #=> true

Incredible, we know.

### Flow Control: Step

The `step` method adds your step to the **right** track. The return value decides about track deviation.

    class Create < Trailblazer::Operation
      step :model!

      def model!(options, **)
        options["model"] = Song.new # return value evals to true.
      end
    end

The **return value of `model!` is evaluated**.

Since the above example will always return something "truesy", the pipe will stay on the right track after `model!`.


However, if the step returns `falsey`, the pipe will change to the left track.

    class Update < Trailblazer::Operation
      step :model!

      def model!(options, params:, **)
        options["model"] = Song.find_by(params[:id]) # might return false!
      end
    end

In the above example, it deviates to left should the respective model **not** be found.

When adding [step macros](step-macros) with `step`, the behavior changes a bit. Macros can command `step` to internally use other operators to attach their step(s).

    class Create < Trailblazer::Operation
      step Model( Song, :find_by )
    end

However, most macro will internally use `step`, too. Note that some macros, such as `Contract::Validate` might add several steps in a row.

### Flow Control: Success

If you don't care about the result, and want to stay on the right track, use `success`.

    class Update < Trailblazer::Operation
      success :model!

      def model!(options, params:, **)
        options["model"] = Song.find_by(params[:id]) # return value ignored!
      end
    end

Here, if `model!` returns `false` or `nil`, the pipe stays on right track.

### Flow Control: Failure

Error handlers on the left track can be added with `failure`.

    class Create < Trailblazer::Operation
      consider :model!
      failure  :error!

      # ...

      def error!(options, params:, **)
        options["result.model"] = "Something went wrong with ID #{params[:id]}!"
      end
    end

Note that you can add as many error handlers as you want, at any position in the pipe. They will be executed in that order, just as it works on the right track.

<div class="callout">
  We will introduce a <em>fail-early</em> option where the left track is stopped after a specific error handler marked with that option.
</div>

## Step Implementation

A step can be added via `step`, `success` and `failure`. It can be implemented as an instance method.

    class Create < Trailblazer::Operation
      step :model!

      def model!(options, **)
        options["model"] = Song.new
      end
    end

Note that you can use modules to share steps across operations.

Or as a proc.

    class Create < Trailblazer::Operation
      step ->(options, **) { options["model"] = Song.new }
    end

Or, for more reusability, as a `Callable`.

    class MyModel
      extend Uber::Callable
      def self.call(options, **)
        options["model"] = Song.new
      end
    end

Simply pass the class (or stateless instance) to the step operator.

    class Create < Trailblazer::Operation
      step MyModel
    end

## Step Arguments

Each step receives the [context object](#dependencies) as a positional argument. All *runtime* data is also passed as keyword arguments to the step.

Whether method, proc or callable object, use the positional options to write, and make use of kw args wherever possible.

    class Create < Trailblazer::Operation
      step ->(options, params:, current_user:, **) {  }
    end

The first `options` is the positional argument and ideal to write new data onto the context. This is the **mutable** part which transports mutable state from one step to the next.

After that, only extract the parameters you need (such as `params:`). Any unspecified keyword arguments can be ignoreed using `**`.



## Step Macros

Trailblazer provides predefined steps to for all kinds of business logic.

* [Contract](contract.html) implements contracts, validation and persisting verified data using the model layer.

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

In an operation, there is only one way to manage dependencies and state: the `options` object (sometimes also called *skills* hash or context object) is what gives access to class, runtime and injected runtime data.

State can be added on the class layer.

{{  "operation_test.rb:dep-op" | tsnippet : "dep-pipe"}}

Unsurprisingly, this is also readable on the class layer.

{{  "operation_test.rb:dep-op-class" | tsnippet }}

This mechanism is used by all DSL methods such as `contract` and by almost all step macros (e.g. `Contract::Build`) to save and access class-wide data.

Class data is also readable at runtime in steps.

{{  "operation_test.rb:dep-op" | tsnippet }}

In steps, you can set runtime data (e.g. `my.model`).

After running the operation, this `options` object turns into the [result object](#result-object).

{{  "operation_test.rb:dep-op-res" | tsnippet }}

## Dependency Injection

Both class data as well as runtime data [described above](#dependencies) can be overridden using dependency injection.

{{  "operation_test.rb:dep-di" | tsnippet }}

Note that injected dependencies need to be in the second argument to `Operation::call`.

<div class="callout">
Since all step macros, i.e. <code>Policy::Pundit</code> or <code>Contract::Validate</code> use the same mechanism, you can override hard-coded dependencies such as policies or contracts from the outside at runtime.
</div>

Be careful, though, with DI: It couples your operation to the caller and should be properly unit-tested or further encapsulated in e.g. [`Endpoint`](endpoint.html).

### Dependency Injection: Auto_inject

The operation supports Dry.RB's [auto_inject](http://dry-rb.org/gems/dry-auto_inject/).

    # this happens somewhere in your Dry system.
    my_container = Dry::Container.new
    my_container.register("repository.song", User::Repository)

    require "trailblazer/operation/auto_inject"
    AutoInject = Trailblazer::Operation::AutoInject(my_container)

    class Song::Create < Trailblazer::Operation
      include AutoInject["repository.song"]

      step :model!

      def model!(options, params:, **)
        options["model"] =
          options["repository.song"].find_or_create( params[:id] )
      end
    end

Including the `AutoInject` module will make sure that the specified dependencies are injected (using [dependency injection](#dependency-injection)) into the [operation's context](#dependencies) at instantiation time.

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
