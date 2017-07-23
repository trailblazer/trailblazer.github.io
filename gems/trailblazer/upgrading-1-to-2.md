---
layout: operation2
title: Upgrading 1.1 to 2.0
gems:
  - ["trailblazer-compat", "trailblazer/trailblazer-compat", "0.1"]
---

The `trailblazer-compat` gem provides a seamless-er™ upgrade from TRB 1.1 to 2.x.

It allows to run both old TRB 1.1 operations along with new or refactored 2.x code in the same application, making it easier to upgrade operation code `step`-wise (no pun intended!) or add new TRB2 operations, workflows, etc. without having to change the old code.

{% callout %}
With the release of TRB2, the API has become incredibly flexible and we promise you LTS (long-term support) for Trailblazer 2.x projects. Another hard upgrade is not to be expected.

Instead, semantical changes will be introduced as completely optional API.
{% endcallout %}

## Installation

Your exisiting application's `Gemfile` should point to the new `trailblazer` gem.

```ruby
gem "trailblazer", ">= 2.0.4"
gem "trailblazer-compat"
```

In a Rails application, you also need to pull the 1.x line of the `trailblazer-rails` gem.

```ruby
gem "trailblazer-rails", ">= 1.0.3"
```

## Initialization

Compat gem ships with the [TRB 1.1 code in the `V1_1` namespace](https://github.com/trailblazer/trailblazer-compat/blob/master/lib/trailblazer/1.1/operation.rb). It then loads the "real" TRB 2.x gem and [remaps the constants](https://github.com/trailblazer/trailblazer-compat/blob/master/lib/trailblazer/compat.rb#L38).

* The `V1_1` namespace becomes the official `Trailblazer::Operation` one.
* Code from 2.x is pushed into the `V2` namespace and can be accessed using `Trailblazer::Operation.version(2)`.

All your 1.1 legacy code can now be run in parallel to 2.x operations and workflows - you can upgrade old code and introduce the new semantics as you go. Please note that this does not slow down any runtime execution and mustn't be considered "dirty".

## Upgrade Path

Theoretically, you don't have to touch any 1.1 code at all. The file structure is identical and all abstractions from 1.1 still exist (except for `Builder`). Only the internals of `Operation` have changed: you now structure your business code into steps on a "railway".

1. You can keep old TRB1 operations.

   ```ruby
   # /app/concepts/song/create.rb
   class Song
     class Create < Trailblazer::Operation
       model Song, :create
       policy Song::Policy, :admin?

       contract do
         property :id
         # ...
       end

       def process(params)
         validate(params[:song]) do |form|
           form.save
         end
       end
     end
   end
   ```

2. At any point, you can introduce new TRB2 operations or update old classes by inheriting from `Trailblazer::Operation.version(2)`.

   ```ruby
   # /app/concepts/song/create.rb
   class Song
     class Create < Trailblazer::Operation.version(2)
       class Form < Reform::Form
         property :id
         # ...
       end

       class Present < Trailblazer::Operation.version(2)
         step Model( Song, :new )
         step Policy::Pundit( Song::Policy, :admin? )
         step Contract::Build( constant: Form )
       end

       step Nested(Present)
       step Contract::Validate( key: :admin )
       step Contract::Persist()
     end
   end
   ```

3. Should you ever be finished updating your application, simply remove the `trailblazer-compat` gem from the `Gemfile`. You can then safely delete `.version(2)` across all files.

## Macros

In TRB2, [step macros](/gems/operation/2.0/api.html#macro-api) can do a lot of work for you. This used to be implemented in an overly complicated nested chain of methods. Macros simply return a callable object to be inserted into the railway.

```ruby
step Contract::Build( constant: Form::Create ) # used to happen in #validate
```

Do not forget to add parenthesis even when there are no options.

```ruby
step Contract::Validate( )
```

Always remember, calling a macro is calling a function that **returns a callable object** at compile-time.

## Model

The [`Model( )` macro](/gems/operation/2.0/api.html#model) replaces `model Song, :create|:find`.

Make sure to change `:create` to `:new` as in 2.x, the action is simply passed on to ActiveRecord (or any other ORM).

```ruby
step Model( Song, :new )
```

## Present / Form

In TRB2, there are no `#present` and `#form` anymore. You can only `run` an operation.

```ruby
class SongsController < ApplicationController
  def create
    run Song::Create
  end
end
```

You now need to write [dedicated presentation operations](/guides/trailblazer/2.0/03-rails-basics.html#nested) for both `present` and `form`.

What used to be one big operation with two or even three confusing "modes" are now two separate operations that are combined via `Nested`.

    class BlogPost::Create < Trailblazer::Operation
      class Present < Trailblazer::Operation
        # steps to setup model and contract
        step Model(BlogPost, :new)
        step Contract::Build( constant: BlogPost::Contract::Create )
      end

      # code for the Create/Update/..
      step Nested( Present )
      step Contract::Validate( )
      step Contract::Persist( )
      # ..
    end

Be wary to run the correct operation for the respective controller action.

```ruby
class SongsController < ApplicationController
  def show
    run Song::Create::Present # gives you @model and @form.
  end

  def create
    run Song::Create          # gives you @model and @form, too!
  end
end
```

## Controller

In 1.1, you mutated `params` in the controller to inject additional dependencies. This is now done via the second optional argument to `Operation::call`. You have [several options to hook into](/gems/trailblazer/2.0/rails.html#runtime-options) how those arguments are created in the controller.

What used to be the following snippet..

    class ApplicationController < ActionController::Base
      def process_params!(params)
        params.merge!(current_user: current_user)
      end
    end

.. now becomes something along the following.

    class ApplicationController < ActionController::Base
      def _run_options(options)
        options.merge("current_user" => current_user)
      end


## Test

In 1.1, this used to be a common pattern.

    op = AccountManager::Update.run(
      current_user: Admin.new,
      id: account_manager.id, account_manager: { email: "" }
    )

    expect(res).to be false
    expect(op.errors.to_s).to eq(..)

This would now look as follows.

    res = AccountManager::Update(
      { id: account_manager.id, account_manager: { email: "" } },
      current_user: Admin.new # this is a 2nd argument to #call.
    )

    expect(res).to be_failure
    expect(res["contract.default"].errors.to_s).to eq(..)


When testing, it was handy to have the `Operation::call` method throw an exception when run invalid. In 2.0, since only have `call`, there will never be any exception thrown.

Use `TestCase#run` to get back the exception-throwing behavior.

    RSpec.describe AccountManager::Update do
      let(:account_manager) do
        run(AccountManager::Create,
          {
            account_manager: {
              name: "Ad Min", email: "account_manager@example.com", password: '12345'
            }
          },
          "current_user" => Admin.new
        )
      end
    end

`run` in tests works exactly the way it does in controllers, except that it throws an error when the result is `failure?`.

## Builder

The `Operation::Builder` module doesn't exist anymore and should be done with `Nested`.

## Common Problems

* `NoMethodError: undefined method reforms_path' for` in cells or views: You have to [pass the `@form` instance](/gems/trailblazer/2.0/rails.html#run) to the cell, and not the `result["contract.default"]` reference. The latter one has not been wrapped to make it compatible with ActiveModel's insanity.

    Alternatively, use the [formular](/gems/formular) form builder.

## Development Status

The `compat` gem tries to make the transition to newer versions as painless as possible. However, if you run into any problems specific to your application, please [don't hesitate to contact us](https://gitter.im/trailblazer/chat). Pull requests (even ugly hacks) are appreciated in this gem, and this gem only.
