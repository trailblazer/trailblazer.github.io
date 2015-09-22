---
layout: default
---

## Initialize

Normally, you instantiate cells with the `concept` or `cell` helper.

{% highlight ruby %}
cell = concept("comment/cell", comment)
{% endhighlight %}

This gives you the cell instance. Although not encouraged, you could call multiple methods on it.

{% highlight ruby %}
cell.(:show)
cell.(:javascript)
{% endhighlight %}

Normally, you will want to run the `show` method, only. In controller views, this will be called automatically. However, you could do that manually as follows.

## Call

{% highlight ruby %}
concept("comment/cell", comment).(:show)
{% endhighlight %}

Always invoke cell methods via `call`. This will ensure that caching - if configured - is performed properly.


The `#call` method also accepts a block and yields `self` (the cell instance) to it. This is extremely helpful for using `content_for` outside of the cell.

```ruby
  = cell(:song, Song.last).call(:show) do |cell|
    content_for :footer, cell.footer
```

Note how the block is run in the global view's context, allowing you to use global helpers like `content_for`.

## Options

A cell can wrap more than one model. This can be handy to pass in additional data you need for presentation.

{% highlight ruby %}
concept("comment/cell", comment, admin: true)
{% endhighlight %}

Inside the cell, the additional options are available via `#options`.

{% highlight ruby %}
class Comment::Cell < Cell::ViewModel
  def show
    return render :admin if options[:admin]
    render
  end
{% endhighlight %}



Class.()

Class.build (no def args)

ViewModel::cell()






## HTML Escaping

Cells per default does no HTML escaping, anywhere. This is one of the reasons that makes Cells faster than Rails.

Include `Escaped` to make property readers return escaped strings.

{% highlight ruby %}
class CommentCell < Cell::ViewModel
  include Escaped
  property :title
end

song.title                 #=> "<script>Dangerous</script>"
Comment::Cell.(song).title #=> &lt;script&gt;Dangerous&lt;/script&gt;
{% endhighlight %}

Only strings will be escaped via the property reader.

You can suppress escaping manually.

{% highlight ruby %}
def raw_title
  "#{title(escape: false)} on the edge!"
end
{% endhighlight %}

Of course, this works in views, too.

{% highlight erb %}
<%= title(escape: false) %>
{% endhighlight %}






## AV

clean encap, no global access, interfaces


## Nesting


# Collections

This will instantiate each collection cell as follows.

```ruby
Comment.(comment, style: "awesome", volume: "loud")
```