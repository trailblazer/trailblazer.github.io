---
layout: default
---

# Operation API

## The `params` Hash

Wherever `params` is referenced, think of an input hash in terms of the `params` hash in a controller.

## Operation



Get the form object.

{% highlight ruby %}
form = Thing::Create.present(params).contract
{% endhighlight %}


## Process

The `#process` method is the pivot of any operation. Here, business logic and validations get executed and dispatched.

Its only argument is the `params` hash being passed into `Op.()`. Note that you don't even have to use a contract.

{% highlight ruby %}
class Comment < ActiveRecord::Base
  class Create < Trailblazer::Operation
    def process(params)
      # do whatever you feel like.
    end
  end
end
{% endhighlight %}

## Model Setup

## Validate

You can instantiate you contract manually and invoke validation by hand.

{% highlight ruby %}
def process(params)
  contract = contract_class.new(model)

  if contract.validate(params[:comment])
    # success.
    contract.sync
  else
    # invalid.
  end
end
{% endhighlight %}

Operation provides the `validate` method to do just that for you.

{% highlight ruby %}
def process(params)
  if validate(params[:comment])
    # success.
    contract.sync
  else
    # invalid.
  end
end
{% endhighlight %}

The block syntax will execute block only when valid and is an alternative to the above.

{% highlight ruby %}
def process(params)
  validate(params[:comment]) do |f|
    # success.
    f.sync
    return
  end

  # invalid.
end
{% endhighlight %}

The signature is `validate(params, model, contract_class)`.