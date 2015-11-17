---
layout: default
title: "Representable Upgrading Guide"
---

# Upgrading Guide

We try to make upgrading as smooth as possible. Here's the generic documentation, but don't hesitate to ask for [help on Gitter](https://gitter.im/trailblazer/chat).

## 2.3 to 2.4

### Deprecations

Once you code is migrated to 2.4, you can disable slow and annoying deprecations as follows.

    Representable.deprecations = false

### Positional Arguments

For dynamic options like `:instance` or `:getter` we used to expose a positional API like `instance: ->(fragment, options)` where every option has a slightly different signature. Even worse, for `collection`s this would result in a differing signature plus an index like `instance: ->(fragment, index, options)`.

From Representable 2.4 onwards, only one argument is passed in for all options with an identical, easily memoizable API. Note that the old signatures will print deprecation warnings, but still work.

For parsing, this is as follows (`:instance` is just an example).

{% highlight ruby %}
property :artist, instance: ->(options) do
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