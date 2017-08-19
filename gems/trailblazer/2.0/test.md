---
layout: operation2
title: Trailblazer Test
gems:
  - ["trailblazer-test", "trailblazer/trailblazer-test", "0.1"]
---

{% callout %}
**Note: This gem is not stable, yet.** It will be released in August 2017.
{% endcallout %}

The `trailblazer-test` gem provides a bunch of assertions, matchers and helpers for writing operation test.

## Operation Tests

In Trailblazer, you write operation and integration tests. Operations encapsulate all business logic and are single-entry points to operate your application. There's no need to test controllers, models, service objects, etc. in isolation - unless you want to do so for a better documentation of your internal APIs.

However, the idea of operation tests is: Run the complete unit with a certain input set, and test the side-effects. This differs to the Rails Way™ testing style, where smaller units of code, such as a specific validation or a callback, are tested in complete isolation. While that might look tempting and clean, it will create a test environment that is not identical to what happens in production.

In production, you will never trigger one specific callback or a particular validation, only. Your application will run all code required to create a `Song` object, for instance. In Trailblazer, this means running the `Song::Create` operation, and testing that very operation with all its side-effects.

Luckily, `trailblazer-test` provides a simple abstraction allowing to run operations and test all side-effects without creating verbose, unmaintable test code.

## assert_pass


Verbose, bad example:

    # every timestamp's unique.
    it { Expense::Create.(params_pass)["model"].created_at < Expense::Create.(params_pass)["model"].created_at }

Good, consistent example:

    it { assert_pass Expense::Create, {}, created_at: ->(actual:, **) { actual < Expense::Create.(params_pass)["model"].created_at } }


===> block for assert_pass/fail


## Generic Assertions

As always, the `model` represents any object with readers, such as a `Struct`, or an `ActiveRecord` instance.

```ruby
Song  = Struct.new(:title, :band)

model = Song.new("Timebomb", "Rancid")
model.title #=> "Timebomb"
model.band  #=> "Rancid"
```

## assert_exposes

Test attributes of an arbitrary object.

Pass a hash of key/value tuples to `assert_exposes` to test that all attributes of the asserted object match the provided values.

{{ "test/assertions_test.rb:exp-eq:../trailblazer-test:master" | tsnippet }}

Per default, this will read the values via `model.{key}` from the asserted object (`model`) and compare it to the expected values.

This is a short-cut for tests such as the following.

```ruby
assert_equal "Timebomb", model.title
assert_equal "Rancid",   model.band
```

Note that `assert_exposes` accepts any object with a reader interface.

### assert_exposes: reader

If the asserted object exposes a hash reader interface, use the `:reader` option.

{{ "test/assertions_test.rb:exp-reader-hash:../trailblazer-test:master" | tsnippet }}

This will read values with via `#[]`, e.g. `model[:title]`.

If the object has a generic reader, you can pass the name via `:reader`.

{{ "test/assertions_test.rb:exp-reader-get:../trailblazer-test:master" | tsnippet }}

Now the value is read via `model.get(:title)`.

### assert_exposes: Lambda

You can also pass a lambda to `assert_expose` in order to compute a dynamic value for the test, or for more complex comparisons.

{{ "test/assertions_test.rb:exp-proc:../trailblazer-test:master" | tsnippet }}

The lambda will receive a hash with the `:actual` value read from the asserted object. It must return a boolean.

## Operation

There are several helpers to deal with operation tests and operations used as factories.

## call

Instead of manually invoking an operation, you can use the `call` helper.

{{ "test/helper_test.rb:call:../trailblazer-test:master" | tsnippet }}

This will `call` the operation and passes through all other arguments. It returns the operation's result object, which allows you to test it.

```ruby
result.success? #=> true
result["model"] #=> #<Song id=1, ...>
```

## factory

You should always use operations as factories in tests. The `factory` method calls the operation and raises an error should the operation have failed. If successful, it will do the exact same thing [`call`](#call) does.

{{ "test/helper_test.rb:factory:../trailblazer-test:master" | tsnippet }}

If the factory operation fails, for example due to invalid form input, it raises a `` exception.

```ruby
factory( Song::Create, { title: "" } )["model"]
#=> Trailblazer::Test::OperationFailedError: factory( Song::Create ) failed.
```

It is absolutely advisable to use `factory` in combination with `let`.

```ruby
let(:song) { factory( Song::Create, { title: "Timebomb", band: "Rancid" } ) }
```

Also, you can safely use FactoryGirl's `attributes_for` to generate input.
