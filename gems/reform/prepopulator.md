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
  property :title, prepopulator: ->(options) { self.title = options[:def_title] }

  property :artist, prepopulator: prepopulate_artist! do
    property :name
  end

private
  def prepopulate_artist!(options)
    self.artist = Artist.new
  end
end
{% endhighlight %}

As `:prepopulator` option, you can pass lambdas or symbols which will resolve to instance methods.

Prepopulators have the following signature:

{% highlight ruby %}
(options)
{% endhighlight %}

* `options` are the arguments passed to the `prepopulate!` call.


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

The blocks are run in form instance context, meaning you have access to all possible data you might need. With a symbol, the same-named method will be called on the form instance, too.

Note that you have to assign the pre-populated values to the form by using setters. In turn, the form will automatically create nested forms for you.

This is especially cool when populating collections.

{% highlight ruby %}
property :songs,
  prepopulator: ->(*) { self.songs << Song.new if songs.size < 3 } do
{% endhighlight %}

This will always add an empty song form to the nested `songs` collection until three songs are attached. You can use the `Twin::Collection` [API](/gems/disposable/collection.html) when adding, changing or deleting items from a collection.

Note that when calling `#prepopulate!`, your `:prepopulate` code for all existing forms in the graph will _be executed_ . It is up to you to add checks if you need that.

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
2. Override the reader of the property. This is not recommended as you might screw things up. Remember that the property reader is called for presentation (in the form builder) and for validation in `#validate`.

{% highlight ruby %}
property :title

def title
  super or "Unnamed"
end
{% endhighlight %}
