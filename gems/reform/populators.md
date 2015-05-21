---
layout: default
permalink: /gems/reform/populators.html
---

# Reform: Populators

...

## :populate_if_empty

{% highlight ruby %}
populate_if_empty: ->(params, *) { User.find_by_email(params["email"]) or User.new },
{% endhighlight %}

### Signature

The result of the block will automatically assigned to the property or collection for you. Note that you can't use Twin API in here. If you want to do fancy stuff, use `:populator`.

You do NOT have access to the entire Collection api (NO WE DO HAVE, VERIFY! )

## Internals

`:populator` options are called via the `:instance` hook in the deserializer. They disable `:setter`, hence you have to set newly created twins yourself.

(how models automatically become twinned when assigning)


