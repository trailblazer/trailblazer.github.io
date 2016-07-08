---
layout: cells
title: "Trailblazer::Cell"
---

# Trailblazer::Cell

This documents the Trailblazer-style cells semantics, brought to you by the [trailblazer-cells](https://github.com/trailblazer/trailblazer-cells) gem. This gem is not dependent on Trailblazer and can be used without it.

```ruby
gem "trailblazer-cells"
```

## File Structure

In Trailblazer, cell classes sit in their concept's `cell` directory, the corresponding views sit in the `view` directory.

```
├── app
│   ├── concepts
│   │   └── comment
│   │       ├── cell
│   │       │   ├── index.rb
│   │       │   ├── new.rb
│   │       │   └── show.rb
│   │       └── view
│   │           ├── index.haml
│   │           ├── item.haml
│   │           ├── new.haml
│   │           ├── show.haml
│   │           └── user.scss

```

Note that one cell class can have multiple views, as well as other assets like `.scss` stylesheets.

Also, the view names with `Trailblazer::Cell` are *not* called `show.haml`, but named after its corresponding cell class.

## Naming

As always, the Trailblazer naming applies.

```ruby
Comment[::SubConcepts]::Cell::[Name]
```

This results in classes such as follows.


```ruby
module Comment # or: Comment < ActiveRecord::Base or alike.
  module Cell
    class New < Trailblazer::Cell
      def show
        render # renders app/concepts/comment/view/new.haml.
      end
    end
  end
end
```

This is different to old suffix-cells. While the `show` method still is the public method, calling `render` will use the `new.haml` view, as inferred from the cell's last class constant segment (`New`).

## Default Show

Note that you don't have to provide a `show` method, it is created automatically.

```ruby
class New < Trailblazer::Cell
end
```

You're free to override `show`, though.

## View Names

Per default, the view name is computed from the cell's class name.

```ruby
Comment::Cell::New #=> "new.haml"
Comment::Cell::Themed::New #=> "themed/new.haml"
```

Note that the entire path after `Cell::` is considered, resulting in a hierarchical view name.

Use `ViewName::Flat` if you prefer a flat view name.

```ruby
module Comment # or: Comment < ActiveRecord::Base or alike.
  module Cell
    module Themed
      class New < Trailblazer::Cell
        extend ViewName::Flat
      end
    end
  end
end

Comment::Cell::Themed::New #=> "new.haml"
```

This will always result in a flat name where the view name is inferred from the last segment of the cell constant.

## Invocation

Manual invocation is always possible as discussed here.

As per Cells 4.1, you can use the `concept` helper to invoke a Trailblazer cell from a controller, view, or test.

```ruby
concept("comment/cell/new", op.model).()
```

You have to provide the fully-qualified constant path.

Within a Trailblazer cell, you can use `concept` to invoke nested cells.

Alternatively, you can use `cell` and provide the constant directly. This applies to both controllers/views and within cells.

```ruby
cell(Comment::Cell::New, op.model).()
```

## Layouts

It's a common pattern to maintain a cell representing the application's layout(s). Usually, it resides in a concept named after the application.

```
├── app
│   ├── concepts
│   │   └── gemgem
│   │       ├── cell
│   │       │   ├── layout.rb
│   │       └── view
│   │           ├── layout.haml
```

Most times, the layout cell can be an empty subclass.

```ruby
class Gemgem::Cell::Layout < Trailblazer::Cell
end
```

The view `gemgem/view/layout.haml` contains a `yield` where the actual content goes.

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
concept("comment/cell/new", op.model, layout: Gemgem::Cell::Layout)
```

This will render the `Comment::Cell::New`, instantiate `Gemgem::Cell::Layout` and pass through the context object, then render the layout around it.
