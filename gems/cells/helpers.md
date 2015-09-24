---
layout: default
---

# Helpers

Conceptually, Cells doesn't have helpers anymore. You can still include modules to import utility methods but they won't get copied to the view. In fact, the view is evaluated in the cell instance context and hence you can simply call instance methods in the template files.

## Translation and I18N

You can use the `#t` helper.

{% highlight ruby %}
require "cell/translation"

class Admin::Comment::Cell < Cell::Concept
  include Cell::Translation

  def show
    t(".greeting")
  end
end
{% endhighlight %}

This will lookup the I18N path `admin.comment.greeting`.

Setting a differing translation path works with `::translation_path`.

{% highlight ruby %}
class Admin::Comment::Cell < Cell::Concept
  include Cell::Translation
  self.translation_path = "cell.admin"
{% endhighlight %}

The lookup will now be `cell.admin.greeting`.

## ImageTag

When using asset path helpers like `image_tag` that render different paths in production, please simply delegate to the controller.

{% highlight ruby %}
class Comment::Cell < Cell::Concept
  delegates :parent_controller, :image_tag
{% endhighlight %}

It is a [well-known problem](https://github.com/apotonick/cells/issues/214) that the cell will render the "wrong" path when using Sprockets. The above delegation fixes this. Please note that this is due to the way Rails includes helpers and accesses global data.