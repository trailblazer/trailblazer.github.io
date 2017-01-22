---
layout: operation2
title: 02- Trailblazer Basics
gems:
  - ["trailblazer", "trailblazer/trailblazer", "2.0"]
---

{% row %}
  ~~~8
  Being able to [populate the pipe](01-getting-started-with-operation.html), or railway, of an operation and handle errors, we now dive into the Trailblazer gem and the abstractions it gives us: persistence handling, validations, policies, and all that.

  An importance architectural decision here is that most abstractions are implemented in completely separate gems. Those gems don't even know they're being used in a Trailblazer operation.

  Instead of shipping with tons of code to implement forms or policies, Trailblazer provides glue code that mediate between the operation (flow control and specific customization) and the additional abstractions (validations, persistence, etc.).

  This happens in *macros*, and we will learn a lot about those in the following session.
  ~~~4
  <img src="/images/diagrams/operation-2017-small.png" class="diagram left">
{% endrow %}

##  The Challenge

Coming back to the controller from chapter 01, I want you to quickly get an idea of what we're trying to achieve now.

    class BlogPostsController < RubyOnTrails::Controller
      before_filter :authorize_user!

      def create
        post = BlogPost.new
        post.update_attributes(params[:blog_post])
        if post.save
          notify_current_user!
        else
          render
        end
      end
    end

This is a classic Rails controller setup. Check if the user is authorized, create a model, validate the incoming parameters, if successful, save and notify the current user about it.

We're going to rebuild this with a Trailblazer operation. We're also going to do that without any infrastructure framework, such as Rails or Hanami. This is content for the following guides.

