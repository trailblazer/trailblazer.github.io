---
layout: operation2
title: "Operation Policy"
gems:
  - ["trailblazer", "trailblazer/trailblazer", "2.0"]
---

This document discusses the `Policy` module and [`Policy::Guard`](#guard).

## Guard

A guard is a proc that's executed before `Call`, making it the simplest form of a policy.

If its result is `falsey`, the pipetree won't be further executed and a policy breach is reported in `self["result.policy"]`.

### Guard Example

You can use `::policy` and pass a proc. The proc is executed in operation instance context, allowing you to access the data using `self[]`.

    class Create < Trailblazer::Operation
      include Policy::Guard
      policy -> { self["params"][:id] == 1 && self["user.current"].admin? }
    end

The following will pass.

    result = Create.( { id: 1 }, "user.current" : User.admin )
    result["result.policy"].success? #=> true

Whereas this fails.

    result = Create.( { id: 1 }, "user.current" : nil )
    result["result.policy"].success? #=> false

Learn more about [→ dependency injection](skill.md) to pass params and current user into the operation.

### Guard Callable

It also accepts a `Callable` object. The object's `call` method signature: `call(operation, options)`

    class Update < Create
      class MyGuard
        include Uber::Callable
        def call(operation, options)
          operation["params"][:id] == 1
        end
      end

      include Policy::Guard
      policy MyGuard.new
    end

Note that your guard class has to be marked as `Uber::Callable`.

### Guard Pipetree

Per default, `policy.guard.evaluate` hooks in before `operation.call`.

    Create["pipetree"] #=>
       0 =======================>>operation.new
       1 ================&policy.guard.evaluate
       2 ======================>>operation.call
       3 ===========operation.result===========

It returns `Left` on breach.
