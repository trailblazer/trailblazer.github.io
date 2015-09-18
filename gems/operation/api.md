---
layout: default
---




# Operation API

This document discusses the callstack from top to bottom.

## Call Style

The _call style_  returns the operation when the validation was successful. With invalid data, it will raise an `InvalidContract` exception.

{% highlight ruby %}
Comment::Create.(comment: {body: "MVC is so 90s."}) #=> <Comment::Create @model=..>
Comment::Create.(comment: {}) #=> exception raised!
{% endhighlight %}

The call style is popular for tests and on the console.

## Run Style

The _run style_ returns a result set `[result, operation]` in both cases.

{% highlight ruby %}
res, operation = Comment::Create.run(comment: {body: "MVC is so 90s."})
{% endhighlight %}

However, it also accepts a block that's run in case of a _successful validation_.

{% highlight ruby %}
res, operation = Comment::Create.run(comment: {}) do |op|
  puts "Hey, #{op.model} was created!" and return # not run.
end

puts "That's wrong: #{operation.errors}"
{% endhighlight %}

To conveniently handle the inverse case where the block should be run in case of an _invalid_ operation, use `::reject`.

{% highlight ruby %}
res, operation = Comment::Create.reject(comment: {}) do |op|
  puts "this is all wrong! #{operation.errors}"
end
{% endhighlight %}

Regardless of the style, you always get the operation instance. This is only for presentation. Please treat it as immutuable.

## Operations in Tests

Operations when used test factories are usually invoked with the _call_ style.

{% highlight ruby %}
let(:comment) { Comment::Create.(valid_comment_params).model }
{% endhighlight %}

Using operations as test factories is a fundamental concept of Trailblazer to remove buggy redundancy in tests and manual factories. Note that you might use FactoryGirl to create `params` hashes.


## The Callstack

Here's the default call stack of methods involved when running an Operation.

<pre>
::call
├── ::build_operation
│   ├── #initialize
│   │   ├── #setup!
│   │   │   ├── #setup_params!
│   │   │   ├── #build_model!
│   │   │   │   ├── #assign_model!
│   │   │   │   │   ├── #model!
│   │   │   │   ├── #setup_model!
│   ├── #run
│   │   ├── #process
</pre>

1. In case of a polymorphic setup when you want different operation classes to handle different contexts, configured [builders](builder.html) will be run by `::build_operation` to figure out the class to instantiate.
2. Override `#setup_params!` to normalize the incoming parameters.
3. Override `#model!` to compute the operation's model.
3. Override `#setup_model!` for tasks such as adding nested models to the operation's model.
4. Implement `#process` for your business logic.

The `Operation::Model` module to [create/find models automatically](model.html) hooks into those methods.

## Process

The `#process` method is the pivot of any operation. Here, business logic and validations get executed and dispatched.

Its only argument is the `params` hash being passed into `Op.({..})`. Note that you don't even have to use a contract or a model.

{% highlight ruby %}
class Comment::Create < Trailblazer::Operation
  def process(params)
    # do whatever you feel like.
  end
end
{% endhighlight %}


## Validate

The `validate` method will instantiate the operation's Reform form with the model and validate it. If you pass a block to it, this will be executed only if the validation was successful (valid).

{% highlight ruby %}
class Comment::Update < Trailblazer::Operation
  contract do
    property :body, validates: {presence: true}
  end

  def process(params)
    manual_model = Comment.find(1)

    validate(params, manual_model) do
      contract.save
    end
  end
end
{% endhighlight %}

Note that when `Model` is _not_ included, you have to pass in the model as the second argument to `#validate`.

However, since most operations use `Model`, we can omit a lot of code here.

{% highlight ruby %}
class Comment::Update < Trailblazer::Operation
  include Model
  model Comment, :update

  contract do
    property :body, validates: {presence: true}
  end

  def process(params)
    validate(params) do
      contract.save
    end
  end
end
{% endhighlight %}

With `Model` included, `#validate` only takes one argument: the `params` to validate.

## Validate Internals

Internally, this is what happens.

{% highlight ruby %}
def validate(params)
  @contract = self.class.contract_class.new(model)
  @valid = @contract.validate(params)
end
{% endhighlight %}

1. The contract is instantiated using the operation's `#model`. The contract is available via `#contract` throughout the operation (even before you call `#validate`, which will use the same instance).
2. It then validates the incoming `params`, assigns values and errors on the contract object and returns the result.

## Validate: Handling Invalid

You don't have to use the block-style `#validate`. It returns the validation result and allows an `if/else`, too.

{% highlight ruby %}
def process(params)
  if validate(params[:comment])
    contract.save # success.
  else
    notify! # invalid.
  end
end
{% endhighlight %}

## Contract

Normally, the contract is instantiated when calling `validate`. However, you can access the contract before that. The `contract` is memoized and `validate` will use the existing instance.

{% highlight ruby %}
def process(params)
  contract.body = "Static"
  validate(params[:comment]) do # will use above contract.
    contract.save # also the same as above.
  end
end
{% endhighlight %}

The `#contract` method always returns the Reform object. It has the [identical API](/gems/reform/api.html) and allows to `sync`, `save`, etc.

This is not only useful in the `validate` block, but also afterwards, for example to render the invalid form.

{% highlight ruby %}
operation = Comment::Create.(params)
form      = operation.contract
{% endhighlight %}

## Validation Errors

You can access the contracts `Errors` object via `Operation#errors`.


## Manual Contract

In case you want to keep your contract in a separate file, or reuse a contract class without inheriting from another operation, use `::contract_class=` to reference another contract. Note that this in _not_ a copy but references the very same contract.

{% highlight ruby %}
class Comment::Delete < Trailblazer::Operation
  self.contract_class = Update.contract_class
{% endhighlight %}

You can also reference a normal Reform class.

{% highlight ruby %}
self.contract_class = CommentForm
{% endhighlight %}


## Marking Operation as Invalid

Sometimes you don't need a form object but still want the validity behavior of an operation.

{% highlight ruby %}
def process(params)
  return invalid! unless params[:id]

  Comment.find(params[:id]).destroy
  self
end
{% endhighlight %}

## Rendering Operation's Form

You have access to an operation's form using `::present`.

{% highlight ruby %}
Comment::Create.present(params)
{% endhighlight %}

This will run the operation's `#process` method _without_ the validate block and return the contract.



## ActiveModel Semantics

When using `Reform::Form::ActiveModel` (which is used automatically in a Rails environment to make form builders work) you need to invoke `model Comment` in the contract. This can be inferred automatically from the operation by including `Model::ActiveModel`.

```ruby
class Create < Trailblazer::Operation
  include Model
  include Model::ActiveModel

  model Comment

  contract do # no need to call ::model, here.
    property :text
  end
```

If you want that in all CRUD operations, check out [how you can include](https://github.com/apotonick/gemgem-trbrb/blob/chapter-5/config/initializers/trailblazer.rb#L26) it automatically.
