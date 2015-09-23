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