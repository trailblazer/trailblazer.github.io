---
layout: default
---

# Engine Cells

You can bundle cells into Rails engines and maximize a clean, component architecture by making your view models easily distributable and overridable.

This pretty much works out-of-the-box, you write cells and push them into an engine. The only thing differing is that engine cells have to set their `view_paths` manually to point to the gem directory.

## View Paths

Each engine cell has to set its `view_paths`.

The easiest way is to do this in a base cell in your engine.

{% highlight ruby %}
module MyEngine
  class Cell < Cell::Concept
    view_paths = ["#{MyEngine::Engine.root}/app/concepts"]
  end
end
{% endhighlight %}

The `view_paths` is inherited, you only have to define it once when using inheritance within your engine.

{% highlight ruby %}
module MyEngine
  class Song::Cell < Cell # inherits from MyEngine::Cell
{% endhighlight %}

This will _not_ allow overriding views of this engine cell in `app/cells` as it is not part of the engine cell's `view_paths`. When rendering `MyEngine::User::Cell` or a subclass, it will _not_ look in `app/cells`.

To achieve just that, you may append the engine's view path instead of overwriting it.

{% highlight ruby %}
class MyEngine::User::Cell < Cell::Concept
  view_paths << "#{MyEngine::Engine.root}/app/concepts"
end
{% endhighlight %}


## Render problems

You might have to include cells' template gem into your **application's** `Gemfile`. This will properly require the extension.

{% highlight ruby %}
# application Gemfile
gem "cells-erb"
{% endhighlight %}
