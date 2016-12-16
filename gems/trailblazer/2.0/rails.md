---
layout: operation2
title: Trailblazer::Rails
gems:
  - ["trailblazer-rails", "trailblazer/trailblazer-rails", "1.0"]
---

Trailblazer in your Rails controllers. The `trailblazer-rails` gem adds `#run` and `render cell: Constant` to your controllers.

This documents the version compatible with Trailblazer 2.0.

## Installation

Add the gem to your `Gemfile`.

    gem "trailblazer-rails"

This will automatically pull `trailblazer` and `trailblazer-loader`.

## Railtie

The `Trailblazer::Rails::Railtie` will activate all necessary convenience methods for you. You don't have to do anything manually here. Sit back and relax.

## Run

In a controller, you could simply invoke an operation manually.

    class SongsController < ApplicationController
      def create
        result = Song::Create.(params)

        @form = result["contract.default"]
        render :new
      end
    end

`Trailblazer-Rails` gives you `run` for this to simplify the task.

    class SongsController < ApplicationController
      def create
        run Song::Create

        render :new
      end
    end

`run` passes the controller's `params` hash into the operation call. It automatically assigns `@model` and, if available, `@form` for you.

The result object is returned.

    def create
      result = run Song::Create
      result["model"] #=> #<Song title=...>

      render :new
    end

The result object is also assigned to `@_result`.

### Run: With Block

To handle success and failure cases, `run` accepts an optional block.

    class SongsController < ApplicationController
      def create
        run Song::Create do |result|
          return redirect_to song_path(result["model"].id)
        end

        render :new
      end
    end

The block is only run for `success?`. The block argument is the operation's result.

## Runtime Options

It's clever to inject runtime dependencies such as `current_user` into the operation call.

    Song::Create.( params, "current_user" => current_user )


Override `#_run_options` to do that automatically for all `run` calls.

    class ApplicationController < ActionController::Base
    private
      def _run_options(options)
        options.merge( "current_user" => current_user )
      end
    end

## Render

The gem extends `ActionController#render` and now allows to render a `Trailblazer::Cell`.

    class SongsController < ApplicationController
      def create
        run Song::Create do |result|
          return redirect_to song_path(result["model"].id)
        end

        render cell(Song::Cell::New, @model)
      end
    end

You simply invoke `cell` the way [you did it before](/gems/cells/trailblazer.html#invocation), and pass it to `render`. Per default, `render` will add `layout: true` to render the ActionView layout. It can be turned off using `layout: false`.

As always, the `cell` method also accepts options.

    render cell(Song::Cell::New, @model, action_name: params[:action])

All arguments after `cell` are simply passed through to Rails' `render`.

    render cell(Song::Cell::New, @model, action_name: params[:action]), layout: false

Use `result` to pass the result object to the cell.

    render cell(Song::Cell::New, result)

{% callout %}
If the first argument to `render` is not a cell instance, the original Rails `render` version will be run.
{% endcallout %}



<!--
## Expose

Use `expose` to pass specified properties from the `result` object directly to the cell.

    render cell( Song::Cell::New, expose(["model", "contract.default"]) )

The `expose` method will create an intermediate object with readers for you.

    value = expose(["model", "contract.default"])
    value["model"] #=> #<Song title=... >
    value.model    #=> #<Song title=... >

This object is now passed to the cell as the `model`.

A common way to call this is using `%w{}`.

    render cell( Song::Cell::New, expose(%w{model contract.default}) )

Additional options to present can be passed as a hash.

    render cell( Song::Cell::New, expose(%w{model contract.default}, artist: Artist.last) )
 -->


## Integration Test

If you're using `Minitest::Spec` and want to run smoke tests using Capybara, use `Trailblazer::Test::Integration`.

You need to add `minitest-rails-capybara` to your `Gemfile`.

    group :test do
      gem "minitest-rails-capybara"
    end

Your tests can now use Capybara matchers.

    require "test_helper"

    class SongsControllerTest < Trailblazer::Test::Integration
      it do
        visit "/songs/new"
        page.must_have_css "form[action='/songs']"
      end
    end
