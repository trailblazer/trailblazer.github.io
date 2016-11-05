---
layout: operation2
title: Endpoint
gems:
  - ["trailblazer-endpoint", "trailblazer/trailblazer-endpoint", "2.0"]
---

`Endpoint` defines possible outcomes when running an operation and provides a neat matcher mechanism using the [`dry-matcher` gem](http://dry-rb.org/gems/dry-matcher/) to handle those predefined scenarios.

It is both usable without Trailblazer and helps to implements endpoint in all frameworks, including Rails and Hanami.

To get a quick overview how endpoints work in Rails, jump to the [→Rails section](#rails).

## Outcomes

An endpoint is supposed to be run either in a controller action, or directly hooked to a Rack route. It runs the specified operation, and then inspects the result object to find out what scenario is met.

Possible outcomes are:

* **`not_found`** when a model via [`Model` configured as `:find_by`](model.html#find_by) is not found.
* **`unauthenticated`** when a policy via [`Policy`](policy.html) reports a breach.
* **`unauthorized`** when a policy via [`Policy`](policy.html) reports a breach (NOT YET IMPLEMENTED).
* **`created`** when an operation successfully ran through the pipetree to create one or more models.
* **`success`** when an operation was run successfully.
* **`present`** when an operation is supposed to load model that will then be presented.

All outcomes are detected via a `Matcher` object [implemented in the `endpoint` gem](https://github.com/trailblazer/trailblazer-endpoint/blob/master/lib/trailblazer/endpoint.rb#L7) using [pattern matching](http://wiki.c2.com/?PatternMatching) to do so. Please note that in the current state, those heuristics are still work-in-progress and [we need your help](https://gitter.im/trailblazer/chat) to define them properly.

Naturally, you may [add your own](#adding-outcomes) domain-specific outcomes.

## Handlers

While `Matcher` is the authorative source for deciding the state of the operation, it is up to you how to react to those well-defined states. This happens using *handlers* that you can define manually, or use a built-in set. Currently, we have handlers for [Rails controllers](#rails) and [Hanami::Router](#Hanami).

You can pass a block to `Endpoint#call` with your handlers and hand in the `Result` object.

    result = Song::Create.({ title: "SVT" }, "user.current" => User.root)

    Trailblazer::Endpoint.new.(result) do |m|
      m.success         { |result| puts "Model #{result["model"]} was created successfully." }
      m.unauthenticated { |result| puts "You ain't root!" }
    end


While the state decisions are abstracted away, handling those outcomes lies in the programmer's hands.

### Handler Proc

You can also organize common outcomes in a callable object, such as a proc.

    MyHandlers = ->(m) do
      m.success         { |result| puts "Model #{result["model"]} was created successfully." }
      m.unauthenticated { |result| puts "You ain't root!" }
    end

And then, hand them into `Endpoint#call` as the second argument.

    Trailblazer::Endpoint.new.(result, MyHandlers)

### Handler: Proc and Block

When handing in a proc *and* using a block, the block takes precedence over the proc object's handlers. This is meant to ad-hoc-override generic behavior.

    Trailblazer::Endpoint.new.(result, MyHandlers) do |m|
      m.unauthenticated { |result| raise "Break-in!" }
    end

With a successful outcome, the generic handler from `MyHandlers` is applied. Running this without a current user will raise an exception from the block, though.



## Adding Outcomes

## Rails

Standard [handlers](#handlers) are provided for Rails and are meant to replace responders.

    require "trailblazer/endpoint/rails" # do that in `config/initializers/trailblazer.rb`!

    class SongsController < ApplicationController
      include Trailblazer::Endpoint::Controller

      def create
        endpoint Song::Create, path: songs_path, args: [ params, { "user.current" => current_user } ]
      end
    end

`endpoint` will run `Song::Create`, use the pre-defined matchers to find out the scenario, and run a generic handler for it.

### Rails Handlers

The generic behavior works as follows.

* **`not_found`** calls `head 404`.
TODO: add descriptions once it's stable.

Check out [the implementation](https://github.com/trailblazer/trailblazer-endpoint/blob/master/lib/trailblazer/endpoint/rails.rb) for more details, it's very readable.

### Rails Ad-Hoc Overriding

To run your custom logic in a specific controller action, pass a block to `endpoint`.

    class SongsController < ApplicationController
      def create
        endpoint Create, path: songs_path, args: [ params, { "user.current" => current_user } ] do |m|
          m.created { |result| render json: result["representer.serializer.class"].new(result["model"]), status: 999 }
        end
      end

TODO: explain `:path` etc, and make it optional.

## Hanami
