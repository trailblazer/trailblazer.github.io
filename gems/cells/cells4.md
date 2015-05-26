---
layout: default
---

# Cells 4

## No ActionView

Starting with Cells 4.0 we no longer use ActionView as a template engine. Removing this jurassic dependency cuts down Cells' rendering code to less than 50 lines and improves rendering speed by 300%!

We rely on the excellent Tilt library for rendering templates.

# Pitfalls

## HTML Escaping

Cells per default does _not_ escape HTML. However, you may run into problems when using Rails helpers. Internally, those helpers often blindly escape. This is not Cells' fault but a design flaw in Rails.

Everything related to `#capture` will cause problems - check [this as an example](https://github.com/rails/rails/blob/8469d2f759fcc8644b9bb7fa326dfa62d956992b/actionview/lib/action_view/helpers/capture_helper.rb#L40). As you can see, this is Rails swinging the escape hammer. Please don't blame us for escapes where they shouldn't be. Rather open an issue on Rails and tell them to make their code better overrideable for us.

1. As a first step, try this and see if it helps.

{% highlight ruby %}
class SongCell < Cell::ViewModel
  include ActionView::Helpers::FormHelper
  include Cell::Erb # include Erb _after_ AV helpers.

  # ..
end
{% endhighlight %}

The same goes for HAML cells, by including `Cell::Haml`.

2. If that doesn't work, play around with `#html_safe` on the strings you generate. We know, this sucks, but this is not our fault.
3. You can also deep-dive into the Rails helpers and try to patch there. Since Rails 4, the helpers are cleaned up and much better implemented than in 3.x.
4. If you're still having problems, open an issue on [cells-erb](https://github.com/trailblazer/cells-erb/issues) or [cells-haml](https://github.com/trailblazer/cells-erb/issues).