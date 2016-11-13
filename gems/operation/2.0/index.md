---
layout: operation2
title: Operation Overview
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0"]
---

The operation's goal is simple: Remove all business logic from the controller and model and instead provide a separate object for it. While doing so, this logic is streamlined into the following steps.



The generic logic can be found in the trailblazer-operation gem. Higher-level abstractions, such as form object or policy integration is implemented in the trailblazer gem.

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


## Adding Functionality: Procedural

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

## Adding Functionality: Functional



## Orchestration

## Result Object

result.contract [.errors, .success?, failure?]
result.policy [, .success?, failure?]
