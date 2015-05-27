# Twin

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