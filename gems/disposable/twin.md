---
layout: default
permalink: /gems/disposable/twin/
---

# Twin

{% highlight ruby %}
class Song::Twin < Disposable::Twin
  property :title
end
{% endhighlight %}

A twin decorates objects. It doesn't matter whether this is an ActiveRecord instance, a ROM model or a PORO.

{% highlight ruby %}
song = OpenStruct.new(title: "Solitaire")
song.title #=> "Solitaire"
{% endhighlight %}

## API

Initialization always requires an object to twin.

{% highlight ruby %}
twin = Song::Twin.new(song)
{% endhighlight %}

The twin will have configured accessors.

{% highlight ruby %}
twin.title #=> "Solitaire"
{% endhighlight %}

Writers on the twin do not write to the model.

{% highlight ruby %}
twin.title = "Razorblade"
song.title #=> "Solitaire"
{% endhighlight %}

You may pass options into the initializer. These options will override the actual values from the model. As always, this does not write to the model.

{% highlight ruby %}
twin = Song::Twin.new(song, title: "Razorblade")
twin.title #=> "Razorblade"
song.title #=> "Solitaire"
{% endhighlight %}

## Twin::Option

Allows to specify external options.

{% highlight ruby %}
class Song < Disposable::Twin
  property :title
  option :good?
end
{% endhighlight %}

Options are _not read_ from the model, they have to be passed in the constructor. When omitted, they default to `nil`.

{% highlight ruby %}
song = Song.new(model, good?: true)
{% endhighlight %}

As always, option properties are readable on the twin.

{% highlight ruby %}
song.good? #=> true
{% endhighlight %}

When syncing, the option property is treated as not writeable and thus not written to the model.