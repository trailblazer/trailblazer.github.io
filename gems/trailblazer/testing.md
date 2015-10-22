---
layout: default
---

# Testing

Testing Trailblazer applications usually involves the following tests.

1. Unit tests for operations. They test all edge cases in a nice, fast unit test environment without any HTTP involved.
2. Integration tests for controllers. These Smoke tests only test the wiring between controller, operation and presentation layer. Usually, a coded click path simulates you manually clicking through your app and testing if it works.

    The preferred way here is using Rack-test and Capybara.
3. Unit tests for cells. By invoking your cells with aritrary data you functionally test the rendered markup using Capybara.


## Rspec

Even though the Trailblazer book uses MiniTest for its test suite, Trailblazer can be tested with any framework. Usually, this will be Rspec.

Invoking operations works identical to MiniTest.

{% highlight ruby %}
describe Comment::Create do
  it "creates comment" do
    op = Comment::Create.(comment: {body: "Rspec rocks!"})
    expect(op.model.body).to eq("Rspec rocks!")
  end
end
{% endhighlight %}

You're free to use your matchers, your testing style, your way of structuring `describe` or `specify`, and so on.


!!! TODO: Example for smoke tests.

To write unit tests for your cells, please install the [rspec-cells](https://github.com/apotonick/rspec-cells) gem.

{% highlight ruby %}
describe Comment::Cell, type: :cell do
  let (:comment) { Comment::Create.(comment: {body: "Rspec rocks!"}) }
  subject { concept(:comment, comment).(:show) }

  it { expect(subject).to have_content "Rspec rocks!" }
end
{% endhighlight %}

Learn more about [Rspec and Cells](/gems/cells/testing.html#rspec).

## MiniTest