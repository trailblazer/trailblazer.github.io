---
layout: operation2
title: 01- Operation Basics
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0"]
redirect_from: "/guides/trailblazer/2.0/01-getting-started-with-operation.html"
---
{% row %}
  ~~~6
  {{ "app/blog_post/operation/create.rb:failure:../trailblazer-guides:operation-01" | tsnippet : "impl" }}

  ~~~6
  The *Operation* is the central concept of the Trailblazer architecture. It's a simple service object that encapsulates and orchestrates all the business logic necessary to accomplish a certain task, such as creating a blog post, or updating a user.

  In this guide we'll create a small example operation that's responsible for having a simple conversation and fixing the other person's mood.
{% endrow %}

Operation provides you with an API that lets you structure your business code into *steps*. Its API is heavily inspired by the "Railway-oriented programming" pattern that combines structuring linear code, and error handling - but more on that later.

Don't let yourself be tricked into thinking the operation is a "god object", as it's been called by critics. The opposite is the case: while the operation knows *what* to orchestrate and *when*, it has zero knowledge about *how*, since the implementation of its steps is hidden from it.

{% callout %}
You can find the code for this page [here](https://github.com/trailblazer/guides/tree/operation-01).
{% endcallout %}

## Gemfile

In the [repository](https://github.com/trailblazer/guides/tree/operation-01) for this page, you will find a very slim `Gemfile`.

    gem "trailblazer-operation"
    gem "rspec"

The `trailblazer-operation` gem gives you the `Trailblazer::Operation` class and its Railway semantics. Nothing more. It does *not* have any other dependencies, which is helpful as it means you can start learning Trailblazer with a setup as simple as possible.

We will explore the operation's behavior using specs. This is my personal favorite way to play with new ideas or gems. The examples here will use RSpec, but you can use Minitest if you prefer. Trailblazer is not coupled to any specific test framework.

## Our first Operation

When implementing a blog website, it's probably quite handy to give a user the ability to write and create a blog post.

In most web frameworks like Rails, you'd start with a `PostsController` and an action `#create` that receives and processes a post form.

    class PostsController < RubyOnTrails::Controller
      def create
        post = Post.new
        post.assign_attributes(params[:post])
        if post.save
          notify_current_user!
        else
          render
        end
      end
    end

Notice how the #create method encapsulates all the business logic involved in creating a post. In Trailblazer we follow the same philosophy of keeping our business logic in one place, but instead of placing it directly into the controller layer (where it's now tightly coupled to things like HTTP, routing, and rendering a response), we encapsulate everything within a separate class called an operation. The operation focuses solely on domain logic and leaves routing and rendering up to the controller, which also means that Trailblazer operations can be used with any Ruby framework, not just Rails. Another nice thing about this approach is that it means we can start coding our operations right away without any web framework or routing, and even without thinking about HTTP - a deeply relaxing thought.

An operation is simply a Ruby object that inherits from `Trailblazer::Operation` and that can be run anywhere.

In `app/blog_post/operation/create.rb` I add an empty class:

{{ "app/blog_post/operation/create.rb:op:../trailblazer-guides/:operation-01" | tsnippet }}

`Create` is a subclass of `Trailblazer::Operation`, but it's worth noting that we're only actually inheriting [a few dozen lines](https://github.com/trailblazer/trailblazer-operation/blob/master/lib/trailblazer/operation.rb) of code here.

## Naming

The actual `Create` operation is put into the `BlogPost` namespace. This is very common in Trailblazer: we leverage Ruby namespaces. This results in the beautiful operation class named `BlogPost::Create`; a very expressive class name, don't you think?

Before adding any logic, let's run this very operation via a spec in `spec/blog_post/operation/create_spec.rb`.

{{ "spec/blog_post/operation/create_spec.rb:fresh:../trailblazer-guides:operation-01" | tsnippet }}

In an empty test case, we invoke (or *call*) our as-yet unspoiled operation.

## Call

That's right, there's only one way to run an operation, and that's the "`call` style". Confused? Here's an alternative way to spell `BlogPost::Create.()`:

    BlogPost::Create.call()

`.()` is just an alias for `.call()`. This is pure Ruby, nothing to do with Trailblazer, and was introduced in Ruby 1.9 if I remember correctly. While it might look bizarre to you at first glance, there's a profound reasoning behind this decision.

<!-- instantiation? -->
An operation, conceptually, is just a *function*. It does only one thing and doesn't need more than one public method. Since the operation's name reflect what it does, you don't need a method name. This is why in Trailblazer you will have many `call`able objects instead of one object with many methods.

{% callout %}
You will soon learn how this greatly improves your architecture since the functional approach minimizes internal state and the [associated mess it might create](https://apotonick.wordpress.com/2014/05/22/rails-misapprehensions-single-responsibility-principle/).
{% endcallout %}

While our spec works, or at least no exception is raised, this is not very impressive. Let's see what it actually returns.

{{ "spec/blog_post/operation/create_spec.rb:puts:../trailblazer-guides:operation-01" | tsnippet }}

Calling an operation always gives you a *result object*. This object is used to transport state, communicate internals to the outer world, and to indicate whether or not the operation was successful. Why don't we make sure it didn't break?

{{ "spec/blog_post/operation/create_spec.rb:success:../trailblazer-guides:operation-01" | tsnippet }}

The `Result#success?` method and its inverse `failure?` are here to test that, from the caller perspective.

## Baby Steps

It might be a good idea to actually add some logic to our operation. While we could simply add a big method with lots of code in a nested procedural style, Trailblazer encourages you to structure your code into a *pipeline*, where steps in the pipe implement parts of the domain code.

{{ "app/blog_post/operation/create.rb:step:../trailblazer-guides/:operation-01" | tsnippet }}

You can add steps with the [`step` method](http://trailblazer.to/gems/operation/2.0/api.html#flow-control-step). It allows you to implement steps using methods, [lambdas](http://trailblazer.to/gems/operation/2.0/api.html#step-implementation-lambda) and [callable objects](http://trailblazer.to/gems/operation/2.0/api.html#step-implementation-callable). For simplicity, let's start with instance methods. The `hello_world!` method sits in the operation as an instance method. It receives some arguments that we'll learn about later. In the body, it's up to us to implement that step.

{% callout %}
Suffixing step methods with a bang (e.g. `model!`) is a purely stylistic choice; it has no semantic meaning.
{% endcallout %}

Running this operation will hopefully output something.

{{ "spec/blog_post/operation/create_spec.rb:step:../trailblazer-guides:operation-01" | tsnippet }}

We can see a greeting on our command line. But, hang on, what's that? The operation didn't finish successfuly, our test just broke... after working with TRB for 2 minutes!

## Step: Return Value Matters

The operation fails because the return value of a `step` matters! If a step returns `nil` or `false` (aka. if it returns a *falsey* value - these are the only two falsey values in Ruby), the operation's result will be marked as failed, and any steps after the failing step won't be executed.

Since `puts` will always return `nil` (and [no one knows why](http://stackoverflow.com/questions/14741329/why-are-all-my-puts-returning-nil)), we manually have to return a truthy value to make the next step be invoked.

{{ "app/blog_post/operation/create.rb:return-value:../trailblazer-guides/:operation-01" | tsnippet }}

It looks odd, and we should've simply used `p` (which prints the string *and* returns a truthy value), but it will probably make the spec pass.

{{ "spec/blog_post/operation/create_spec.rb:return-value:../trailblazer-guides:operation-01" | tsnippet }}

Yes, our tests are green again.

## Multiple Steps

Having fixed the first problem, we should extend our operation with another step.

Multiple steps will be executed in the order you added them.

{{ "app/blog_post/operation/create.rb:steps:../trailblazer-guides/:operation-01" | tsnippet }}

The operation will now greet and enquire about your wellbeing.

{{ "spec/blog_post/operation/create_spec.rb:steps:../trailblazer-guides:operation-01" | tsnippet }}

How friendly! I wish more operations could be like you.

## Breaking Things

We're all curious about what will happen when the first step returns `false` instead of `true`, aren't we?

{{ "app/blog_post/operation/create.rb:breaking:../trailblazer-guides/:operation-01" | tsnippet }}

The `hello_world!` step now returns `nil`, making the operation's flow "fail". What does that mean?

{{ "spec/blog_post/operation/create_spec.rb:breaking:../trailblazer-guides:operation-01" | tsnippet }}

The step following the "broken" step now doesn't get executed anymore. Furthermore, the operation's result is a failure. Awesome, we broke things, and that's exactly what we wanted!

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

{{ "app/blog_post/operation/create.rb:success:../trailblazer-guides/:operation-01" | tsnippet }}

This looks better, and, more important: another developer looking at this operation will instantly understand the first two steps do always pass.

We now understand how to implement an operation with successive steps, and how to communicate that to the caller with the result object. Next, we should explore how to *read* input, test it and maybe have alternative flows depending on a certain value.

## Handling Input

Since our operation seems to be interested in our health, and actually asks us about it, we should pass the answer into it. With operations, there's only one way to pass data into it, and that's, of course, in `call`.

{{ "spec/blog_post/operation/create_spec.rb:input:../trailblazer-guides:operation-01" | tsnippet }}

We now have to implement a check that tests our answer, and if it happens to be `"yes"`, wish a good day, and make the outcome successful.


{{ "app/blog_post/operation/create.rb:input:../trailblazer-guides/:operation-01" | tsnippet }}

The middle step `how_are_you?` is now added with `step`, making its return value matter. That means, if the `params[:happy] == "yes"` check is true, the next step is going to be executed. And, surprisingly, given the above test case with the respective input, this works.

Of course, we now have to test the opposite scenario, too. What if we're unhappy?

{{ "spec/blog_post/operation/create_spec.rb:input-false:../trailblazer-guides:operation-01" | tsnippet }}

Then, only the first two steps are executed, the third is skipped. Also, the result's state is "failed".

## Options

Before we dive into error handling, let's quickly discuss how steps access the input.

Remember how we called the operation?

{{ "spec/blog_post/operation/create_spec.rb:input-call:../trailblazer-guides:operation-01" | tsnippet }}

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

{{ "app/blog_post/operation/create.rb:failure:../trailblazer-guides/:operation-01" | tsnippet }}

The pipe, or railway, created now represents the one we've just seen in the diagram. Due to the way `failure` works, it will only be executed if `how_are_you?` fails.

## Writing Output

In the new `tell_joke!` step, you can see that we write to `options`. That's how you communicate state changes to the outer world. For example, that could be an error message interpreted by the operation user.

Note that writing applies to any kind of state, right or left track! To keep this example brief, we only write in this one step, though.

{{ "spec/blog_post/operation/create_spec.rb:failure:../trailblazer-guides:operation-01" | tsnippet }}

When passing in a negative (or false) value for `:happy`, the second step `how_are_you?` will deviate to the left track. This is why we can test the result's state for `failure?` and why the `options[:joke]` value is set.

It's up to the operation caller to decide whether or not they find this joke hilarious.

## Interpretation

Speaking about decisions: in Trailblazer, it is not the operation's job or scope to decide what will happen given that the railway took path A, B or even C. The operation may write as many flags, objects, booleans, whatever you need to the `options` hash and thus expose state and internal decisions.

Nevertheless, the interpretation of the result is the sole business of the caller. *What* will happen with this result is up to the controller, the background job, or wherever else you use the operation.

To make sure that the operation provides those values and to have a contract with the outer world, you write tests with assumptions. In case someone changes those assumptions, the test will fail.

Given these boundaries, it's quite obvious now why the operation does not have access to the environment, and why HTTP is not it's business at all. We will learn how this is handled in a further chapter.

Having understood the basic mechanics of the operation, in [the next chapter](02-trailblazer-basics.html) we are going to discover what additional abstractions Trailblazer brings, and how policies, forms, persistence layer and all that hooks into the operation's workflow.

{% row %}
  ~~~12,text-center
  <a href="02-trailblazer-basics" class="button">GO TO PART 2: TRAILBLAZER BASICS!</a>
{% endrow %}
