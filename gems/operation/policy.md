---
layout: operation
title: "Operation Policies"
---

# Policy

Trailblazer supports "pundit-style" policy classes. They can be hooked into operations and prevent the operation from running its `#process` method by raising an exception if the policy rule returned `false`.

## Policy Classes

The format of a policy class is heavily inspired by the excellent [Pundit](https://github.com/elabs/pundit) gem. In fact, you can reuse your pundit policies without any code changes in Trailblazer.

A policy file per concept is recommendable.


    class Thing::Policy
      def initialize(user, thing)
        @user, @thing = user, thing
      end

      def create?
        admin?
      end

      def admin?
        @user.admin == true
      end
      # ..
    end


This class would probably be best located at `app/concepts/thing/policy.rb`.

## Operation Policy

Use `::policy` to hook the policy class along with a query action into your operation.


    class Thing::Create < Trailblazer::Operation
      include Trailblazer::Operation::Policy

      policy Thing::Policy, :create?



The policy is evaluated in `#setup!`, raises an exception if `false` and thus suppresses running `#process`. It is a great way to protect your operations from unauthorized users.


    Thing::Create.(current_user: User.find_normal_user, thing: {})


This will raise a `Trailblazer::NotAuthorizedError`.

## Policy Creation

To instantiate the `Thing::Policy` object internally, per default the `params[:current_user]` and the operation's `model` is passed into the constructor. You can override that via `Operation#evaluate_policy`.

## Queries

After `#setup!`, the policy instance is available at any point in your operation code.


    def process(params)
      notify_admin! if policy.admin?


This won't raise an exception.

## Pundit

Pundit policy classes can be used directly in operations.


    class Thing::Create < Trailblazer::Operation
      include Trailblazer::Operation::Policy

      policy ThingPolicy, :create?


As a matter of course, you may call other rule queries on the internal policy object later on.

## Guard

Instead of using policies, you can also use a simple guard.

A guard is like an inline policy that doesn't require you to define a policy class. It is run in `#setup!`, too, like a real policy, but isn't accessable in the operation after that.


    class Thing::Create < Trailblazer::Operation
      include Policy::Guard

      policy do |params|
        params[:current_user].present? # true when present.
      end


If you prefer a separate class as your guard, you can provide a `Callable` object.

    class Thing::Authorization
      include Uber::Callable # marks instance as callable.

      def call(operation, params)
        params[:current_user].present?
      end
    end

Pass the guard *instance* to `Operation::policy` to register it.

    class Thing::Create < Trailblazer::Operation
      include Policy::Guard
      policy Authorization.new


The same works with `Proc`, which will receive `params` only but is executed in operation context (subject to change).

Note that you can't mix `Policy` and guards in one class.

## Resolver

You can use policies in your builders, too. Please refer to the [builder docs](builder.html#resolver) to learn about that.
