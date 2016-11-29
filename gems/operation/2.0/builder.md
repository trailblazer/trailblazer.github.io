---
layout: operation2
title: "Operation Builder"
gems:
  - ["trailblazer", "trailblazer/trailblazer", "2.0", "1.1"]
---

Different application contexts like _"admin user"_ vs. _"signed in"_ can be handled in the same code asset along with countless `if`s and `else`s. Or, you can use polymorphism as it is encouraged by Trailblazer.

Here, different contexts are handled by different classes. Those classes may inherit from each other, but don't have to.

    class Create < Trailblazer::Operation
      # generic code, contracts, etc.

      class SignedIn < self
        # specific code
      end

      class Admin < self
        # ..
      end
    end

The idea is to never instantiate internal classes  directly (`SignedIn` and `Admin`), but only call the "top-level" operation (`Create`) and hide polymorphic behavior from the user.

## Definition: Proc

The polymorphic logic sits in a *builder* that you can push onto the pipetree of the "top-level" operation.

    class Create < Trailblazer::Operation
      my_builder = ->(options) do
        return Admin    if options["user.current"].admin?
        return SignedIn if options["user.current"]
        Create
      end

      self.| Builder[ my_builder ]
    end

Note that with this technique, `my_builder` is simply a proc that checks conditions and returns the respective class constant.

## Evaluation

When calling the "top-level" operation, the builder will instantiate the correct class according to the deciders you wrote in the builder proc.

    Create.({ id: 1 }, "user.current: admin") #=> runs Create::Admin

The `Builder` step inserts itself *before* the `operation.new` step.

    Create["pipetree"].inspect
     0 ========================>>builder.call
     1 =======================>>operation.new
     ...

The step **is not inherited** to subclasses.

    Create::Admin["pipetree"].inspect
     0 =======================>>operation.new
     ...

## Definition: Builds

Instead of using a proc, you can use Trailblazer's `builds` DSL.


    class Create < Trailblazer::Operation
      include Builder # you *have* to include this!

      builds -> (options) do
        return Admin    if options["user.current"].admin?
        return SignedIn if options["user.current"]
        # no need to return Create here as a fallback.
      end

Note that with the `builds` method, you don't have to provide a fallback constant: when none of the conditions are met, the top-level constant is used. In the example, an anonymous user would be facing the `Create` method.

## Shared Builders

## Builder Objects
