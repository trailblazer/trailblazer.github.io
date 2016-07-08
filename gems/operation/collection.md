---
layout: operation
title: "Operation Collection"
---

# Collections

Operations can also be used to present collections. This is often used in `Index` operations.


	class Comment::Index < Trailblazer::Operation
	  include Collection

	  def model!(params)
	    Comment.all
	  end
	end


You include the `Collection` module and override `#model!` to aggregate the collection of objects.

This operation won't need a contract, as it is presentation, only.

## Presenting Collections

You can instantiate the collection operation manually.

	op = Comment::Index.present(params)
	op.model #=> [<Comment>, ..]

Or use the `present` controller helper.

```ruby
def index
  present Comment::Index
end
```

This will set the `@model` instance variable to your collection.

## Pagination

## Scoping
