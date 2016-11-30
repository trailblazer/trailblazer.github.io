---
layout: operation2
title: "Operation Policy"
gems:
  - ["trailblazer", "trailblazer/trailblazer", "2.0", "1.1"]
---

This document discusses the `Policy` module and [`Policy::Guard`](#guard).

## Guard: Overview

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

### Guard: Callable

As always, the guard can also be a `Callable`-marked object.

{{  "guard_test.rb:callable" | tsnippet }}

Insert the object instance via the `Policy::Guard` macro.

{{  "guard_test.rb:callable-op" | tsnippet : "pipe-only" }}


### Guard: Class-level

You can also place any kind of guard before the operation instantiation using `before:`.

{{  "guard_test.rb:class-level" | tsnippet : "pipe--only" }}

This is helpful to clear out breaches quickly.

### Guard: Name

The guard name defaults to `default` and can be set via `name:`. This allows having multiple guards.

{{  "guard_test.rb:name" | tsnippet }}

The result will sit in `result.policy.#{name}`.

{{  "guard_test.rb:name-result" | tsnippet }}

### Guard: Dependency Injection

Instead of using the configured guard, you can inject any callable object that returns a `Result` object. Do so by overriding the `policy.#{name}.eval` path when calling the operation.

{{  "guard_test.rb:di-call" | tsnippet }}

An easy way to let Trailblazer build a compatible object for you is using `Guard.build`.

This is helpful to override a certain policy for testing, or to invoke it with special rights, e.g. for an admin.
