---
layout: guide
title: Getting Started
---

## Installation

As Trailblazer is highly modular, you have to make sure you include the correct gems in your `Gemfile`.

{% tabs %}
~~Rails
Here's a `Gemfile` example for a Rails application.

    gem "trailblazer"
    gem "trailblazer-rails"

    # optional, in case you want Cells.
    gem "trailblazer-cells"
    gem "cells-erb"         # Or cells-haml, cells-slim, cells-hamlit.
    gem "cells-rails"

This will also load `reform` and `reform-rails` making the integration very smooth.

~~Ruby
Here's a sample `Gemfile` for a non-Rails project that doesn't use `Active*`.

    gem "trailblazer"
    gem "trailblazer-loader" # optional, if you want us to load your concepts.

    gem "reform", ">= 2.2.0"
    gem "dry-validation", ">= 0.8.0"

    # optional, in case you want Cells.
    gem "trailblazer-cells"
    gem "cells-erb"         # Or cells-haml, cells-slim, cells-hamlit.

Note that you need to invoke the loader manually. Usually, this would happen in an initializer.


    Trailblazer::Loader.new.(concepts_root: "./concepts/") do |file|
      require_relative(file)
    end

{% endtabs %}


## Configuration

You can configure what validation engine you want to use.

{% tabs %}
~~Rails
In Rails, use an initializer, e.g. `config/initializer/trailblazer.rb` for that.

    Rails.application.config.reform.validations = :dry

If omitted, `ActiveModel::Validations` will be configured, per default.
~~Ruby

To set the default validation engine, it's easiest to monkey-patch Reform itself.

    Reform::Form.send(:feature, Reform::Form::ActiveModel::Validations)

For `dry-validations`:

    Reform::Form.send(:feature, Reform::Form::Dry)

Simply for a matter of readability, this should be done before you start defining forms.

{% endtabs %}

Note that you can still use alternative validations per form class.
