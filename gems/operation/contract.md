---
layout: operation
title: "Operation: Contract"
---

# Operation: Contract

The operation's contract is one of the pivotal elements in Trailblazer. It integrates the deserialization and validation into your service object.

[DOCS STILL UNDER CONSTRUCTION]

## Composition

Contracts don't have to map to one model, only.

If your contract embraces several models using `Composition`, you can easily pass the composition hash via `validate`. Note that composition is a [Reform feature](/gems/reform/#composition). Do not forget the `on:` option when defining your compositional mapping.

```ruby
class Create < Trailblazer::Operation
  contract do
    include Reform::Form::Composition

    property :id,   on: :comment
    property :name, on: :author
  end

  def process(params)
    comment = Comment.find(params[:id])
    author  = comment.author

    validate(params, comment: comment, author: author)
  end
end
```

The second argument to `validate` is the contract's model. As per Reform's API, for compositions this must be a hash.

## Injection

It is possible to inject additional dependencies into the contract, which are not part of the original model(s). This often is a `current_user` or the operation instance itself.

Those dependencies have to be virtual properties in the contract. They can then be passed as the third argument to `validate`.

```ruby
class Create < Trailblazer::Operation
  contract do
    property :current_user, virtual: true
    property :operation,    virtual: true
  end

  def process(params)
    validate(params, model,
      current_user: params[:current_user],
      operation:    self) do |f|

    end
  end
end
```

The same semantics apply to `contract`.

## contract! Method

To automate injection or composition, you can override `Operation#contract!`.

```ruby
class Create < Trailblazer::Operation

private
  def contract!(model, options, contract_class)
    contract_class.new(model, current_user: @current_user)
  end
```
