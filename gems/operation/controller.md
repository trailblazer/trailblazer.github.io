---
layout: default
---

# Controller

## Normalizing Params

Override #process_params! to add or remove values to params before the operation is run. This is called in #run, #respond and #present.

{% highlight ruby %}
class CommentsController < ApplicationController
private
  def process_params!(params)
    params.merge!(current_user: current_user)
  end
end
{% endhighlight %}

This centralizes params normalization and doesn't require you to do that in every action manually.