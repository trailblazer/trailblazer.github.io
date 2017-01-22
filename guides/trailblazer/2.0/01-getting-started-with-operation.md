---
layout: operation2
title: 01- Getting Started With Operation
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0"]
---
{% row %}
  ~~~6
  {{ "create.rb:failure:../trailblazer-guides/app/post/operation:operation-01" | tsnippet : "impl" }}

  ~~~6
  The *Operation* is the central concept of the Trailblazer architecture. It is a simple service object that embraces and orchestrates all the business logic necessary to accomplish a certain task, such as creating a blog post, or updating a user.

  Or, as in this guide, leading a small conversation and fixing the other person's mood.
{% endrow %}

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

## Naming

The actual `Create` operation is put into the `BlogPost` namespace. This is very common in Trailblazer: we leverage Ruby namespaces. This results in the beautiful operation class named `BlogPost::Create`, a very expressive class name, don't you think?

Before adding any logic, let's run this very operation via a spec in `spec/post/operation/create_spec.rb`.

{{ "create_spec.rb:fresh:../trailblazer-guides/spec/post/operation" | tsnippet }}

In an empty test case, we invoke (or *call*) our yet unspoiled operation.

## Call

That's right, there's only one way to run an operation, and that's the "`call` style". Confused? Here's how to spell that alternatively.

    BlogPost::Create.call()

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

Since `puts` will always return `nil` (and [no one knows why](http://stackoverflow.com/questions/14741329/why-are-all-my-puts-returning-nil)), we manually have to return a truthy value to make the next step be invoked.

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

{% row %}
  ~~~4
  <img src="/images/diagrams/guide-op-railway1.gif" width="140">
  ~~~8
  Apparently, `step` allows us to define some kind of flow. If one `step` returns a falsey value, all other remaining steps are skipped.

  We will soon see that this is great for error handling, as it takes away nested `if`s and `else`s in your code and formalizes them in a declarative pipe.

  Check out the diagram on the left hand. This is how Trailblazer structures the flow, but more on that [later](#error-handling).
{% endrow %}

## Success!

We don't really test anything in the first two steps, and returning `true` looks weird. Luckily, Trailblazer gives us the `success` method to define a step that always passes. Or, in other words: the return value is ignored and assumed it was `true`.

{{ "create.rb:success:../trailblazer-guides/app/post/operation:operation-01" | tsnippet }}

This looks better, and, more important: another developer looking at this operation will instantly understand the first two steps do always pass.

We now understand how to implement an operation with successive steps, and how to communicate that to the caller with the result object. Next, we should explore how to *read* input, test it and maybe have alternative flows depending on a certain value.

## Handling Input

Since our operation seems to be interested in our health, and actually asks us about it, we should pass the answer into it. With operations, there's only one way to pass data into it, and that's, of course, in `call`.

{{ "create_spec.rb:input:../trailblazer-guides/spec/post/operation" | tsnippet }}

We now have to implement a check that tests our answer, and if it happens to be `"yes"`, wish a good day, and make the outcome successful.


{{ "create.rb:input:../trailblazer-guides/app/post/operation:operation-01" | tsnippet }}

The middle step `how_are_you?` is now added with `step`, making its return value matter. That means, if the `params[:happy] == "yes"` check is true, the next step is going to be executed. And, surprisingly, given the above test case with the respective input, this works.

Of course, we now have to test the opposite scenario, too. What if we're unhappy?

{{ "create_spec.rb:input-false:../trailblazer-guides/spec/post/operation" | tsnippet }}

Then, only the first two steps are executed, the third is skipped. Also, the result's state is "failed".

## Options

Before we dive into error handling, let's quickly discuss how steps access the input.

Remember how we called the operation?

{{ "create_spec.rb:input-call:../trailblazer-guides/spec/post/operation" | tsnippet }}

The first argument passed to `call` will be available via `options["params"]` in every step.

    def how_are_you?(options, *)
      # ...
      options["params"] #=> { happy: "yes" }
    end

It's a bit tedious to always go through `options`, so Trailblazer harnesses *keyword arguments* a lot to simplify accessing data. Keyword arguments are an incredibly cool feature introduced in Ruby 2.0.

So, instead of going through `options`, you can tell Ruby to extract the params into the local `params` variable.

    def how_are_you?(options, params:, **)
      # ...
      params #=> { happy: "yes" }
    end

This is highly recommended as it simplifies the method body, and as a nice side effect, Ruby will complain if params are not available. You may also set a default value for the keyword argument, but let's talk about this another time.

Note the double-splat `**` at the end of the argument list. It means "I know there are more keyword arguments coming in, but I'm not interested right now". It ignores other kw args that [Trailblazer passes into the step](/gems/operation/2.0/api.html#step-arguments).

## Error Handling

The operation's pipe doesn't only allow you to skip steps, but also to handle errors. And this is where it makes sense to introduce the mental model for Trailblazer, the [*Railway* paradigm from functional programming](http://fsharpforfunandprofit.com/rop/).

{% row %}
  ~~~4
  <img src="/images/diagrams/guide-op-railway1.gif">
  ~~~8
  Steps added with `success` will go on the *right track*. Once that step is executed, a following step will be invoked regardless of the preceding result. This is why `hello_world!` and then `how_are_you?` are always called, in that very order.

  When adding with `step`, it will also go on the right track. However, now the step's result is crucial. This is where you create a switch that might deviate to the *left track*.

  Handling an eventual error in `how_are_you?` now becomes nothing more than adding a step on the left track, after the erroring one. This works with `failure`.

  And keep in mind, there can be any number of steps on each track. You can even jump back and fourth.
{% endrow %}

{% callout %}
We also call the pipe a *railway* because it has different tracks and mentally follows a train/track scenario.
{% endcallout %}


## Failure

In order to handle the case that `how_are_you?` returns a negative mood, we need to add an error handler on the left track. As already discussed, this happens via `failure`.

{{ "create.rb:failure:../trailblazer-guides/app/post/operation:operation-01" | tsnippet }}

The pipe, or railway, created now represents the one we've just seen in the diagram. Due to the way `failure` works, it will only be executed if `how_are_you?` fails.

## Writing Output

In the new `tell_joke!` step, you can see that we write to `options`. That's how you communicate state changes to the outer world. For example, that could be an error message interpreted by the operation user.

Note that writing applies to any kind of state, right or left track! To keep this example brief, we only write in this one step, though.

{{ "create_spec.rb:failure:../trailblazer-guides/spec/post/operation" | tsnippet }}

When passing in a negative (or false) value for `:happy`, the second step `how_are_you?` will deviate to the left track. This is why we can test the result's state for `failure?` and why the `options[:joke]` value is set.

It's up to the operation caller to decide whether or not they find this joke hilarious.

## Interpretation

Speaking about decisions: in Trailblazer, it is not the operation's job or scope to decide what will happen given that the railway took path A, B or even C. The operation may write as many flags, objects, booleans, whatever you need to the `options` hash and thus expose state and internal decisions.

Nevertheless, the interpretation of the result is the sole business of the caller. *What* will happen with this result is up to the controller, the background job, or wherever else you use the operation.

To make sure that the operation provides those values and to have a contract with the outer world, you write tests with assumptions. In case someone changes those assumptions, the test will fail.

Given these boundaries, it's quite obvious now why the operation does not have access to the environment, and why HTTP is not it's business at all. We will learn how this is handled in a further chapter.

Having understood the basic mechanics of the operation, in the next chapter we are going to discover what additional abstractions Trailblazer brings, and how policies, forms, persistence layer and all that hooks into the operation's workflow.

