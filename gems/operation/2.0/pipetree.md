<!-- ---
layout: operation2
title: Operation Pipetree
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0"]
--- -->

The "flow pipetree" structures and directs the control flow in an operation.

All major steps like building the operation, deserializing incoming parameters, validating, triggering callbacks, etc. are orchestrated via the pipetree. It maximises reusability, helps rewiring or skipping steps and reduces `if`/`else` deciders throughout your code. And it's also pretty awesome to [debug](#debugging)!

The flow pipetree is a mix of the [`Either` monad](http://dry-rb.org/gems/dry-monads/) and ["Railway-oriented programming"](http://zohaib.me/railway-programming-pattern-in-elixir/), but not entirely the same.

[→ Overview](#overview)

## Cheat Sheet

#### Step Example

    Persist  = ->(input, options) { options["model"].save }
    Validate = ->(input, options) { options["params"]["id"].present? }
    Warn     = ->(input, options) { Kernel.warn options["errors.contract"].inspect }

#### Pipetree Operators

| **`::>`** | Add step to **right** track. Result irrelevant, stays on **right**. | `Create.> Persist` |
| **`::&`** | Add step to **right** track. `falsey` result deviates to *left*track. | `Create.& Validate` |
| **`::<`** | Add step to **left** track. Result irrelevant, stays on **left**. | `Create.< Warn` |

#### Operator Options

<!-- | **`delete`** | Create["pipetree"].delete Persist | -->

| **`:replace`** | `Create.> Sequel::Persist, replace: Mysql::Persist`  |
| **`:before`** | `Create.> Deserializer, before: Validate`  |
| **`:after`** | `Create.> EvaluateResult, after: Validate`  |
| **`:append`** | `Create.> ResultLogger, append: true` |
| **`:prepend`** | `Create.> JSONParse, prepend: true` |

## Overview

<div class="row">
  <div class="columns medium-3">
    <img src="/images/diagrams/pipetree.png" alt="Two parallel, vertical tracks, where steps like validation or logger sit either on the right (success) or the left (error). They are executed from top to bottom. Tracks can be changed after a step.">
  </div>
  <div class="columns medium-9">
    <p>
      A pipetree is a an array of <em><strong>functions</strong></em>. Each function in this pipeline is called a <em><strong>step</strong></em>. In the diagram, every box, like <code>Builder</code> or <code>Rollback</code> represents a step. Keep in mind that those steps to the left are just an example!
      </p>
      <p>
        The steps are executed from top to bottom. It starts with <code>Build</code>, then <code>New</code>, then <code>Validation</code> is invoked. Here, it depends on the result of the step. If <code>Validation</code> was successful, it stays on the <em>right</em> track and invoke <code>Persist</code>, and so on. Otherwise, it'll change to the <em>left</em> track and call <code>LogInvalid</code>, then <code>Rollback</code>.
      </p>

      <p>As a last step, ignoring the result of the former step, a wildcard step <code>LogResult</code> is <em>always</em> run.</p>

      <p>This is just one example of a flow pipetree your operation could implement. The possibilities are endless how to plug together flows for complex domain logic.</p>

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

As discussed, the flow within the operation is controlled by a pipetree and this mysterious pipetree is simply invoked in the `Operation::call` method and takes over control of what to run when.

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

## Adding Steps: Right Track

You can add your own or existing steps to the right track using `Operation::>`. The right track is supposed to implement the correct, happy path of the operation, the *right* thing, so to speak.

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

The `SuccessfulPolicyLogger` will, of course, only be executed if its predecessor `Policy::Evaluate` doesn't deviate to the left track. To learn how a step can deviate, we should look at how they're implemented.

## Step Implementation

The simplest step can be a proc in Trailblazer.

    SuccessfulPolicyLogger = ->(input, options) { options["log.policy"] = "Success!" }

It receives `input` which is usually the operation instance, and `options` which is the operation's skill hash. As always, you're free to write to `options`.

The way you *attach* your step to the pipetree decides whether or not its returned value is meaningful.

[TODO: you will also be able to use an operation instance method soon.]

## Changing Tracks

The return value of a step is key to deviate to another track.

If added with the `>` method, the step won't be able to deviate to the left track, regardless of what it returns or does.

An easy way to allow a step to change the track is to attach it using `&`. Now, the step's return value is evaluated, if `falsey`, it will deviate to the left track.

    class Edit < Trailblazer::Operation
      MyValidator = ->(input, options) { options["params"][:id].blank? }
      self.& MyValidator, after: SuccessfulPolicyLogger

Which gives us the pipetree below.

     0 >>New
     1 &Policy::Evaluate
     2 >SuccessfulPolicyLogger
     3 &MyValidator
     4 >>Call

If `MyValidator` returns `false`, the `Call` step will never be reached.

## Adding Steps: Left Track

The left track is meant to handle errors or inconsistencies, such as invalid data, exceptions and so on.

Steps you add here are for error management.

Adding a step to the left track happens with the `<` method.

    class Edit < Trailblazer::Operation
      # ..
      PolicyBreachLogger = ->(input, options) { Notify::Mail.("more breaches!") }
      self.& PolicyBreachLogger, after: Policy::Evaluate

With an amazing pipetree.

     0 >>New
     1 &Policy::Evaluate
     2 <PolicyBreachLogger
     3 >SuccessfulPolicyLogger
     4 &MyValidator
     5 >>Call

Obviously, the `PolicyBreachLogger` step is never called when the operation is on the right track (no pun intended).



--- examples how it's run

## Whatever

If you don't care about the incoming direction, use `%` - we call it the *"whatever"* operator inspired by SQL's wildcard symbol.

    class Edit < Trailblazer::Operation
      # ..
      GenericLogger = ->(input, options) { options["log.message"] = "Policy OK? #{options["policy.evaluator"]["valid"].inspect}" }

      self.% GenericLogger, after: Policy::Evaluate
    end

The `GenericLogger` will be run either way.

## Debugging

At any point, you may inspect the operation's pipetree.

    class Create < Trailblazer::Operation
      def process(params)
        # what's going on here?
        puts self["pipetree"].inspect
      end

Or, from the outside.

    puts Create["pipetree"].inspect
