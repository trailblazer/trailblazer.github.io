---
layout: operation2
title: Operation API
gems:
  - ["trailblazer", "trailblazer/trailblazer", "2.0", "1.1"]
---


This document describes Trailblazer's `Operation` API.

{% callout %}
  The generic implementation can be found in the [trailblazer-operation gem](https://github.com/trailblazer/trailblazer-operation). This gem only provides the pipe and dependency handling.

  Higher-level abstractions, such as form object or policy integration, are implemented in the [trailblazer gem](https://github.com/trailblazer/trailblazer).
{% endcallout %}


## Invocation

An operation is designed like a function and it can only be invoked in one way: via `Operation::call`.

    Song::Create.call( name: "Roxanne" )

Ruby allows a shorthand for this which is commonly used throughout Trailblazer.

    Song::Create.( name: "Roxanne" )

The absence of a method name here is per design: this object does only one thing, and hence *what it does is reflected in the class name*.

Running an operation will always return its [→ result object](#result-object). It is up to you to interpret the content of it or push data onto the result object during the operation's cycle.

    result = Create.call( name: "Roxanne" )

    result["model"] #=> #<Song name: "Roxanne">

### Invocation: Dependencies

Dependencies other than the params input, such as a current user, are passed via the second argument.

{{  "operation_test.rb:invocation-dep-call" | tsnippet }}

External dependencies will be accessible via `options` in every step.

{{  "operation_test.rb:invocation-dep" | tsnippet }}

They are also readable in the result.

{{  "operation_test.rb:invocation-dep-res" | tsnippet }}

Keep in mind that there is **no global state** in Trailblazer, anything you need in the operation has to be injected via the second `call` argument. This also applies to tests.

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

The flow pipetree is a mix of the [`Either` monad](http://dry-rb.org/gems/dry-monads/) and ["Railway-oriented programming"](http://fsharpforfunandprofit.com/rop/), but not entirely the same.

The following high-level API is available.

* `step` adds a step to the right track. If its return value is `falsey`, the pipe deviates to the left track. Can be called with macros, which will run their own insertion logic.
* `success` always add step to the right. The return value is ignored.
* `failure` always add step to the left for error handling. The return value is ignored.

### Flow Control: Outcome

If the operation ends on the right track, the [result object](#result-object) will return true on `success?`.

    result = Song::Create.({ title: "The Feeling Is Alright" }, "current_user": current_user)
    result.success? #=> true

Otherwise, when the run ends on the left track, `failure?` will return true.

    result = Song::Create.({ })
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

Since the above example will always return something "truthy", the pipe will stay on the right track after `model!`.


However, if the step returns `falsey`, the pipe will change to the left track.

    class Update < Trailblazer::Operation
      step :model!

      def model!(options, params:, **)
        options["model"] = Song.find_by(params[:id]) # might return false!
      end
    end

In the above example, it deviates to the left should the respective model **not** be found.

When adding [step macros](#step-macros) with `step`, the behavior changes a bit. Macros can command `step` to internally use other operators to attach their step(s).

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
      step    :model!
      failure :error!

      # ...

      def error!(options, params:, **)
        options["result.model"] = "Something went wrong with ID #{params[:id]}!"
      end
    end

Just as in right-tracked steps, you may add failure information to the [result object](#result-object) that you want to communicate to the caller.

    def error!(options, params:, **)
      options["result.model"] = "Something went wrong with ID #{params[:id]}!"
    end

Note that you can add as many error handlers as you want, at any position in the pipe. They will be executed in that order, just as it works on the right track.

### Flow Control: Fail Fast Option

If you don't want left track steps to be executed after a specific step, use the `:fail_fast` option.

{{  "fast_test.rb:ffopt" | tsnippet }}

This will **not** execute any `failure` steps after `abort!`.

{{  "fast_test.rb:ffopt-res" | tsnippet }}

Note that this option in combination with `failure` will always fail fast once its reached, regardless of the step's return value.

`:fail_fast` also works with `step`.

{{  "fast_test.rb:ffopt-step" | tsnippet }}

Here, if `step` returns a falsey value, the rest of the pipe is skipped, returning a failed result. Again, this will **not** execute any `failure` steps after `:empty_id?`.

{{  "fast_test.rb:ffopt-step-res" | tsnippet }}

<!-- ### Flow Control: Pass Fast Option



The `:pass_fast` option also works with `success` and will always skip the remaining pipe returning a successful result, should the `success` step be reached. -->

### Flow Control: Fail Fast


Instead of [hardcoding the flow behavior](#flow-control-fail-fast-option) you can have a dynamic skipping of left track steps based on some condition. This works with the `fail_fast!` method.

{{  "fast_test.rb:ffmeth" | tsnippet }}

This will **not** execute any steps on either track, but will result in a failed operation.

{{  "fast_test.rb:ffmeth-res" | tsnippet }}

Note that you have to **return** `Railway.fail_fast!` from the track. You can use this signal from any step, e.g. `step` or `failure`.

<!-- ### Flow Control: Pass Fast

Sometimes it might be necessary to skip the rest of the pipe and return a successful result. Use `pass_fast!` for this.

{{  "fast_test.rb:pfmeth" | tsnippet }}

After **returning** the signal from a step, the remaining steps will be skipped.

{{  "fast_test.rb:pfmeth-res" | tsnippet }}

Note that this works on both right and left track. -->

## Step Implementation

A step can be added via `step`, `success` and `failure`. It can be implemented as an instance method.

    class Create < Trailblazer::Operation
      step :model!

      def model!(options, **)
        options["model"] = Song.new
      end
    end

Note that you can use modules to share steps across operations.

### Step Implementation: Lambda

Or as a proc.

    class Create < Trailblazer::Operation
      step ->(options, **) { options["model"] = Song.new }
    end

### Step Implementation: Callable

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

Each step receives the [context object](#dependencies) as a positional argument. All *runtime* data is also passed as keyword arguments to the step. Whether method, proc or callable object, use the positional options to write, and make use of kw args wherever possible.

For example, you can use kw args with a proc.

    class Create < Trailblazer::Operation
      step ->(options, params:, current_user:, **) {  }
    end

Or with an instance method.

    class Create < Trailblazer::Operation
      step :setup!

      def setup!(options, params:, current_user:, **)
        # ...
      end
    end

The first `options` is the positional argument and ideal to write new data onto the context. This is the **mutable** part which transports mutable state from one step to the next.

After that, only extract the parameters you need (such as `params:`). Any unspecified keyword arguments can be ignored using `**`.

{% callout %}

Keyword arguments work fine in Ruby 2.1 and >=2.2.3. They are broken in Ruby 2.2.2 and have a to-be-confirmed unexpected behavior in 2.0.

{% endcallout %}


## Result Object

Calling an operation returns a `Result` object. Sometimes we also called it a *context object* as it's available throughout the call. It is passed from step to step, and the steps can read and write to it.

Consider the following operation.

{{  "operation_test.rb:step-options" | tsnippet }}

All three steps add data to the `options` object. That data can be used in the following steps.

{{  "operation_test.rb:step-val" | tsnippet }}

It is a convention to use a `"namespaced.key"` on the result object. This will help you structure and manage the data. It's clever to namespace your data with something like `my.`.

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
    my_container.register("repository.song", Song::Repository)

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

## Inheritance

To share code and pipe, use class inheritance.

{% callout %}
Try to avoid inheritance and use [composition](#nested) instead.
{% endcallout %}

You can inherit from any kind of operation.

{{  "operation_test.rb:inh-new" | tsnippet }}

In this example, the `New` class will have a pipe as follows.

{{  "operation_test.rb:inh-new-pipe" | tsnippet }}

In addition to Ruby's normal class inheritance semantics, the operation will also copy the pipe. You may then add further steps to the subclass.

{{  "operation_test.rb:inh-create" | tsnippet }}

This results in the following pipe.

{{  "operation_test.rb:inh-create-pipe" | tsnippet }}

Inheritance is great to eliminate redundancy. Pipes and step code can easily be shared amongst groups of operations.

Be weary, though, that you are tightly coupling flow and implementation to each other. Once again, try to use Trailblazer's [compositional](#nested) semantics over inheritance.

### Inheritance: Override

When using inheritance, use `:override` to replace existing steps in  subclasses.

Consider the following base operation.

{{  "operation_test.rb:override-app" | tsnippet }}

Subclasses can now override predefined steps.

{{  "operation_test.rb:override-new" | tsnippet }}

The pipe flow will remain the same.

{{  "operation_test.rb:override-pipe" | tsnippet }}

Refrain from using the `:override` option if you want to add steps.

## Options

When adding steps using `step`, `failure` and `success`, you may name steps explicitly or specify the position.

### Options: Name

{% row %}
  ~~~6
A step macro will name itself.

{{  "operation_test.rb:name-auto" | tsnippet }}
  ~~~6
You can find out the name by inspecting the pipe.

{{  "operation_test.rb:name-auto-pipe" | tsnippet }}
{% endrow %}

For every kind of step, whether it's a macro or a custom step, use `:name` to specify a name.

{{  "operation_test.rb:name-manu" | tsnippet }}

When inspecting the pipe, you will see your names.

{{  "operation_test.rb:name-manu-pipe" | tsnippet }}

Assign manual names to steps when using macros multiple times, or when planning to alter the pipe in subclasses.

### Options: Position

Whenever inserting a step, you may provide the position in the pipe using `:before` or `:after`.

{{  "operation_test.rb:pos-before" | tsnippet }}

This will insert the custom step before the model builder.

{{  "operation_test.rb:pos-before-pipe" | tsnippet }}

{% callout %}
Naturally, `:after` will insert the step after an existing one.
{% endcallout %}

### Options: Inheritance

The position options are extremely helpful with inheritance.

{{  "operation_test.rb:pos-inh" | tsnippet }}

It allows inserting new steps without repeating the existing pipe.

{{  "operation_test.rb:pos-inh-pipe" | tsnippet }}

### Options: Replace

Replace existing (or inherited) steps using `:replace`.

{{  "operation_test.rb:replace-inh" | tsnippet  }}

The existing step will be discarded with the newly provided one.

{{  "operation_test.rb:replace-inh-pipe" | tsnippet }}

### Options: Delete

## Step Macros

Trailblazer provides predefined steps to for all kinds of business logic.

<!-- * [Builder](#builder) allows writing and using polymorphic factories to create different operations based on different input. -->
* [Contract](contract.html) implements contracts, validation and persisting verified data using the model layer.
* [`Nested`](#nested), [`Wrap`](#wrap) and [`Rescue`](#rescue) are step containers that help with transactional features for a group of steps per operation.
* All [`Policy`-related](policy.html) macros help with authentication and making sure users only execute what they're supposed to.
* The [`Model`](#model) macro can create and find models based on input.

## Macro API

Implementing your own macros helps to create reusable code.

It's advised to put macro code into namespaces to not pollute the global namespace.

{{  "macro_test.rb:simple" | tsnippet }}

The macro itself is a function. Per convention, the name is capitalized. You can specify any set of arguments (e.g. using kw args), and it returns a 2-element array with the actual step to be inserted into the pipe and default options.

Note that in the macro, the code design is up to you. You can delegate to other functions, objects, etc.

The macro step receives `(input, options)` where `input` is usually the operation instance and `options` is the context object passed from step to step. It's your macro's job to read and write to `options`. It is not advisable to interact with the operation instance.

Operations can then use your macro the way you've done it with our Trailblazer macros.

{{  "macro_test.rb:simple-op" | tsnippet }}

When looking at the operation's pipe, you can see how, in our example, the default options provide a convenient step name.

{{  "macro_test.rb:simple-pipe" | tsnippet }}

It is not advised to test macros in isolation. Note that it *is* possible by simply calling your macro in a test case. However, macros should be tested via an operation unit test to make sure the wiring is correct.

{% callout %}
In future versions (TRB 2.0.2+) we will have public APIs for creating nested pipes, providing temporary arguments to steps and allowing injectable options.
{% endcallout %}

## Model

An operation can automatically find or create a model for you depending on the input, with the `Model` macro.

{{  "model_test.rb:op" | tsnippet }}

After this step, there is a fresh model instance under `options["model"]` that can be used in all following steps.

{{  "model_test.rb:create" | tsnippet }}

Internally, `Model` macro will simply invoke `Song.new` to populate `"model"`.

### Model: Find_by

You can also find models using `:find_by`. This is helpful for `Update` or `Delete` operations.

{{  "model_test.rb:update" | tsnippet }}

The `Model` macro will invoke the following code for you.

    options["model"] = Song.find_by( params[:id] )

This will assign `["model"]` for you by invoking `find_by`.

{{  "model_test.rb:update-ok" | tsnippet }}

If `Song.find_by` returns `nil`, this will deviate to the left track, skipping the rest of the operation.

{{  "model_test.rb:update-fail" | tsnippet }}

Note that you may also use `:find`. This is not recommended, though, since it raises an exception, which is not the preferred way of flow control in Trailblazer.

## Nested

It is possible to nest operations, as in running an operation in another. This is the common practice for "presenting" operations and "altering" operations, such as `Edit` and `Update`.

{{  "nested_test.rb:edit" | tsnippet }}

Note how `Edit` only defines the model builder (via `:find`) and builds the contract.

Running `Edit` will allow you to grab the model and contract, for presentation and rendering the form.

{{  "nested_test.rb:edit-call" | tsnippet }}

This operation could now be leveraged in `Update`.

{{  "nested_test.rb:update" | tsnippet }}

The `Nested` macro helps you invoking an operation at any point in the pipe.

### Nested: Data

The nested operation (`Edit`) will, per default, only receive runtime data from the composing operation (`Update`). Mutable data is not available to protect the nested operation from unsolicited input.

After running the nested `Edit` operation its runtime data (e.g. `"model"`) is available in the `Update` operation.

{{  "nested_test.rb:update-call" | tsnippet }}

Should the nested operation fail, for instance because its model couldn't be found, then the outer pipe will also jump to the left track.

### Nested: Callable

If you need to pick the nested operation dynamically at runtime, use a callable object instead.

{{  "nested_test.rb:callable" | tsnippet }}

The object's `call` method has the exact same interface as any other step.

{{  "nested_test.rb:callable-builder" | tsnippet }}

Note that `Nested` also works with `:instance_method` and lambdas.

{{  "nested_test.rb:method" | tsnippet }}

### Nested: Input

Per default, only the runtime data will be passed into the nested operation. You can use `:input` to change the data getting passed on.

The following operation multiplies two factors.

{{  "nested_test.rb:input-multiply" | tsnippet }}

It is `Nested` in another operation.

{{  "nested_test.rb:input-pi" | tsnippet }}

The examplary composing operation uses both runtime and mutable data. Its invocation could look as follows.

{{  "nested_test.rb:input-result" | tsnippet }}


The `:input` option for `Nested` allows to specify what options will go into the nested operation. It passes `mutable_data` and `runtime_data` to the option for your convenience.

While the runtime data normally gets passed on to nested operations automatically, mutual data won't. `:input` has to compile all data being passed on to the nested operation and return that hash.

Use a `Callable` to share mapping code.

{{  "nested_test.rb:input-callable" | tsnippet }}

It will improve readability.

{{  "nested_test.rb:input-callable-op" | tsnippet }}

### Nested: Output

After running a nested operation, its mutable data gets copied into the `options` of the composing operation.

Use `:output` to change that, should you need only specific values.

{{  "nested_test.rb:output" | tsnippet }}

This works with lambdas, `:method` and `Callable`.

## Wrap

Steps can be wrapped by an embracing step. This is necessary when defining a set of steps to be contained in a database transaction or a database lock.

{{  "wrap_test.rb:sequel-transaction" | tsnippet }}

The `Wrap` macro helps you to define the wrapping code (such as a `Sequel.transaction` call) and allows you to define the wrapped steps. (Because of the precedence works in Ruby, you need to use `{...}` instead of `do...end`.)

{{  "wrap_test.rb:sequel-transaction" | tsnippet : "wrap-only" }}

As always, you can have steps before and after `Wrap` in the pipe.

The proc passed to `Wrap` will be called when the pipe is executed, and receives `block`. `block.call` will execute the nested pipe.

You may have any amount of `Wrap` nesting.

### Wrap: Return Value

All nested steps will simply be executed as if they were on the "top-level" pipe, but within the wrapper code. Steps may deviate to the left track, and so on.

However, the last signal of the wrapped pipe is not simply passed on to the "outer" pipe. The return value of the actual `Wrap` block is crucial: If it returns falsey, the pipe will deviate to left after `Wrap`.

    step Wrap ->(*, &block) { Sequel.transaction do block.call end; false } {

In the above example, regardless of `Sequel.transaction`'s return value, the outer pipe will deviate to the left track as the `Wrap`'s return value is always `false`.

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
