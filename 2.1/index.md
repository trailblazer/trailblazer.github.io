---
layout: operation-2-1
title: Operation 2.1 API
gems:
  - ["trailblazer-operation", "trailblazer/trailblazer-operation", "2.1"]
code: ../trailblazer/test/docs,trace_test.rb,master
---

 "macaroni_test.rb:create:../trailblazer-operation/test/docs:master" | tsnippet : "ign" }}

hallo from cells!
 und bitte

## yo

```ruby
  def a(x=1)
  end
```
explain

<!-- @trailblazer-rails loader, trailblazer-loader, rails support, -->

## Trailblazer in Rails            {#trailblazer-rails}

Trailblazer runs with any Ruby web framework. However, if you're using Rails, you're lucky since we provide convenient glue code in the `trailblazer-rails` gem.

```ruby
gem "trailblazer-rails"
```

todo: add versioning information

### Loader

The `trailblazer-loader` gem implements a very simple way to load all files in your `concepts` directory in a heuristically meaningful order. It can be used in any environment.


<!-- @trailblazer-loader, disable loader, file structure -->

#### Loader with Rails {#trailblazer-rails-loader}

The `trailblazer-loader` gem comes pre-bundled with `trailblazer-rails` for historical reasons: in the early days of Trailblazer, the conventional file name `concepts/product/operation/create.rb` didn't match the short operation name, such as `Product::Create`.

The `trailblazer-loader` gem's duty was to load all concept files without using Rails' autoloader, overcoming the latter's conventions.

Over the years, and with the emerge of controller helpers or our workflow engine calling operations for you, the class name of an operation more and becomes a thing not to worry about.

Many projects use Trailblazer along with the Rails naming convention now. This means you can disable the loader gem, and benefit from Rails auto-magic behavior such as faster loading in the "correct" order, reloading and all the flaws that come with this non-deterministic behavior.

As a first step, add `Operation` to your operation's class name, matching the Rails naming convention.

```ruby
# app/concepts/product/operation/create.rb

module Product::Operation
  class Create < Trailblazer::Operation
    # ...
  end
end
```

It's a Trailblazer convention to put `[ConceptName]::Operation` in one line: it will force Rails to load the concept name constant, so you don't have to reopen the class yourself.

This will result in a class name `Product::Operation::Create`.

Next, disable the loader gem, in `config/initializers/trailblazer.rb`.

```ruby
# config/initializers/trailblazer.rb

YourApp::Application.config.trailblazer.enable_loader = false
```

Trailblazer files will now be loaded by Rails - you need to follow the Rails autoloading file naming from here on, and things should run smoothly. A nice side-effect here is that in bigger projects (with hundreds of operations), the start-up time in development accelerates significantly.
