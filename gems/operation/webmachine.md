---
layout: default
---

# Webmachine

Operations and representers work nicely within Webmachine.

## API

The modular API of operation allows to split _model-finding_ and _operation-building_. This fits perfectly into the Webmachine flow.

{% highlight ruby %}
def resource_exists?
  Comment::Create.model!(params)
end

def update # beth, please a link to that code, again
  Comment::Create.(params, model: resource)
end
{% endhighlight %}

Model is only queried once and then passed into the operation builder/run.