---
layout: operation
title: "Operation Builder"
redirect_from:
  - /gems/operation/builder.html
gems:
  - ["operation", "trailblazer/trailblazer-operation", "1.1", "2.0"]
---

Different contexts like _"admin user"_ vs. _"signed in"_ can be handled in the same code asset along with countless `if`s and `else`s. Or, you can use polymorphism as it is encouraged by Trailblazer.

The easiest way is to use normal inheritance for context-specific operations.


    class Thing::Create < Trailblazer::Operation
      # generic code, contracts, etc.

      class SignedIn < self
        # specific code
      end
    end


A `builds` block allows to let the operation class take care of the instantiation process.

    class Thing::Create < Trailblazer::Operation
      builds -> (params) do
        return SignedIn if params[:current_user]
      end

When running the top-level operation, the builder will instantiate the correct subclass according to the `params` environment.


    op = Thing::Create.(current_user: admin)
    op.class #=> Thing::Create::SignedIn


If the `builds` block doesn't return a constant, the original constant will be used for instantiation. In our example, this would resolve to `Thing::Create`.

## Shared Builders

`builds` blocks are _not inherited_. You can copy them to other classes, though.


    class Thing::Update < Trailblazer::Operation
      self.builder_class = Create.builder_class


Be careful about constant resolving here: the block you copied has to have runtime evaluation of constants.


    class Thing::Create < Trailblazer::Operation
      builds -> (params) do
        return self::SignedIn if # ...
      end


Now, the block can safely be copied to other classes where `SignedIn` will be resolved in the new context.

## Resolver

A resolver allows you to use both the operation model and the policy in the builder.


    class Thing::Create < Trailblazer::Operation
      include Resolver

      policy Thing::Policy, :create?
      model Thing, :create

      builds -> (model, policy, params) do
        return Admin if policy.admin?
        return SignedIn if params[:current_user]
      end


Please note that the `builds` block is run in class context, no operation instance is available, yet. It is important to understand that `Resolver` also changes the way the operation's model is created/found. This, too, happens on the class layer, now.

You have to configure the CRUD module using `::model` so the operation can instantiate the correct model for the builder.

If you want to change the way the model is created, you have to do so on the class level.


    class Thing::Create < Trailblazer::Operation
      include Resolver
      # ..

      def self.model!(params)
        Thing.find_by(slug: params[:slug])
      end


Do _not_ include `CRUD` when using `Resolver`.
