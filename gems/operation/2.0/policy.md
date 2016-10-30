---
layout: operation2
title: "Operation Policy"
---

## Guard

A guard is a proc that's executed before `Call`, making it the simplest form of a policy.

If its result is `falsey`, the pipetree won't be further executed and a policy breach is reported in `self["policy.result"]`.

### Guard Example

You can use `::policy` and pass a proc. The proc is executed in operation instance context, allowing you to access the data using `self[]`.

    class Create < Trailblazer::Operation
      include Policy::Guard
      policy -> { self["params"][:id] == 1 && self["user.current"].admin? }
    end

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

Per default, `Policy::Evaluate` hooks in before `Call`.

    Create["pipetree"] #=>
     0 >>New
     1 &Policy::Evaluate
     2 >>Call

It returns `Left` on breach.
