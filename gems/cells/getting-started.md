---
title: "Cells: Getting Started"
layout: docs
description: "Learn how Trailblazer::Cell helps you refactoring legacy views. 4-minutes read."
---

The [Cells](https://github.com/apotonick/cells) gem provides view models for Ruby web applications. View models are plain objects that represent a part of the web page, such as a dashboard widget. View models can also render views, and be nested.

Cells is a replacement for ActionView and used in many Rails projects. However, Cells can be used in any web framework such as Sinatra or Hanami.

This guide discusses how to get started with `Trailblazer::Cell`, the canonical view model implementation following the Trailblazer file and naming structure. Don't worry, `Trailblazer::Cell` can be used without Trailblazer.

## Refactoring Legacy Views

When refactoring legacy views into a solid cell architecture, it is often advisable to start with small fragments and extract markup and logic into an object-oriented cell. After that is done, you can move up and replace a bigger fragment of the view, and so on.

Given you were running an arbitrary Ruby web application, let's assume you had a menu bar sitting in your global layout. The menu shows navigation links to pages and - dependent on the login status of the current user - either a miniatur avatar of the latter or a link to sign in.

Since this is quite a bit of logic, it's a good idea to encapsulate that into an object.

Here's what the old legacy `layout.html.haml` looks like.

{% tabs code %}
~~HAML

    %html
      %head

      %body
        %nav.top-bar
          %ul
            %li SUPPORT CHAT
            %li GUIDES
            %li
              - if signed_in?
                %img{src: avatar_url}
              - else
                "SIGN IN"

~~ERB

    <html>
      <head></head>

      <body>
        <nav class="top-bar">
          <ul>
            <li>SUPPORT CHAT</li>
            <li>GUIDES</li>
            <li>
              <% if signed_in? %>
                <img src="<%= avatar_url %>">
              <% else %>
                SIGN IN
              <% end %>
            </li>
      </body>
    </html

{% endtabs %}

Of course, this navigation bar doesn't really make sense without any links added. I've left that out so we can focus on the structure. We will discuss how helpers work in the per-framework sections below.

## Extraction

In order to convert all markup below the `<nav>` node into a cell, we first need to add the respective gems to our `Gemfile`.

{% tabs %}
~~Ruby
For now, all you need is the `trailblazer-cells` gem and the Cells template engine.

    gem "trailblazer-cells"
    gem "cells-hamlit"
~~Rails
In Rails, you need the `trailblazer-cells` gem and the Cells template engine.

    gem "trailblazer-cells"
    gem "cells-hamlit"
    gem "cells-rails"

The `cells-rails` gem will add cell invocation helpers to controllers and views, and supply the URL helpers in cells.
{% endtabs %}


Please note that `trailblazer-cells` simply loads the `cells` gem and then adds some simple semantics on top of it. Also, [Cells supports Haml, Hamlit, ERB, and Slim](api.html#template-formats).

Cut the `%nav` fragment from the original `layout.html.haml` and replace it with the cell invocation.

{% tabs %}
~~Ruby
{% tabs code %}

~~HAML
    %html
      %head

      %body
        = Pro::Cell::Navigation.(nil, current_user: current_user).()

~~ERB

    <html>
      <head></head>

      <body>
        <%= Pro::Cell::Navigation.(nil, current_user: current_user).() %>
      </body>
    </html>
{% endtabs %}

Cells can be invoked using the call style.

~~Rails

{% tabs code %}
~~HAML

    %html
      %head

      %body
        = cell(Pro::Cell::Navigation, nil, current_user: current_user)

~~ERB

    <html>
      <head></head>

      <body>
        <%= cell(Pro::Cell::Navigation, nil, current_user: current_user) %>
      </body>
    </html>

{% endtabs %}

In Rails, you can use the handy `cell` helper to invoke the view model.

{% endtabs %}

Instead of keeping navigation view code in the layout, or rendering a partial, the `Pro::Cell::Navigation` cell is now responsible to provide the HTML fragment representing the menu bar.

The cell is invoked without a _model_, but we pass in the `current_user` as an _option_. This code assumes that the `current_user` object is available in the layout view. As the current user is passed from your web framework to the cell, this is called an _dependency injection_.

We will learn what models and options are soon.

## Navigation Cell

Having extracted the "partial" from the layout, paste it into a new file `app/concepts/pro/view/navigation.haml`.

    %nav.top-bar
      %ul
        %li SUPPORT CHAT
        %li GUIDES
        %li
          - if signed_in?
            %img{src: avatar_url}
          - else
            "SIGN IN"

Creating a view for the cell in the correct directory is one thing. A cell is more than just a partial, it also needs a class file where the logic sits. This class goes to `app/concepts/pro/cell/navigation.rb`.

```ruby
module Pro
  module Cell
    class Navigation < Trailblazer::Cell
      include ::Cell::Hamlit

      def signed_in?
        options[:current_user]
      end

      def email
        options[:current_user].email
      end

      def avatar_url
         hexed = Digest::MD5.hexdigest(email)
        "https://www.gravatar.com/avatar/#{hexed}?s=36"
      end
    end
  end
end
```

The reason the cell class lives in the `Pro` namespace is because that's the example app's name and its top-level namespace. Since the navigation cell is an app-wide concept, it is best put into the `Pro` namespace.

Adding the class is enough to re-render your application, and you will see, the navigation menu now comes from a cell, presenting you with a hip gravatar icon when logged in, or a string to do so otherwise. Congratulations.

<img src="/images/guides/cells-nav-bar.jpg">


## Discussion: Navigation

Let's quickly discuss what happens here in what order. After this section, you will understand how cells work and probably already plan where else to use them. They're really simple!

1. Invoking the cell in the layout via `Pro::Cell::Navigation.(nil, current_user: current_user).()` will instantiate the cell object and internally invoke the cell's default rendering method, named `show`. This method is automatically provided and simply renders the corresponding view.
2. Since the cell class name is `Pro::Cell::Navigation`, this cell will render the view `concepts/pro/view/navigation.haml`. This is following the Trailblazer naming style.
3. In the cell's view, two "helpers" are called: `signed_in?` and `avatar_url`. Whatsoever, the concept of a "helper" in Cells doesn't exist anymore. Any method or variable called in the view must be an *instance method* on the cell itself. This is why the cell class defines those two methods, and not some arbitrary helper module.
4. Dependencies like the `current_user` have to get injected from the outer world when invoking the cell. Later, in the cell, those arguments can be accessed using the `options` cell method.

It is important to understand that the cell has no access to global state. You as the cell author have to define the interface and the dependencies necessary to render the cell.

It is a good idea to write tests for you cell now, to document and assert this very interface you've just created.

## Test: Navigation

Testing cells can either happen via full-stack integration tests, or with module cell unit tests. This example illustrates the latter.

A very basic test for a cell with signed in user could looks as follows.

```ruby
class NavigationCellTest < Minitest::Spec
  it "renders avatar when user provided" do
    html = Pro::Cell::Navigation.(nil, current_user: User.find(1)).()

    html.must_match "Signed in: nick@trb.to"
  end
end
```

Likewise, you can easily test the anonymous user case, where no one's logged in. The unit-test style makes it very easy to simulate that.

```ruby
it "renders SIGN IN otherwise" do
  html = Pro::Cell::Navigation.(nil, current_user: nil).()

  html.must_match "SIGN IN"
end
```

Make sure to read the [full documentation on testing cells](testing.html) for all kinds of environments, including Capybara matchers, Rails and test frameworks such as Minitest and Rspec.

## URL helpers

Besides indicating the logged-in status of the use, the `Navigation` cell should also display real links. This happens with URL helpers in web frameworks.

In `app/concepts/pro/view/navigation.haml`, add actual links to the view.

{% tabs %}
~~Ruby
    %nav
      %ul
        %li SUPPORT CHAT
          %a{href: "/support"}
        %li GUIDES
          %a{href: "/guides"}
        %li
          - if signed_in?
            %img{src: avatar_url}
          - else
            "SIGN IN"

Without any URL system, you can create links using Haml, or delegate to your own URL objects.

~~Rails
    %nav
      %ul
        %li
          = link_to "SUPPORT CHAT", chat_path
        %li
          = link_to "GUIDES", guides_path
        %li
          - if signed_in?
            %img{src: avatar_url}
          - else
            "SIGN IN"

The `cells-rails` gem conveniently allows to use URL helpers in cell views.
{% endtabs %}



## Content Cell

View models are not only great to encapsulate small fragments, but also the entire content - which is everything but the wrapping layout. For example, when browsing to `/comments/1`, the content view usually provided by a controller will now come from the `Comment::Cell::Show` cell. We call this a *content cell* in Trailblazer-speak.

In the controller, invoke this new cell instead of letting the framework render the content.

{% tabs %}
~~Ruby
    def show
      comment = Comment.find(1)
      html = Comment::Cell::Show.(comment).()
    end

~~Rails
    class CommentsController < ApplicationController
      def show
        comment = Comment.find(1)
        render html: cell(Comment::Cell::Show, comment)
      end
    end

This instructs the controller to render the `Comment::Cell::Show` cell, pass the `comment` into it, and let Rails wrap it in the application layout.
{% endtabs %}

Note that we now pass the `comment` as the cell's *model* without passing any additional *options*.

The new class lives in `app/concepts/comment/cell/show.rb`.

```ruby
module Comment::Cell
  class Show < Trailblazer::Cell
    property :body
  end
end
```

The `property` method creates a shortcut to `model.body`.

The view for this cell goes into `app/concepts/comment/view/show.haml`.

    %h1 Comment #{model.id}
    %p
      = body

In views, you can access the model via the `model` method. In this example, this is the `comment` instance we passed into the cell when invoking.

## Layout Cell

To render the entire page with Cells, the last missing piece is the layout. This is still being rendered by the underlying framework.

Again, the layout is represented by a cell. Its code goes to `app/concepts/pro/cell/layout.rb`.

```ruby
module Pro::Cell
  class Layout < Trailblazer::Cell
  end
end
```

Since this cell's sole purpose is to render a view to wrap dynamic content, no logic is needed.

The view sits at `app/concepts/pro/view/layout.haml`.

    %html
      %head

      %body
        = cell(Pro::Cell::Navigation)
        = yield

The content cell's HTML markup will be passed to the layout cell and can be `yield`ed (which basically replaces `yield` with the HTML string).

## Putting Things Together

In the controller, the content cell needs to get instructed it will be wrapped by a layout cell.

{% tabs %}
~~Ruby
    def show
      comment = Comment.find(1)

      html = Comment::Cell::Show.(comment,
        context: { current_user: current_user },
        layout:  Pro::Cell::Layout).()
    end
~~Rails
    class CommentsController < ApplicationController
    def show
      comment = Comment.find(params[:id])

      render html: cell(Comment::Cell::Show, comment,
        context: { current_user: current_user },
        layout:  Pro::Cell::Layout
        )
    end
{% endtabs %}

The following happens now.

1. First, `Comment::Cell::Show` cell is rendered.
2. Then, `Pro::Cell::Layout` is invoked and it will yield the content from the show cell.
3. In the `layout.haml` view, the navigation cell is also rendered. This cell needs a `current_user` option which is provided by the *context object*.

## Context Object

When rendering a hierarchy of cells, it's often necessary to share generic data across all involved cells. This always happens via dependency injection, no global state is allowed in Trailblazer.

The `:context` option will create such an object and is automatically being passed to all cells in that render workflow.

In order to access the `current_user` from the context object, the navigation cell has to be changed slightly.

```ruby
module Pro
  module Cell
    class Navigation < Trailblazer::Cell
      include ::Cell::Hamlit

      def signed_in?
        context[:current_user]
      end

      def email
        context[:current_user].email
      end

      def avatar_url
         hexed = Digest::MD5.hexdigest(email)
        "https://www.gravatar.com/avatar/#{hexed}?s=36"
      end
    end
  end
end
```

Note that `:current_user` is not an option anymore, but comes from the `context` object.

## Success

As demonstrated in this guide, it's not really hard to replace the existing rendering stack, whether that's `ActionView` or `Hanami::View` or Sinatra templates, with Cells.
