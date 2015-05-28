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

Calling the two helpers does exactly the same it does in a controller or a view.

Usually, this will give you the cell instance. It's your job to invoke a state using `#call`.

{% highlight ruby %}
it "renders cell" do
  cell(:song, @song).call #=> HTML / Capybara::Node::Simple
end
{% endhighlight %}

However, when invoked with `:collection`, it will render the cell collection for you. In that case, `#cell`/`#concept` will return a string of markup.

{% highlight ruby %}
it "renders collection" do
  cell(:song, collection: [@song, @song]) #=> HTML
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

### Optional Controller

If your cells have a controller dependency, you can set it using `::controller`.

{% highlight ruby %}
class SongCellTest < Cell::TestCase
  controller SongsController
{% endhighlight %}

This will provide a testable controller via `#controller`, which is automatically used in `Testing#concept` and `Testing#cell`.


## Rspec

Rspec works out of the box. You can use the `#cell` and `#concept` builders in your specs.

{% highlight ruby %}
describe SongCell, type: :cell do
  subject { cell(:song, Song.new).call(:show) }

  it { expect(subject).to have_content "Song#show" }
end
{% endhighlight %}

### Optional Controller

If your cells have a controller dependency, you can set it using `::controller`.

{% highlight ruby %}
describe SongCell do
  controller SongsController
{% endhighlight %}

This will provide a testable controller via `#controller`.

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