{% callout %}
Code for this session is [here](https://github.com/trailblazer/guides/tree/operation-02).
{% endcallout %}

## WAT

Trailblazer is suitable both for greenfield projects as well as refactoring massive and messy legacy projects. The mechanics are always the same.

* Extract domain logic from controller, models and half-baked service objects and rearrange them embraced by an operation.
* Free the model: Validations go to forms (or contracts as we also call them).
* Callback code is triggered from the operation, not the model or controller.
* Authorization happens in policies orchestrated by the operation, not in random places in controller, model, or view.

You will see, it's actually quite simple to let the operation control the flow and other stakeholder objects implement the specifics.

## Gemfile

Have a look at the `Gemfile`.

    gem "trailblazer"
    gem "activerecord"
    gem "sqlite3"
    gem "rspec"
    gem "dry-validation"

The `trailblazer` gem brings the operation, the Reform gem for contracts, and some code for the macros we're going to discuss.

We already discussed `rspec`'s role. Mentioning the `activerecord` gem is important, since we need a persistence layer. Please be advised, though, that Trailblazer is database-agnostic: you can use ROM, `Hanami::Model`, Sequel, or whatever else you feel like.

For validations, we refrain from using `ActiveModel::Validation` in this example and use the excellent [dry-validation gem](dry-rb.org/gems/dry-validation/). Reform allows using `dry-v` out-of-the-box. In case you want to/have to use ActiveModel's validations, no problem, Reform does that, too.

## Model

Since we're going to create a new blog post record, it's a good idea to add a model class. I put that in `app/models/blog_post.rb`.

{{ "blog_post.rb:model:../trailblazer-guides/app/models:operation-02" | tsnippet }}

This is an empty model that skips all the features of ActiveRecord's that should've never been added, and leverages what ActiveRecord is amazing at: persistence.

{% callout %}
We also [have a `User` model](https://github.com/trailblazer/guides/blob/operation-02/app/models/user.rb), which is a simple Struct that allows us to set a `signed_in?` flag. In later chapters we will use a "real" user model and an authentication gem.
{% endcallout %}

## Procedural Approach

To implement the above controller action in an operation, you could simply throw the code into a single step, ignoring all the nice mechanics and error handling that comes with the pipe, but making it "understandable" to a new developer.

For illustration purposes, this `Create` operation goes to `app/concepts/blog_post/operation/create.rb`.

{{ "create.rb:procedural:../trailblazer-guides/app/concepts/blog_post/operation:operation-02" | tsnippet }}

The operation now orchestrates model, validation and the notification "callback" that used to sit in the controller. Note that no HTTP-related code, like redirects or rendering results, is found here anymore. That's a step forward in our quest to separating concerns!

### Procedural Approach: Test

A quick test makes sure that our authorization kicks in and an anonymous user leads to a failing operation, and no model is persisted.

{{ "spec/concepts/blog_post/operation/create_spec.rb:procedural:../trailblazer-guides/:operation-02" | tsnippet }}

We also test the [successful case here](https://github.com/trailblazer/guides/blob/operation-02/spec/concepts/blog_post/operation/create_spec.rb#L21). It's obvious that our current implementation is not great, for example, we don't have access to the created model without manual work, which we don't favor, do we?

## Dependencies

Even though this operation is far from ideal, it demonstrates a very important concept in Trailblazer. Have you noticed how we pass in and access the current user?

There is no global state in Trailblazer, everything you need in the operation needs to go in via `call`.

The first argument is usually the framework's `params` has [as discussed here](01-getting-started-with-operation.html#options). The second argument can be any hash specifying the dependencies needed in the operation, such as the current user.

{{ "spec/concepts/blog_post/operation/create_spec.rb:dependencies:../trailblazer-guides/:operation-02" | tsnippet }}

By passing the current user with a string key, you will be able to access it via `options` in all steps. And, of course, you as the attentive reader still remember that you can use keyword arguments to grab that current user (or whatever else you need from the options) in a local variable.

{{ "create.rb:args:../trailblazer-guides/app/concepts/blog_post/operation:operation-02" | tsnippet }}

Here's what to remember about dependencies in a snapshot.

* Every dependency needs to go in via `call`, whether that is in a controller, a test, or a background job.
* Use [*required* kw args](https://robots.thoughtbot.com/ruby-2-keyword-arguments#required-keyword-arguments) wherever you can, as they will automatically raise an exception should the required keyword be absent.

## Exposing Values

Before breaking up this monolith into small, flexible steps, it's a good time to learn how we can communicate values to the caller via the result object. You remember, in our specs, in order to grab the model for specing, we had to use `BlogPost.last` - which yields potential for bugs.

Instead, we can simply write values to the `options` object. Those will be accessable to all following steps, as we'll see in a few seconds.

{{ "create.rb:procedural-set:../trailblazer-guides/app/concepts/blog_post/operation:operation-02" | tsnippet : "hide" }}

Writing to `options` will also allow to read that very value in the result object, allowing us to change the specs slightly.

{{ "spec/concepts/blog_post/operation/create_spec.rb:set-spec:../trailblazer-guides/:operation-02" | tsnippet }}

We can now test against `result["model"]` and retrieve the actual processed model instance.

## Manual Steps

While all this works fine, we actually don't need an operation for this procedural piece of code. We could put that in one of the "service objects" that spook through many Ruby applications out there.

Splitting up the procedural logic into steps will give us a better code structure and automatic error handling. Going further, using Trailblazer macros instead of manual steps, we will maximise stability and get helpful statuses in the result object.

{{ "create.rb:firststeps:../trailblazer-guides/app/concepts/blog_post/operation:operation-02" | tsnippet  }}

Four steps now implement the exact same that we did in one procedural step. As you can see, error handling and `if`s disappeared because if a step returns a falsey value, the remaining steps will be skipped. I also advise you to take a minute and check out how we use different kw args per step - this is such a helpful feature, you should use it and understand it.

The specs we wrote still pass, so we're good to go to the next step.

## Policy

One big advantage of Trailblazer's `Policy` macro over our home-made `authorize!` step is: It will add its outcome to the result object, making it extremely simple to track what went wrong should things go wrong.

The other benefit of using this macro is: You don't have to use [the primitive *guard* implementation](/gems/operation/2.0/policy.html#guard), but use your existing [Pundit-style policies](/gems/operation/2.0/policy.html#pundit) to intercept unauthorized users.

{{ "create.rb:policy:../trailblazer-guides/app/concepts/blog_post/operation:operation-02" | tsnippet  }}

Check line 2. Guards are a good way to quickly implement access control, but I advise you to invest some time in a separated policy implementation such as [pundit]((/gems/operation/2.0/policy.html#pundit)).
