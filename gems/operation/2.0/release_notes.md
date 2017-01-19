---
layout: operation
title: "Trailblazer 2.0 - What's New?"
---

Please find the complete list of [changes here](https://github.com/trailblazer/trailblazer/blob/master/CHANGES.md#200).

The estimated release date is November 25. 2016, that is. 😜

## Installation / Structure

**We will provide installation instructions as soon as the code is presentable.**

The core logic has been extracted to the [`trailblazer-operation` gem](https://github.com/trailblazer/operation/) that can be used even if you dislike Trailblazer's semantics. But, why would you?

Additional functionality like `Contract`, `Policy`, etc. comes in the [`trailblazer` gem](https://github.com/trailblazer/trailblazer/).

You now have to include the respective modules to extend the operation for contract, callbacks, and so on.


## Call

There's only one way to invoke an operation now: `Operation::call`. You can't instantiate using `::new` and `::run` was removed. All exceptions have been removed; `call` will never throw anything unless your code is seriously broken. Instead, `call` will  return the [result object](#result-object).

In Trailblazer 1.x we defined an operation's behavior by overriding `#process`. This has been removed; operations are now defined by a new DSL using the `step` and `failure` methods:

```ruby
class Song::Create < Trailblazer::Operation
  step    Model( Song, :new )
  step    :assign_current_user!
  step    Contract::Build( constant: MyContract )
  step    Contract::Validate()
  failure :log_error!
  step    Contract::Persist()

  def log_error!(options)
    # ..
  end

  def assign_current_user!(options)
    options["model"].created_by =
    options["current_user"]
  end
end
```

For more information, see the [guide to the new Operation API](/gems/operation/2.0/api.html).

## Params and Dependencies

You no longer merge dependencies such as the current user into `params`, you can pass an arbitrary list of containers or hashes to `call`, after the `params` hash.

`params` is treated as immutable unless *you want to* mess around with it.

```ruby
params = { id: 1 }

Create.(params, "user.current" => Object) # just an example for the current user
```

Any dependency passed into the operation is called *skill*. Skills, or dependencies, can be accessed via `#[]`.

```ruby
class Create < Trailblazer::Operation
  def process(params)
    puts self["user.current"]
  end
end

Create.(params, "user.current" => Object) #=> "Object"
```

## Skills

The way Trailblazer 2.0 manages dependencies is extremely simple implemented and also a pleasure to use. You can assign any skill on class level you want. Note that for skills we always use string names (because we can segment them).

```ruby
class Create < Trailblazer::Operation
  self["contract.params.class"] = MyContract
end

Create["contract.params.class"] #=> MyContract
```

In `call`, run-time dependencies such as the current user and class skills are made available via `#[]`.

```ruby
class Create < Trailblazer::Operation
  self["contract.params.class"] = MyContract

  def process(params)
    puts self["contract.params.class"]
    puts self["user.current"]
  end
end

Create.({ id: 1}, "user.current" => Object)
#=> MyContract
#=> Object
```

You can also set skills on the instance level. This **won't override anything** on the class level or other containers and is disposed of after the operation instance is destroyed.

```ruby
class Create < Trailblazer::Operation
  def process(params)
    self["state"] = :created
  end
end
```

## Result Object

Per default, the `call` method returns a result object. Currently, this is simply the immutable *operation instance* (it's not really immutable, yet, but that's easily achievable).

That makes is super simple to read all kinds of states from it.

```ruby
Create.({})["state"]                 #=> :created
Create.({})["contract.params.class"] #=> MyContract
```


The API of the result object allows using it with simple conditionals. Note that this way you can expose any kind of information to the caller.

```ruby
result = Create.({})
if result["state"] == :created and result["valid"]
  redirect_to "/success/#{result["model"].id}"
elsif result["state"] == :updated and result["valid"]
  redirect_to "/news/#{result["model"].id}"
```


["model"]
["valid"]
["errors.contract"]


## Pattern Matching

You can also use [pattern matching](https://github.com/dry-rb/dry-matcher) with the result object.

This will help us implement generic endpoints (TO BE DOCUMENTED).

## Controller methods

TRB 1 [provided](http://trailblazer.to/gems/operation/1.1/controller.html) the controller methods `run`, `present`, `form`, and `respond` for running and/or presenting an operation. In TRB 2 these have all been removed except `run`, and `run` has been moved to the [trailblazer-rails](https://github.com/trailblazer/trailblazer-rails) gem. For more information see the [guides for Trailblazer::Rails](http://trailblazer.to/gems/trailblazer/2.0/rails.html).

## Endpoint

## Dependency Injection

The operation uses the skill mechanism to manage all its dependencies, too, such as policies, contracts, representers, and so on.

```ruby
class Create < Trailblazer::Operation
  include Contract
  contract do
    property :id
  end

  puts self["contract.default.class"] #=> <Contract class we just defined...>
end
```

This allows to inject dependencies and thus override the skill configured on the class layer.

```ruby
result = Create.({ id: 1 }, "contract.default.class" => Module)
result["contract.default.class"] #=> Module, not the class-level value.
```

You can inject models, contract classes, policies, or whatever needs to get into the operation.

## Dry-container

The skill mechanics also support injecting [Dry::Container](https://github.com/dry-rb/dry-container) to provide additional (or all!) dependencies.

```ruby
my_container = Dry::Container.new
my_container.register("user_repository", -> { Object })

Create.({}, my_container)["user_repository"] #=> Object
```

That means that all kinds of dependencies, such as contracts or policies, can be managed by Dry's loading and container logic.

## Dry-validation Contract

Besides the fact that you now can have as many contracts as you need, Trailblazer also support [`Dry::Validation::Schema` contracts](http://dry-rb.org/gems/dry-validation/) instead of a full-blown Reform object.

This is helpful for simple, formal validations where you don't need deserialization, for example to validate some unrelated parts of the `params`
.

```ruby
class Create < Trailblazer::Operation
  include Contract

  contract "params", (Dry::Validation.Schema do
    required(:id).filled
  end)

  contract MyContract # the main contract
```

Now, have a look how to use those two contract.

```
  def process(params)
    validate(params, name: "params") do |f|
      puts "params have :id!" # done with dry-validation, without Reform!
    end

    validate(params) do |f|
      f.save # normal contract and behavior.
    end
  end
end
```

## Pipetree

Example with callbacks in pipeline.


## API Consistency

You might've noticed that APIs and object structures in Trailblazer frequently change and you might miss Rails' consistency already.

Please keep in mind that we change things to *help* you building better software. When we do Trailblazer consulting, we identify design flaws together with the teams we help, and build solutions.

Those solutions are shipped as fast as we can. And that might hurt sometimes. Nevertheless, we try to ease your pain with the `compat` gem, [upgrading help](/inc/help.html), and we're very confident that the 2.0 API is extremely stable and easily extended without breaking API changes.

## What's Next?

* Deserializer layer that can happen *before* validation, or whenever you want. This separate the deserialization/population from the actual validation and might make many people happy.
