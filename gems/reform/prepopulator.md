---
layout: default
permalink: /gems/reform/prepopulator.html
---

# Pre-Populating

Prepopulating is helpful when you want to fill out fields (aka. _defaults_) or add nested forms before rendering.

## Configuration

You can use the `:prepopulator` option on every property or collection.

{% highlight ruby %}
class AlbumForm < Reform::Form
  property :title, prepopulator: ->(options) { self.title = options.user_options[:def_title] }

  property :artist, prepopulator: ->(options) { self.artist = Artist.new } do
    property :name
  end
end
{% endhighlight %}

Prepopulators have the following signature:

{% highlight ruby %}
->(options)
{% endhighlight %}

* `options` is an Options instance. Interesting to you might mostly be `options.user_options`, which are the user options from the `prepopulate!` call.


## Invoking

Prepopulating must be invoked manually.

{% highlight ruby %}
form.prepopulate!
{% endhighlight %}

Options may be passed. They will be available in the `:prepopulator` blocks.

{% highlight ruby %}
form.prepopulate!(def_title: "Roxanne")
{% endhighlight %}

This call will be applied to the entire nested form graph recursively _after_ the currently traversed form's prepopulators were run.


## Execution

The blocks are run in form instance context, meaning you have access to all possible data you might need.

Note that you have to assign the pre-populated values to the form by using setters. The form will automatically create nested forms for you.

This is especially cool when populating collections.

{% highlight ruby %}
property :songs,
  prepopulator: ->(*) { self.songs << Song.new if songs.size < 3 } do
{% endhighlight %}

This will always add an empty song form to the nested `songs` collection until three songs are attached. You can use the `Twin::Collection` API when adding, changing or deleting items from a collection. (# TODO: add link)


## Overriding

You don't have to use the `:prepopulator` option. Instead, you can simply override `#prepopulate!` itself.

{% highlight ruby %}
class AlbumForm < Reform::Form
  def prepopulate!(options)
    self.title = "Roxanne"
    self.artist = Artist.new(name: "The Police")
  end
{% endhighlight %}


# Defaults

There's different alternatives for setting a default value for a formerly empty field.

1. Use `:prepopulator` as [described here](#configuration). Don't forget to call `prepopulate!` before rendering the form.
2. Override the reader of the property. This is not recommended as you might screw things up. Remember that the property reader is called for presentation (in the form builder), for validation and when syncing.

{% highlight ruby %}
property :title

def title
  super or "Unnamed"
end
{% endhighlight %}
