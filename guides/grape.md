---
layout: guide
title: "Grape and Trailblazer"
---

# Grape and Trailblazer

A sample application can be found [on Github](https://github.com/apotonick/gemgem-grape).

## Summary

As Trailblazer provides `Operation` to encapsulate the business logic, and representers for rendering and parsing documents, Grape ends up being leveraged as a routing layer that dispatches to operations.

```ruby
module API
  class Application < Grape::API
    format :json

    version :v1 do
      get("posts")  { run!(Post::Show, request) }
      post("posts") { run!(Post::Create, request) }
    end
  end
end
```

## Routing

Using Grape's popular routing DSL, routes point straigt to operations and pass in the request body as a hash.



## Validation

Grape comes with built-in [parameter validation](https://github.com/ruby-grape/grape#parameter-validation-and-coercion) and deserialization mechanics. Both are, nevertheless, very limited and a subset of what Trailblazer's contract and representer provide. With Trailblazer, there's no need to use those parts of Grape - even though you could if you want.


