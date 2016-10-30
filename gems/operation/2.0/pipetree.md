---
layout: operation
title: Operation Pipetree
---

The "flow pipetree" is concept for designing the control flow within an operation while maximising reusability, encapsulation and rewiring. Its control semantics help you reducing `if`/`else` deciders and it's also pretty awesome to debug!

The flow pipetree is a mix of the [`Either` monad](http://dry-rb.org/gems/dry-monads/) and ["Railway-oriented programming"](http://zohaib.me/railway-programming-pattern-in-elixir/), but not entirely the same.

## Operation Pipetree

The flow within the operation is controlled by a pipetree and this mysterious pipetree is simply invoked in the `Operation::call` method and takes over control of what to run when.

A pipetree is a pipeline, or an array of functions.

--> Example of Builder, Contract, Policy


step
>>Build,>>New,>>Call,>>New,>>Call
Edit["pipetree"]

## Default Functions

## Extending

## &
## >
## |
## %
