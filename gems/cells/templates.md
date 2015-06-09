---
layout: default
---

# Template Engines

Cells supports various template engines.

# ERB

# Haml

# Slim

# Your Own

Theoretically, you can use any template engine supported by Tilt.

To activate it in a cell, you only need to override `#template_options_for`.

{% highlight ruby %}
class SongCell < Cell::ViewModel
  def template_options_for(options)
    {
      template_class: Tilt, # or Your::Template.
      suffix:         "your"
  }
  end
{% endhighlight %}

This will use `Tilt` to instantiate a template to be evaluated. The `:suffix` is needed for Cells when finding the view.