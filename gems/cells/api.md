---
layout: default
---


### Call

The `#call` method also accepts a block and yields `self` (the cell instance) to it. This is extremely helpful for using `content_for` outside of the cell.

```ruby
  = cell(:song, Song.last).call(:show) do |cell|
    content_for :footer, cell.footer
```

Note how the block is run in the global view's context, allowing you to use global helpers like `content_for`.

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