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

## Render

The gem overrides `ActionController#render` and now allows to render a `Trailblazer::Cell`.

    class SongsController < ApplicationController
      def create
        run Song::Create do |result|
          return redirect_to song_path(result["model"].id)
        end

        render cell: Song::Cell::New, model: @model
      end
    end

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
        page.must_have_css "form.new_song[action='/songs']"
      end
    end
