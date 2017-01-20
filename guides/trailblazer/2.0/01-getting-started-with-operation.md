---
layout: operation2
title: 01- Getting Started With Operation
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0"]
---

The *Operation* is the central concept of the Trailblazer architecture. It is a simple service object that embraces and orchestrates all the business logic necessary to accomplish a certain task, such as creating a blog post, or updating a user.

In order to do so, the operation provides you an API to structure your business code into *steps*. Its API is heavily inspired by the "Railsway-oriented programming" pattern that combines structuring linear code, and error handling - but more on that later.

Don't let yourself trick into the thinking the operation is a "god object", as it's been called by critics. The opposite is the case: the operation knows what to orchestrates and when, however, it has zero knowledge about the *how* since the implementation of the steps are hidden from it.

{% callout %}
You can find the code for this page [here](https://github.com/trailblazer/guides/tree/operation-01).
{% endcallout %}

## Gemfile

In the [repository](https://github.com/trailblazer/guides/tree/operation-01) for this page, you will find a very slim `Gemfile`.

    gem "trailblazer-operation"
    gem "rspec"

The `trailblazer-operation` gem gives you the `Trailblazer::Operation` class and its Railway semantics. Nothing more. It does *not* have any other dependencies, which is why it is a great idea to start learning Trailblazer with a setup as simple as possible.

We will explore the operation's behavior using specs. This is my personal favorite way to play with new ideas or gems. If you prefer Minitest, you may do so, Trailblazer is not coupled to any specific test framework.

## Our first Operation

When implementing a blog website, it's probably quite handy to empower a user to write and create a blog post.

In most web frameworks like Rails, you'd start with a `PostsController` and an action `#create` that receives and processes a post form.

    class PostsController < RubyOnTrails::Controller
      def create
        post = Post.new
        post.update_attributes(params[:post])
        if post.save
          notify_current_user!
        else
          render
        end
      end
    end

In Trailblazer, this is identical, only that the entire *business code* to create a post is embraced by an operation. Leaving routing and rendering responses up to the controller, the operation solely focuses on domain logic. The nice thing here is that we can start coding without any web framework or routing, and even without thinking about HTTP - a deeply relaxing thought.

An operation is simply a Ruby object that can be run anywhere.

In `app/post/operation/create.rb` I add an empty class.

{{ "create.rb:op:../trailblazer-guides/app/post/operation:operation-01" | tsnippet }}

`Create` is derived from `Trailblazer::Operation`. Do note that we're inheriting [a few dozens lines](https://github.com/trailblazer/trailblazer-operation/blob/master/lib/trailblazer/operation.rb) of code here, only.

### Naming

The actual `Create` operation is put into the `Post` namespace. This is very common in Trailblazer: we leverage Ruby namespaces. This results in the beautiful operation class named `Post::Create`, a very expressive class name, don't you think?

Before adding any logic, let's run this very operation via a spec in `spec/post/operation/create_spec.rb`.

{{ "create_spec.rb:fresh:../trailblazer-guides/spec/post/operation" | tsnippet }}

In an empty test case, we invoke (or *call*) our yet unspoiled operation.

### Call

That's right, there's only one way to run an operation, and that's the "`call` style". Confused? Here's how to spell that alternatively.

    Post::Create.call()

This behavior is pure Ruby and was introduced in Ruby 1.9, if I remember correctly. While this might look bizarre to you at first glance, there's a profound reasoning behind this decision.

<!-- instantiation? -->
An operation conceptually is a *function*, it does only one thing and doesn't need more than one public method. Since the operation's name reflect what it does, you don't need a method name. This is why in Trailblazer you will have many `call`able objects instead of one object with many methods.

{% callout %}
You will soon learn how this greatly improves your architecture since the functional approach minimizes internal state and the [associated mess it might create](https://apotonick.wordpress.com/2014/05/22/rails-misapprehensions-single-responsibility-principle/).
{% endcallout %}

While our spec works, or at least no exception is raised, this is not very impressive. Let's see what it actually returns.

{{ "create_spec.rb:puts:../trailblazer-guides/spec/post/operation" | tsnippet }}

Calling an operation always gives you a *result object*. It is used to transport state, communicate internals to the outer world, and to indicate whether or not this operation was successful. Why don't we make sure it didn't break?

{{ "create_spec.rb:success:../trailblazer-guides/spec/post/operation" | tsnippet }}

The `Result#success?` method and its friend `failure?` are here to test that, from the caller perspective.

## Baby Steps

It might be a good idea to actually add some logic to our operation. While we could simply add a big method with lots of code in a nested procedural style, Trailblazer encourages you to structure your code into a *pipeline*, where steps in the pipe implement parts of the domain code.

{{ "create.rb:step:../trailblazer-guides/app/post/operation:operation-01" | tsnippet }}

You can add steps with the [`step` method](http://trailblazer.to/gems/operation/2.0/api.html#flow-control-step). It allows to implement steps using methods, [lambdas](http://trailblazer.to/gems/operation/2.0/api.html#step-implementation-lambda) and [callable objects](http://trailblazer.to/gems/operation/2.0/api.html#step-implementation-callable). For simplicity, let's go with instance methods for now. The `hello_world!` method sits in the operation as an instance method. It receives some arguments that we'll learn about later. In the body, it's up to us to implement that step.

{% callout %}
Suffixing step methods with a bang (e.g. `model!`) is purely style, it has no semantic.
{% endcallout %}

Running this operation will hopefully output something.

{{ "create_spec.rb:step:../trailblazer-guides/spec/post/operation" | tsnippet }}

We can see a greeting on our command line. But, hang on, what's that? The operation didn't finish successful, our test just broke... after working with TRB for 2 minutes!

## Step: Return Value Matters

The operation fails because the return value of a `step` matters! If a step returns `nil` or `false` (aka. *falsey*), the operation's result will be marked as failed, and the following steps won't be executed,

Since `puts` will always return `nil` (and [no one knows why](http://stackoverflow.com/questions/14741329/why-are-all-my-puts-returning-nil)), we manually have to return a trusy value to make the next step be invoked.

{{ "create.rb:return-value:../trailblazer-guides/app/post/operation:operation-01" | tsnippet }}

It looks odd, and we should've simply used `p`, but it will probably make the spec pass.

{{ "create_spec.rb:return-value:../trailblazer-guides/spec/post/operation" | tsnippet }}

Yes, our tests are green again.

## Multiple Steps

Having fixed the first problem, we should extend our operation with another step.

Multiple steps will be executed in the order you added them.

{{ "create.rb:steps:../trailblazer-guides/app/post/operation:operation-01" | tsnippet }}

The operation will now greet and enquire about your wellbeing.

{{ "create_spec.rb:steps:../trailblazer-guides/spec/post/operation" | tsnippet }}

How friendly! I wish more operations could be like you.

## Breaking Things

We're all curious about what will happen when the first step returns `false` instead of `true`, aren't we?

{{ "create.rb:breaking:../trailblazer-guides/app/post/operation:operation-01" | tsnippet }}

The `hello_world!` step now returns `nil`, making the operation's flow "fail". What does that mean?

{{ "create_spec.rb:breaking:../trailblazer-guides/spec/post/operation" | tsnippet }}

The step following the "broken" step now doesn't get executed, anymore. Furthermore, the operation's result is a failure. Awesome, we broke things, and that's exactly what we wanted!

## Basic Flow Control









Apparently, `step` and `success` allow you to define some kind of flow. If one `step` returns a falsey value, all other remaining steps are skipped. This is great for error handling as it takes away nested `if`s and `else`s in your code and formalizes them in a declarative pipe.

## Railway

The operation's pipe doesn't only allow you to skip steps, but also to handle errors. And this is where it makes sense to introduce the mental model for Trailblazer, the [*Railway* paradigm from functional programming](http://fsharpforfunandprofit.com/rop/).

We also call the pipe a *railway* because it has different tracks.

