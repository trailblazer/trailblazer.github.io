---
layout: operation2
title: 03- Rails Basics
gems:
  - ["trailblazer", "trailblazer/trailblazer", "2.0"]
description: "Learn how to use Trailblazer in Rails for processing and rendering actions."
imageurl: http://trailblazer.to/images/summary/guide-02.png
---

Now that we've learned [what operations do](01-operation-basics.html) and how Trailblazer [provides convenient macro steps](02-trailblazer-basics.html) to ease your life as a software engineer, it's time to check out how to use operations, contracts, and cells in Rails.

<i class="fa fa-download" aria-hidden="true"></i> Where's the [**EXAMPLE CODE?**](https://github.com/trailblazer/guides/tree/operation-03)

## Setup

In this example we will use Trailblazer operations with Reform form objects to validate and process incoming data.

Here's the `Gemfile`.

{{ "Gemfile:gemfile:../trailblazer-guides:operation-03" | tsnippet }}

The `trailblazer-rails` gem makes the integration a walk in the park. It pulls and invokes the [`trailblazer-loader` gem](/gems/trailblazer/loader.html) automatically for you [via a Railtie](https://github.com/trailblazer/trailblazer-rails/blob/master/lib/trailblazer/rails/railtie.rb). All Trailblazer files are eager-loaded.

{% callout %}
In Trailblazer, we don't believe that an ever-changing runtime environment is a good idea. Code that is, maybe, loaded, in a certain order, maybe, is a source of many production problems. Even in development mode we want an environment as close to production as possible.

This is why `trailblazer-loader` always loads all TRB files at server startup. The speed decrease is about 2 seconds and ignorable, since the automatic reloading with Rails still works.
{% endcallout %}

The Traiblazer-rails gem also adds one single method `#run` to the `ApplicationController` which we'll discover soon.

## File Structure

You can always discover a Trailblazer application in Rails by the `app/concepts` directory.

{% row %}
  ~~~6
    ├── app
    │   ├── concepts
    │   │   ├── blog_post
    │   │   │   ├── cell
    │   │   │   │   ├── edit.rb
    │   │   │   │   ├── index.rb
    │   │   │   │   ├── item.rb
    │   │   │   │   ├── new.rb
    │   │   │   │   └── show.rb
    │   │   │   ├── contract
    │   │   │   │   ├── create.rb
    │   │   │   │   └── edit.rb
    │   │   │   ├── operation
    │   │   │   │   ├── create.rb
    │   │   │   │   ├── delete.rb
    │   │   │   │   ├── index.rb
    │   │   │   │   ├── show.rb
    │   │   │   │   └── update.rb
    │   │   │   └── view
    │   │   │       ├── edit.slim
    │   │   │       ├── index.slim
    │   │   │       ├── item.slim
    │   │   │       ├── new.slim
    │   │   │       └── show.slim
    │   │   └── user
    │   │       ├── contract
    │   │       │   └── create.rb
    │   │       └── operation
    │   │           └── create.rb
    │   ├── controllers
    │   │   ├── application_controller.rb
    │   │   └── blog_posts_controller.rb
    │   └── models
    │       ├── blog_post.rb
    │       └── user.rb

  ~~~6
This is where files are structured by *concept*, and then by technology. What is very different to Rails has proven to be highly intuitive and emphasizes the modularity TRB brings.

For example, all classes and views related to the "blog post" concept are located in `app/concepts/blog_post`. The different abstractions are represented with their own directories, such as `blog_post/operation` or `blog_post/contract`.

Keep in mind that it is also possible to use nested concepts as in `app/concepts/admin/ui/post`.

Also, in Trailblazer we decided that **all file and class names are singular** which means you don't have to think about whether or not something should be plural (it is still possible to use plural names, e.g. `app/concepts/invoices/..`).

Your controllers and models, unless desired differently, are still organized the Rails Way, allowing TRB to be used in existing projects for refactoring.
{% endrow %}

## Presentation Operation

Since we already covered the essential mechanics in chapter 02, we can jump directly into the first problem: how do we render a form to create a blog post?

At first, we need a *presentation* operation that creates an empty `BlogPost` for us and sets up a Reform object which can then be rendered in a view. This operation per convention is named `BlogPost::Create::Present` and sits in `app/concepts/blog_post/operation/create.rb`.

{{ "app/concepts/blog_post/operation/create.rb:createop:../trailblazer-guides:operation-03" | tsnippet : "present" }}

Those are all steps we've discussed in chapter 02. Create a new model, and use `Contract::Build` to instantiate a Reform form that decorates the model.

{% callout %}
It's totally up to you whether or not you want a separate file for `Present` operations, or if you want to name them `New` and `Edit`. The convention shown here is in use in hundreds of applications and has evolved as a best-practice over the last years.
{% endcallout %}

## Contract

The interesting part here is the `:constant` option: it references the `BlogPost::Contract::Create` class, which itself lives in `app/concepts/blog_post/contract/create.rb`.

{{ "app/concepts/blog_post/contract/create.rb:contract:../trailblazer-guides:operation-03" | tsnippet : "present" }}

Contracts can be pure `dry-validation` schemas or Reform objects that can in turn use `dry-validation` as their validation engine. Using a reform object, whatsoever, will allow rendering that form in a view.

## Contract Rendering

We now have the form and operation in place and are ready to hook that into the `BlogPostsController`'s `new` action.

{{ "app/controllers/blog_posts_controller.rb:new:../trailblazer-guides:operation-03" | tsnippet }}

The `run` method invokes the operation, optionally passes dependencies such as the `current_user` into the operation's `call`, and then sets some default variables such as `@model` and `@form` for you.

{% callout %}
The instance variables in the controller are only set for your convenience and could be retrieved via the result object, too. [→ API ](/gems/trailblazer/2.0/rails.html#run)
{% endcallout %}

After running the operation and retrieving the contract instance, it is now time to render a view with a form, that we can actually fill out and publish our blog post. This happens via `render` and by passing the `@form` object to it.

The `BlogPost::Cell::New` cell is responsible for rendering this view. We will discuss its internals later, but for a quick preview, here's the cell view in `app/concepts/blog_post/view/new.slim`.

{{ "app/concepts/blog_post/view/new.slim:new:../trailblazer-guides:operation-03" | tsnippet }}

Submitting the form will POST it to `/blog_posts/`, which is the next controller action we have to implement.

## Form Processing

Again, we run an operation. This time it's `BlogPost::Create`.

{{ "app/controllers/blog_posts_controller.rb:create:../trailblazer-guides:operation-03" | tsnippet }}

A nice detail about `run` is: it executes an optional block when the operation was run successful. This means we can redirect to the index page in case of a successful blog post create. Otherwise, we re-render the form cell.

## Nested

To understand how the operation knows whether or not it was run successful, we should have a look at the code in `app/concepts/blog_post/operation/create.rb`.

{{ "app/concepts/blog_post/operation/create.rb:createop:../trailblazer-guides:operation-03" | tsnippet }}

As you can see, we reuse the existing `Create::Present` to create the model and contract for it, and then run validation and persisting steps after it. This all happens [by leveraging `Nested`](http://localhost:4000/gems/operation/2.0/api.html#nested). It runs the `Create::Present` operation and copies the key/value pairs from its result object into the composing operation's result object.

## Feature Tests

## Operation Tests
