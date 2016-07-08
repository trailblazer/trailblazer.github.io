---
layout: representable
title: "Representable Upgrading Guide"
---

# Upgrading Guide

We try to make upgrading as smooth as possible. Here's the generic documentation, but don't hesitate to ask for [help on Gitter](https://gitter.im/trailblazer/chat).

## 2.4 to 3.0

* The 3.0 line runs with Ruby >2.0, only. This is to make extensive use of keyword arguments.
* All deprecations from 2.4 have been removed.

to_hash(user_options: {})
->(options) { options[:user_options] }
->(user_options:,**) { user_options }

## 2.3 to 2.4

The 2.4 line contains many new features and got a major internal restructuring. It is a transitional release with deprecations for all changes.

### Breakage

    :render_filter => lambda { |val, options| "#{val.upcase},#{options[:doc]},#{options[:options][:user_options]}" }


### Deprecations

Once your code is migrated to 2.4, you should upgrade to 3.0, which does _not_ have deprecations anymore and only supports Ruby 2.0 and higher.

If you can't upgrade to 3.0, you can disable slow and annoying deprecations as follows.

    Representable.deprecations = false

### Positional Arguments

For dynamic options like `:instance` or `:getter` we used to expose a positional API like `instance: ->(fragment, options)` where every option has a slightly different signature. Even worse, for `collection`s this would result in a differing signature plus an index like `instance: ->(fragment, index, options)`.

From Representable 2.4 onwards, only one argument is passed in for all options with an identical, easily memoizable API. Note that the old signatures will print deprecation warnings, but still work.

For parsing, this is as follows (`:instance` is just an example).

{% highlight ruby %}
property :artist, instance: ->(options) do
  options[:input]
  options[:fragment] # the parsed fragment
  options[:doc]      # the entire document
  options[:result]   # whatever the former function returned,
                     # usually this is the deserialized object.
  options[:user_options] # options passed into the parse method (e.g. from_json).
  options[:index]    # index of the currently iterated fragment (only with collection)
end
{% endhighlight %}

We highly recommend to use keyword arguments if you're using Ruby 2.1+.

{% highlight ruby %}
property :artist, instance: ->(fragment:, user_options:, **) do
{% endhighlight %}

### User Options

When passing dynamic options to `to_hash`/`from_hash` and friends, in older version you were allowed to pass in the options directly.

    decorator.to_hash(is_admin: true)

This is deprecated. You now have to use the `:user_options` key to make it compatible with library options.

    decorator.to_hash(user_options: { is_admin: true })

### Pass Options

The `:pass_options` option is deprecated and you should simply remove it, even though it still works in < 3.0. You have access to all the environmental object via `options[:binding]`.

In older version, you might have done as follows.

{% highlight ruby %}
property :artist, pass_options: true,
  instance: ->(fragment, options) { options.represented }
{% endhighlight %}

Runtime information such as `represented` or `decorator` is now available via the generic options.

{% highlight ruby %}
property :artist, instance: ->(options) do
  options[:binding]              # property Binding instance.
  options[:binding].represented  # the represented object
  options[:user_options]         # options from user.
end
{% endhighlight %}

The same with keyword arguments.

{% highlight ruby %}
property :artist, instance: ->(binding:, user_options:, **) do
  binding.represented  # the represented object
end
{% endhighlight %}

### Parse Strategy

The `:parse_strategy` option is deprecated in favor of `:populator`. Please replace all occurrences with the new populator style to stay cool.

If you used a `:class` proc with `:parse_strategy`, the new API is `class: ->(options)`. It used to be `class: ->(fragment, user_options)`.

### Class and Instance

In older versions you could use `:class` and `:instance` in combination, which resulted in hard-to-follow behavior. These options work exlusively now.

### SkipRender

skip_render: lambda { |options|
# raise options[:represented].inspect
        options[:user_options][:skip?] and options[:input].name == "Rancid"

### Binding

The `:binding` option is deprecated and will be removed in 3.0. You can use your own pipeline and replace the `WriteFragment` function with your own.