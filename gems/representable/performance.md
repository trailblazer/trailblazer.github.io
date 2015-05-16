---
layout: default
---

# Representable: Performance

Since Representable 2.2 we provide the feature `Representable::Cached` which boost up rendering and parsing speed by about 50%.

Instead of unnecessarily creating (sometimes thousands of) nested representers, bindings, and associated instances for every represented object, this is now cached. By making `Binding` instances stateless we can reuse it.

[Example]
Now, only one binding instance is used to render/parse the entire collection.


## Usage

As per Representable 2.2 this feature is still experimental. Nevertheless, we recommend using it. Note that caching **only works with decorators**.

{% highlight ruby %}
class AlbumRepresenter < Representable::Decorator
  include Representable::Hash
  feature Representable::Cached

  property :name

  collection :songs do
    property :title
  end
end
{% endhighlight %}

Inserting the module on the top-level representer via `feature Representable::Cached` will activate caching for all representers in the graph.

## Pitfalls

Using `Cached` currently hooks into the `Deserializer:#prepare` method. If you use `:prepare` to instantiate different representers per iteration, you might have problems with caching. I'll update this soon.

[Graph of caching hierarchy]
