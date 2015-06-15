---
layout: default
---

# Collections

Operations can also be used to present collections. This is often used in `Index` operations.

{% highlight ruby %}
class Comment::Index < Trailblazer::Operation
  include Collection

  def model!(params)
    Comment.all
  end
end
{% endhighlight %}

You include the `Collection` module and override `#model!` to aggregate the collection of objects.

This operation won't need a contract, as it is presentation, only.

## Presenting Collections

You can either instantiate the collection operation manually.

{% highlight ruby %}
op = Comment::Index.present(params)
op.model #=> [<Comment>, ..]
{% endhighlight %}

Or you can use the `Controller#collection` helper to do that in the controller.

{% highlight ruby %}
class CommentsController < ApplicationController
  def index
    collection Comment::Index
  end
{% endhighlight %}

This will set the `@collection` instance variable.


## Pagination

## Scoping