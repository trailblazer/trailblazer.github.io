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

Use `assert_pass` to run an operation and assert it was successful, while checking if the attributes of the operation's `model` are what you're expecting.

{{ "test/operation_test.rb:pass:../trailblazer-test:master" | tsnippet }}

Both `params_pass` and `attrs_pass` have to be made available via `let` to provide all default data. They will automatically get merged with the data per test-case. `params_pass` will be merged with the params passed into the operation `call`, `attrs_pass` represent your expected outcome.

The second test case would resolve to this manual test code.

    it do
      result = Comment::Create( band: "Rancid", title: "  Ruby Soho " )

      assert result.success?
      assert_equal "Rancid",   result["model"].band
      assert_equal "Timebomb", result["model"].title
    end

As you can see, `assert_pass` drastically reduces the amount of test code.

### assert_pass: Block

If you need more specific assertions, use a block with `assert_pass`.

{{ "test/operation_test.rb:pass-block:../trailblazer-test:master" | tsnippet }}

Here, the only assertion made automatically is whether the operation was run successfully. By yielding the result object in case of success, all other assertions can be made manually.

## assert_fail

To test an unsuccessful outcome of an operation, use `assert_fail`. This is used for testing all kinds of validations. By passing insufficient or wrong data to the operation, it will fail and mark errors on the errors object.

{{ "test/operation_test.rb:fail:../trailblazer-test:master" | tsnippet }}

Here, your params are merged into `params_pass` and the operation is called. The first assertion is whether `result.failure?` is true.

After that, the operation's error object is grabbed. With an array as the third argument to `assert_fail` this will test if the errors object keys and your expected keys of error messages are equal.

{% callout %}
In 2.0 and 2.1, the errors object defaults to `result["contract.default"].errors`. In TRB 2.2, there will be an operation-wide errors object decoupled from the contracts.
{% endcallout %}

This roughly translates to the following manual test case.

    it do
      result = Comment::Create( band: "  Adolescents", title: "Timebomb" )
                                            # Timebomb is a Rancid song.
      assert result.failure?
      assert_equal [:band], result["contract.default"].errors.messages.keys
    end

Per default, no assumptions are made on the model.

### assert_fail: Block

You can use a block with `assert_fail`.

{{ "test/operation_test.rb:fail-block:../trailblazer-test:master" | tsnippet }}

Only the `failure?` outcome is asserted here automatically.

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
