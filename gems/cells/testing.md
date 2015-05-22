---
layout: default
---

# Testing

Only a few methods are needed to integrate cells testing into your test suite. This is implemented in `Cell::Testing`.

## API

Regardless of your test environment (Rspec, MiniTest, etc.) the following methods are available.

{% highlight ruby %}
module Testing
  concept(name, *args) # instantiates Cell::Concept subclass.
  cell(name, *args) # instantiates Cell::ViewModel subclass.
end
{% endhighlight %}

This will give you the cell instance. It's your job to invoke a state using `#call`.

{% highlight ruby %}
it "renders" do
  cell(:song, @song).call #=> HTML / Capybara::Node::Simple
end
{% endhighlight %}

## MiniTest, Test::Unit

In case you're _not_ using Rspec, derive your tests from `Cell::TestCase`.

{% highlight ruby %}
class SongCellTest < Cell::TestCase
  it "renders" do
    cell(:song, @song).call.must_have_selector "b"
  end
end
{% endhighlight %}

You can also include `Cell::Testing` into an arbitrary test class if you're not happy with `Cell::TestCase`.

## Capybara Support

Per default, Capybara support is enabled in `Cell::TestCase` when the Capybara gem is loaded.

The only extension is that the result of `Cell#call` is wrapped into a `Capybara::Node::Simple` instance, which allows to call matchers on the result.

{% highlight ruby %}
cell(:song, @song).call.must_have_selector "b" # example for MiniTest::Spec.
{% endhighlight %}

In case you need access to the actual markup string, use `#to_s`. Note that this is a Cells-specific extension.

{% highlight ruby %}
cell(:song, @song).call.to_s.must_match "by SNFU" # example for MiniTest::Spec.
{% endhighlight %}

You can disable Capybara for Cells even when the gem is loaded.

{% highlight ruby %}
Cell::Testing.capybara = false
{% endhighlight %}