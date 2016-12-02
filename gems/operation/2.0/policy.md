---
layout: operation2
title: "Operation Policy"
gems:
  - ["trailblazer", "trailblazer/trailblazer", "2.0", "1.1"]
---

This document discusses the `Policy` module, [`Policy::Pundit`](#pundit), and [`Policy::Guard`](#guard).

## Pundit

The `Policy::Pundit` module allows using [Pundit](https://github.com/elabs/pundit)-compatible policy classes in an operation.

A Pundit policy has various rule methods and a special constructor that receives the current user and the current model.

{{  "pundit_test.rb:policy" | tsnippet }}

In pundit policies, it is a convention to have access to those objects at runtime and build rules on top of those.

You can plug this policy into your pipe at any point. However, this must be inserted after the `"model"` skill is available.

{{  "pundit_test.rb:pundit" | tsnippet }}

Note that you don't have to create the model via the `Model` macro - you can use any logic you want. The `Pundit` macro will grab the model from `["model"]`, though.

This policy will only pass when the operation is invoked as follows.

    Create.({}, "user.current" => Module)

Any other call will cause a policy breach and stop the pipe from executing after the `Policy::Pundit` step.

## Pundit: API

Add your polices using the `Policy::Pundit` macro. It accepts the policy class name, and the rule method to call.

{{  "pundit_test.rb:pundit" | tsnippet }}

The step will create the policy instance automatically for you and passes the `"model"` and the `"current_user"` skill into the policies constructor. Just make sure those dependencies are available before the step is executed.

If the policy returns `falsey`, it [deviates to the left track](pipetree.html).

After running the `Pundit` step, its result is readable from the `Result` object.

{{  "pundit_test.rb:pundit-result" | tsnippet }}

Note that the actual policy instance is available via `["result.policy.#{name}"]["policy"]` to be reinvoked with other rules (e.g. in the view layer).

## Pundit: Name

You can add any number of Pundit policies to your pipe. Make sure to use `name:` to name them, though.

{{  "pundit_test.rb:name" | tsnippet }}

The result will be stored in `"result.policy.#{name}"`

{{  "pundit_test.rb:name-call" | tsnippet }}

## Pundit: Dependency Injection

Override a configured policy using dependency injection.

{{  "pundit_test.rb:di-call" | tsnippet }}

You can inject it using `"policy.#{name}.eval"`. It can be any object responding to `call`.

## Guard

A guard is a step that helps you evaluating a condition and writing the result. If the condition was evaluated as `falsey`, the pipe won't be further processed and a policy breach is reported in `Result["result.policy.default"]`.

{{  "guard_test.rb:proc" | tsnippet }}

The only way to make the above operation invoke the second step `:process` is as follows.

    result = Create.({ pass: true })
    result["x"] #=> true

Any other input will result in an abortion of the pipe after the guard.

    result = Create.()
    result["x"] #=> nil
    result["result.policy.default"].success? #=> false

Learn more about [→ dependency injection](skill.md) to pass params and current user into the operation.

## Guard: API

The `Policy::Guard` macro helps you inserting your guard logic. If not defined, it will be evaluated where you insert it. → [Class-level guards](#guard-class-level)

{{  "guard_test.rb:proc" | tsnippet : "pipeonly" }}

The `Skill` options object is passed into the guard and allows you to read and inspect data like `params` or `current_user`.

## Guard: Callable

As always, the guard can also be a `Callable`-marked object.

{{  "guard_test.rb:callable" | tsnippet }}

Insert the object instance via the `Policy::Guard` macro.

{{  "guard_test.rb:callable-op" | tsnippet : "pipe-only" }}


## Guard: Class-level

You can also place any kind of guard before the operation instantiation using `before:`.

{{  "guard_test.rb:class-level" | tsnippet : "pipe--only" }}

This is helpful to clear out breaches quickly.

## Guard: Name

The guard name defaults to `default` and can be set via `name:`. This allows having multiple guards.

{{  "guard_test.rb:name" | tsnippet }}

The result will sit in `result.policy.#{name}`.

{{  "guard_test.rb:name-result" | tsnippet }}

## Guard: Dependency Injection

Instead of using the configured guard, you can inject any callable object that returns a `Result` object. Do so by overriding the `policy.#{name}.eval` path when calling the operation.

{{  "guard_test.rb:di-call" | tsnippet }}

An easy way to let Trailblazer build a compatible object for you is using `Guard.build`.

This is helpful to override a certain policy for testing, or to invoke it with special rights, e.g. for an admin.
