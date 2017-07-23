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

## Generic Assertions

## assert_exposes

Pass a hash of key/value tuples to `assert_exposes` to test that all attributes of the asserted object match the provided values.

{{ "test/assertions_test.rb:exp-eq:../trailblazer-test:master" | tsnippet }}

Per default, this will read the values via `model#[key]` from the asserted object (`model`) and compare it to the expected values.

This is a short-cut for tests such as the following.

```ruby
assert_equal "Timebomb", model["title"]
assert_equal "Rancid",   model["band"]
```

Note that `assert_exposes` accepts any object with a `#[]` interface.

### assert_exposes: reader

If the asserted object exposes readers, you need to set `:reader` to `false`.

{{ "test/assertions_test.rb:exp-reader-false:../trailblazer-test:master" | tsnippet }}

This will read values with via the reader, e.g. `model.title`.

If the object has a generic reader, you can pass the name via `:reader`.

{{ "test/assertions_test.rb:exp-reader-get:../trailblazer-test:master" | tsnippet }}

Now the value is read via `model.get(:title)`.

### assert_exposes: Lambda

You can also pass a lambda to `assert_expose` in order to compute a dynamic value for the test, or for more complex comparisons.

{{ "test/assertions_test.rb:exp-proc:../trailblazer-test:master" | tsnippet }}

The lambda will receive the actual value read from the asserted object and must return a boolean.

## Operation

