---
layout: cells
title: "Testing Cells"
---

# Testing

Only a few methods are needed to integrate cells testing into your test suite. This is implemented in `Cell::Testing`.

## API

Regardless of your test environment (Rspec, MiniTest, etc.) the following methods are available.


    module Testing
      concept(name, *args) # instantiates Cell::Concept subclass.
      cell(name, *args) # instantiates Cell::ViewModel subclass.
    end


Calling the two helpers does exactly the same it does in a controller or a view.

Usually, this will give you the cell instance. It's your job to invoke a state using `#call`.


    it "renders cell" do
      cell(:song, @song).() #=> HTML / Capybara::Node::Simple
    end


However, when invoked with `:collection`, it will render the cell collection for you. In that case, `#cell`/`#concept` will return a string of markup.


    it "renders collection" do
      cell(:song, collection: [@song, @song]) #=> HTML
    end



## MiniTest, Test::Unit

In case you're _not_ using Rspec, derive your tests from `Cell::TestCase`.


    class SongCellTest < Cell::TestCase
      it "renders" do
        cell(:song, @song).().must_have_selector "b"
      end
    end


You can also include `Cell::Testing` into an arbitrary test class if you're not happy with `Cell::TestCase`.

### Optional Controller

If your cells have a controller dependency, you can set it using `::controller`.


    class SongCellTest < Cell::TestCase
      controller SongsController


This will provide a testable controller via `#controller`, which is automatically used in `Testing#concept` and `Testing#cell`.


## Rspec

Rspec works with the [`rspec-cells` gem](https://github.com/apotonick/rspec-cells).

Make sure to install it.

```ruby
gem "rspec-cells"
```

You can use the `#cell` and `#concept` builders in your specs.


    describe SongCell, type: :cell do
      subject { cell(:song, Song.new).(:show) }

      it { expect(subject).to have_content "Song#show" }
    end


### Optional Controller

If your cells have a controller dependency, you can set it using `::controller`.


    describe SongCell do
      controller SongsController


This will provide a testable controller via `#controller`.

## Capybara Support

Per default, Capybara support is enabled in `Cell::TestCase` when the Capybara gem is loaded. This works for both Minitest and Rspec.

The only changed behavior will be that the result of `Cell#call` is wrapped into a `Capybara::Node::Simple` instance, which allows to call matchers on the result.


    cell(:song, @song).().must_have_selector "b" # example for MiniTest::Spec.

In case you need access to the actual markup string, use `#to_s`. Note that this is a Cells-specific extension.


    cell(:song, @song).().to_s.must_match "by SNFU" # example for MiniTest::Spec.

You can disable Capybara for Cells even when the gem is loaded.


    Cell::Testing.capybara = false

## Capybara with Minitest (Rails)

With Minitest, the recommended approach is to use the `minitest-rails-capybara` gem.

    group :test do
      gem "minitest-rails-capybara"
    end

You also have to include certain Capybara modules into your test case. It's a good idea to do this in your app-wide `test_helper.rb`.

```ruby
Cell::TestCase.class_eval do
  include ::Capybara::DSL
  include ::Capybara::Assertions
end
```

If you miss to do so, you will get an exception similar to the following.

```ruby
NoMethodError: undefined method `must_have_css' for #<User::Cell::Index:0xb5a6c>
```

Here's an example [how we do it](https://github.com/apotonick/gemgem-trbrb/blob/7cc8c7a0de78ba00092957a32d8cd234f102c73f/test/test_helper.rb#L19) in Gemgem.

## Capybara with Minitest::Spec

In a non-Rails environment, the [capybara_minitest_spec](https://github.com/ordinaryzelig/capybara_minitest_spec) gem is what we use.

    group :test do
      gem "capybara_minitest_spec"
    end

Add the following to your `test_helper.rb`.

    require "capybara_minitest_spec"
    Cell::Testing.capybara = true

After including the `Testing` module, you're ready to run specs against cells.

```ruby
class NavigationCellTest < Minitest::Spec
  include Cell::Testing

  it "renders avatar when user provided" do
    html = cell(Pro::Cell::Navigation, user).()

    html.must_have_css "#avatar-signed-in"
    html.to_s.must_match "Signed in: nick@trb.to"
  end
```
