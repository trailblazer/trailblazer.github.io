---
layout: default
---

# Operation API

## The `params` Hash

Wherever `params` is referenced, think of an input hash in terms of the `params` hash in a controller.

## Operation



Get the form object.

{% highlight ruby %}
form = Thing::Create.present(params).contract
{% endhighlight %}


## Validate

validate(params) do
  # .. valid
end

if validate(params)
  # .. valid
else
  # ..
end