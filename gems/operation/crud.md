---
layout: default
---

# Operation::CRUD

Including `CRUD` will add simple CRUD semantics to your operation.

{% highlight ruby %}
class Create < Trailblazer::Operation
  include CRUD
  model Thing, :create
{% endhighlight %}

Using the `::model` method you _have to_ define what model the operation will work with. The second argument specifies the action.

This will override `model!` and automatically create a new `Thing` model for you when the operation is run.

## Actions

The following actions are available.

* `:create`
* `:update` or `:find`: will execute `Thing.find(params[:id])`

In `process`, you now have a new or existing `model` available.

## Validation

In `validate`, you don't need to provide the model anymore.

```ruby
def process(params)
  validate(params[:thing]) do
```

## Discussion

Note that this is really simple behavior. Do not use this module when you plan to use more complex models.
