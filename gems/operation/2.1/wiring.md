---
layout: operation-2-1
title: "Wiring API"
---

Let's learn how to create the circuit graph for operations. This is called the _Wiring API_.

## Doormat Step

Very often, you want to have one or multiple "last steps" in an operation, for instance to generically log errors or success messages. We call this a _doormat step_.

### Doormat Step: Before

The most elementary way to achieve this is using the `:before` option.


Note that `:before` is a DSL option and not related to the Graph API. It will move up steps using this option before `:log_success!`, as if you had actually called it before this step.

<img src="/images/graph/doormat-before.png">

### Doormat Step: Before with Inheritance

The same can be achieved using inheritance. In a generic base operation, you can define concept- or application-wide steps.


Concrete steps are added in the subclass.


The resulting `Create`'s activity is identical to the [last example](#doormat-step-before).
