---
layout: default
---

# Rendering

## View Paths

Every cell class can have multiple view paths. However, I advise you not to have more than two, better one, unless you're imlementing a cell in an engine. This is simply to prevent unexpected behavior.

View paths are set via the `::view_paths` method.

{% highlight ruby %}
class Cell::ViewModel
  self.view_paths = ["app/cells"]
{% endhighlight %}

Use the setter to override the view paths entirely, or append as follows.

{% highlight ruby %}
class Shopify::CartCell
  self.view_paths << "/var/shopify/app/cells"
{% endhighlight %}

The `view_paths` variable is an inheritable array.

A trick to quickly find out about the directory lookup list is to inspect the `::prefixes` class method of your particular cell.

{% highlight ruby %}
puts Shopify::CartCell.prefixes
#=> ["app/cells/shopify/cart", "/var/shopify/app/cells/shopify/cart"]
{% endhighlight %}

This is the authorative list when finding templates. It will include inherited cell's directories as well when you used inheritance. The list is traversed from left to right.

## Partials

Even considered a taboo, you may render global partials from Cells.

{% highlight ruby %}
SongCell < Cell::ViewModel
  include Partial

  def show
    render partial: "../views/shared/sidebar.html"
  end
{% endhighlight %}

Make sure to use the `:partial` option and specify a path relative to the cell's view path. Cells will automatically add the format and the terrible underscore, resulting in `"../views/shared/_sidebar.html.erb"`.