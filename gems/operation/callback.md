---
layout: default
---

## Composable Interface

Using `Operation::callback` simply creates a new `Disposable::Callback::Group` class for you.

{% highlight ruby %}
class Comment::Create < Trailblazer::Operation
  callback :after_save do
    # this is a Disposable::Callback::Group class.
  end
{% endhighlight %}

Successive calls with the same name will extend the group.

{% highlight ruby %}
class Comment::Create < Trailblazer::Operation
  callback :after_save do
    on_change :notify!
  end

  callback :after_save do
    on_change :cleanup!
  end
{% endhighlight %}

Dispatching `:after_save` will now run `#notify!`, then `#cleanup!`.

Note that this also works when inheriting callbacks from a parent operation. You can extend it without changing the parent's callbacks.

If you prefer keeping callbacks in separate classes, you can do so.

{% highlight ruby %}
class AfterSave < Disposable::Callback::Group
  on_change :notify!
end
{% endhighlight %}

Register it using `::callback`.

{% highlight ruby %}
class Comment::Create < Trailblazer::Operation
  callback :after_save, AfterSave
{% endhighlight %}

As always, the callback can be extended locally.

{% highlight ruby %}
class Comment::Create < Trailblazer::Operation
  callback :after_save, AfterSave do
    on_update :cleanup!
  end
{% endhighlight %}

Since Trailblazer copies the callback group, this will change the callbacks only for this operation.

## Custom Callbacks

You can attach any callback object you like to an operation. It will receive the contract in the initializer and has to respond to `#call`.

{% highlight ruby %}
class MyCallback
  def initialize(contract)
    @contract = contract
  end

  def call(options) # this is {context: operation} normally.
    User::Mailer.(@contract.email)
  end
end
{% endhighlight %}

Use `::callback` to register it as a group.

{% highlight ruby %}
class Comment::Create < Trailblazer::Operation
  callback :after_save, MyCallback
{% endhighlight %}