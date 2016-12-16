---
layout: cells
title: "Trailblazer::Cell"
gems:
  - ["trailblazer-cells", "trailblazer/trailblazer-cells", "2.0"]
---

This documents the Trailblazer-style cells semantics, brought to you by the [trailblazer-cells](https://github.com/trailblazer/trailblazer-cells) gem.

{% callout %}
This gem can be used **stand-alone** without Trailblazer, its only dependency is the `cells` gem.
{% endcallout %}

A `Trailblazer::Cell` is a normal cell with Trailblazer semantics added. Naming, file structure, and the way views are resolved follow the TRB style. Note that this will be the standard for Cells 5, which will drop all old "dialects".

## Installation

```ruby
gem "trailblazer-cells"
gem "cells-slim"
```

Make sure you also add the view engine. We recommend [`cells-slim`](https://github.com/trailblazer/cells-slim).

## File Structure

In Trailblazer, cell classes sit in their concept's `cell` directory, the corresponding views sit in the `view` directory.

```
├── app
│   ├── concepts
│   │   └── comment            # namespace/class
│   │       ├── cell           # namespace/module
│   │       │   ├── index.rb   # class
│   │       │   ├── new.rb     # class
│   │       │   └── show.rb    # class
│   │       └── view
│   │           ├── index.slim
│   │           ├── item.slim
│   │           ├── new.slim
│   │           ├── show.slim
│   │           └── user.scss

```

Note that one cell class can have multiple views, as well as other assets like `.scss` stylesheets.

Also, the view names with `Trailblazer::Cell` are *not* called `show.slim`, but named after its corresponding cell class. For instance, `Comment::Cell::Index` will render `comment/view/index.slim`.

## Naming

As always, the Trailblazer naming applies.

```ruby
Comment[::SubConcepts]::Cell::[Name]
```

This results in classes such as follows.


```ruby
module Comment::Cell            # namespace
  class New < Trailblazer::Cell # class
    def show
      render # renders app/concepts/comment/view/new.slim.
    end
  end
end
```

This is different to old suffix-cells. While the `show` method still is the public method, calling `render` will use the `new.slim` view, as inferred from the cell's last class constant segment (`New`).

## Default Show

Note that you don't have to provide a `show` method, it is created automatically.

```ruby
module Comment::Cell
  class New < Trailblazer::Cell
  end
end
```

This is the **recommended way** since no setup code should be necessary.

You're free to override `show`, though.

## View Names

Per default, the view name is computed from the cell's class name.

```ruby
Comment::Cell::New         #=> "comment/view/new.slim"
Comment::Cell::Themed::New #=> "comment/view/themed/new.slim"
```

Note that the entire path after `Cell::` is considered, resulting in a hierarchical view name.

Use `ViewName::Flat` if you prefer a flat view name.

```ruby
module Comment
  module Cell
    module Themed
      class New < Trailblazer::Cell
        extend ViewName::Flat
      end
    end
  end
end

Comment::Cell::Themed::New #=> "comment/view/new.slim"
```

This will always result in a flat name where the view name is inferred from the last segment of the cell constant.

## Invocation

To render a cell in controllers, views, or other cells, use `cell`. You need to provide the constant directly. Ruby's constant lookup rules apply.

    html = cell(Comment::Cell::New, result["model"]).()

## Layouts

It's a common pattern to maintain a cell representing the application's layout(s). Usually, it resides in a concept named after the application.

```
├── app
│   ├── concepts
│   │   └── gemgem
│   │       ├── cell
│   │       │   ├── layout.rb
│   │       └── view
│   │           ├── layout.slim
```

Most times, the layout cell can be an empty subclass.

```ruby
module Gemgem::Cell
  class Layout < Trailblazer::Cell
  end
end
```

The view `gemgem/view/layout.slim` contains a `yield` where the actual content goes.

```
!!!
%html
  %head
    %title= "Gemgem"
    = stylesheet_link_tag 'application', media: 'all'
    = javascript_include_tag 'application'
  %body
    = yield
```

Wrapping the content cell (`Comment::Cell::New`) with the layout cell (`Gemgem::Cell::Layout`) happens via the public `:layout` option.

```ruby
concept("comment/cell/new", result["model"], layout: Gemgem::Cell::Layout)
```

This will render the `Comment::Cell::New`, instantiate `Gemgem::Cell::Layout` and pass through the context object, then render the layout around it.
