---
layout: operation2
title: Operation Pipetree
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0"]
---

The "flow pipetree" structures the control flow in an operation.

All major steps like building the operation, deserializing incoming parameters, validating, triggering callbacks, etc. are orchestrated via the pipetree. It maximises reusability, helps rewiring or skipping steps and reduces `if`/`else` deciders troughout your code. And it's also pretty awesome to [debug](#debugging)!

The flow pipetree is a mix of the [`Either` monad](http://dry-rb.org/gems/dry-monads/) and ["Railway-oriented programming"](http://zohaib.me/railway-programming-pattern-in-elixir/), but not entirely the same.

## Overview

<div class="row">
  <div class="columns medium-3">
    <img src="/images/diagrams/pipetree.png">
  </div>
  <div class="columns medium-9">
    <p>
      A pipetree is a an array of <em><strong>functions</strong></em>. Each function in this pipeline is called a <em><strong>step</strong></em>. In the diagram, every box, like <code>Builder</code> or <code>Rollback</code> represents a step. Keep in mind that those steps to the left are just an example!
      </p>
      <p>
        The steps are executed from top to bottom. It starts with <code>Build</code>, then <code>New</code>, then <code>Validation</code> is invoked. Here, it depends on the result of the step. If <code>Validation</code> was successful, it stays on the <em>right</em> track and invoke <code>Persist</code>, and so on. Otherwise, it'll change to the <em>left</em> track and call <code>LogInvalid</code>, then <code>Rollback</code>.
      </p>

      <p>As a last step, ignoring the result of the former step, a wildcart step <code>LogResult</code> is <em>always</em> run.</p>

      <p>This is just one example of a flow pipetree your operation could implement. The possibilities how to plug together flows that implement complex domain logic are endless.</p>

      <p>In these sections we will discuss the following questions.

      <ul>
        <li>How do we define a pipetree and add steps?</li>
        <li>Where can I set what track my step is on?</li>
        <li>How can a step emit different results to change the track?</li>
        <li>Where do we transport state and additional results?</li>
      </ul>
      </p>
  </div>
</div>


## Initial Pipetree

The flow within the operation is controlled by a pipetree and this mysterious pipetree is simply invoked in the `Operation::call` method and takes over control of what to run when.

An empty operation has a very comprehensible pipetree.

    class Edit < Trailblazer::Operation
    end

    puts Edit["pipetree"].inspect(style: :rows)

     1 >>New
     2 >>Call

There are only two steps: In `New`, the operation instance is created, in `Call` the operation's `#call` method is invoked, which will in turn run your `process` method.

Usually, when including Trailblazer operation modules, those modules will hook themselves into the pipetree in the desired position.

    class Edit < Trailblazer::Operation
      include Builder
      include Policy::Guard
      include Contract
      include Model
    end

    puts Edit["pipetree"].inspect(style: :rows)

     0 >>Build
     1 >>New
     2 >Model::Build
     3 &Policy::Evaluate
     5 >>Call

Here, the `Builder` is run as the very first step since it decides the actual class to instantiate, `Policy::Evaluate` is run after the model's logic as it needs the model, and so on.

## Control Flow: Outgoing

Each step must either return a `Left` object when something went wrong, or a `Right` when things are, well, al<em>right</em>. This is a common pattern we copied from the `Either` monad as found in many functional languages.

For example, the `Policy::Evaluate` step could be implemented as follows.

    Policy::Evaluate = ->(input, options) { options["user.current"].admin? ? Pipetree::Right : Pipetree::Left }

This step would make the further execution of the pipetree stop if the current user wasn't an admin, by emitting a `Left` object.

Every step in the pipetree will return such a `Left` or `Right` result.

## Control Flow: Incoming

Now, returning the "direction" is one thing. However, when hooking steps into the pipetree, you can also specify the *incoming direction*. In other words, you can say if your step wants to be executed for an incoming `Left` (for example an error handler) or a `Right`.

Use `>` to add a step that is expecting a `Right`, a successful, direction.

    class Edit < Trailblazer::Operation
      include Policy

      SuccessfulPolicyLogger = ->(input, options) { options["log.policy"] = "Success!" }

      self.> SuccessfulPolicyLogger, after: Policy::Evaluate
    end

Resulting in the following pipetree.

    puts Edit["pipetree"].inspect(style: :rows)

     0 >>New
     1 &Policy::Evaluate
     2 >SuccessfulPolicyLogger
     3 >>Call

The `SuccessfulPolicyLogger` will only be executed if its predecessor in the pipe returns a `Right`.

--- examples how it's run

If you need a `Left`-expecting step, such as a policy breach logger, use `<`.

    class Edit < Trailblazer::Operation
      # ..
      PolicyBreachLogger = ->(input, options) { options["log.policy"] = "FAIL!" }

      self.> SuccessfulPolicyLogger, after: Policy::Evaluate
      self.< PolicyBreachLogger, after: Policy::Evaluate
    end

And the pipetree.

    puts Edit["pipetree"].inspect(style: :rows)

     0 >>New
     1 &Policy::Evaluate
     2 <PolicyBreachLogger
     3 >SuccessfulPolicyLogger
     4 >>Call

It all depends on the direction result of the former pipetree. If it's `Left` with an error, the `PolicyBreachLogger` is involved, if there's a `Right` travelling down the pipetree, it's `SuccessfulPolicyLogger`'s turn.

## Whatever

If you don't care about the incoming direction, use `%` - we call it the *"whatever"* operator inspired by SQL's wildcard symbol.

    class Edit < Trailblazer::Operation
      # ..
      GenericLogger = ->(input, options) { options["log.message"] = "Policy OK? #{options["policy.evaluator"]["valid"].inspect}" }

      self.% GenericLogger, after: Policy::Evaluate
    end

The `GenericLogger` will be run either way.

## Extending

## &
## >
## |
## %

## Debugging
