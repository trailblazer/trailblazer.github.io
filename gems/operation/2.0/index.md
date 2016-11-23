---
layout: operation2
title: Operation Overview
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0", "1.1"]
---

The operation's goal is simple: Remove all business logic from the controller and model and instead provide a separate object for it. While doing so, this logic is streamlined into the following steps.



The generic logic can be found in the trailblazer-operation gem. Higher-level abstractions, such as form object or policy integration is implemented in the trailblazer gem.

* Overview
* Flow Control
* Papi::Operation extend Contract::DSL


<hr>


An operation is a Ruby object that embraces all logic needed to implement one function, or *use case*, of your application. It does so by orchestrating various objects like form objects for validations, models for persistence or callbacks to implement post-processing logic.

While you could do all that in a nested, procedural way, the Trailblazer operation uses a pipetree to structure the control flow and error handling.

    class Create < Trailblazer::Operation
    end

## Invocation

An operation is designed like a function and it can only be invoked in one way: via `Operation::call`.

    Create.call( name: "Roxanne" )

Ruby allows a shorthand for this which is commonly used throughout Trailblazer.

    Create.( name: "Roxanne" )

The absence of a method name here is per design: this object does only one thing, has only one public method, and hence **what is does is reflected in the class name**. Likewise, you never instantiate operations manually - this contradicts its functional concept and prevents you from randomly running methods on it in the wrong order.

Running an operation will always return a result object. It is up to you to interpret the content of it or push data onto the result object during the operation's cycle.

    result = Create.call( name: "Roxanne" )

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

## Orchestration

## Result Object

result.contract [.errors, .success?, failure?]
result.policy [, .success?, failure?]
