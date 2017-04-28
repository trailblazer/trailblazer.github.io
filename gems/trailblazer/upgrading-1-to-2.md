---
layout: operation2
title: Trailblazer-Compat
gems:
  - ["trailblazer-compat", "trailblazer/trailblazer-compat", "0.1"]
---

This gem provides a seamless-er™ upgrade from TRB 1.1 to 2.x.

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
gem "trailblazer-rails", ">= 1.0.0"
```

## Initialization

Compat gem ships with the [TRB 1.1 code in the `V1_1` namespace](https://github.com/trailblazer/trailblazer-compat/blob/master/lib/trailblazer/1.1/operation.rb). It then loads the "real" TRB 2.x gem and [remaps the constants](https://github.com/trailblazer/trailblazer-compat/blob/master/lib/trailblazer/compat.rb#L38).

* The `V1_1` namespace becomes the official `Trailblazer::Operation` one.
* Code from 2.x is pushed into the `V2` namespace and can be accessed using `Trailblazer::Operation.version(2)`.

All your 1.1 legacy code can now be run in parallel to 2.x operations and workflows - you can upgrade old code and introduce the new semantics as you go. Please note that this does not slow down any runtime execution and mustn't be considered "dirty".

## Upgrade Path / Overview

Theoretically, you don't have to touch any 1.1 code at all.

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

In TRB2, step macros can do a lot of work for you. This used to be implemented in an overly complicated nested chain of methods. Macros simply return a callable object to be inserted into the railway.

```ruby
step Contract::Build( constant: Form::Create ) # used to happen in #validate
```

Do not forget to add parenthesis even when there are no options.

```ruby
step Contract::Validate( )
```

Always remember, calling a macro is calling a function that **returns a callable object** at compile-time.

## Model

The `Model( )` macro replaces `model Song, :create|:find`. Make sure to change `:create` to `:new` as in 2.x, the action is simply passed on to ActiveRecord (or any other ORM).

## Development Status

The `compat` gem tries to make the transition to newer versions as painless as possible. However, if you run into any problems specific to your application, please [don't hesitate to contact us](https://gitter.im/trailblazer/chat). Pull requests (even ugly hacks) are appreciated in this gem, and this gem only.
