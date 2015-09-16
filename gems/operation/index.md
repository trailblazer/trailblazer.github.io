---
layout: default
permalink: /gems/operation/
---

# Trailblazer::Operation

An operation is a service object.

It embraces and orchestrates all business logic between the controller dispatch and the persistance layer. This ranges from tasks as finding or creating a model, validating incoming data using a form object to persisting application state using model(s) and dispatching post-processing callbacks or even nested operations.

Note that operation is not a monolithic god object, but a composition of many. It is up to you to include features like polices, representers or callbacks.

Every public function in your application is implemented as an operation. Ideally, you don't access models directly anymore, only via the respective operation.

## API

An operation is to be seen as a _function_ as in _Functional Programming_. You invoke an operation using the implicit `::call` class method.

{% highlight ruby %}
op = Comment::Create.(comment: {body: "MVC is so 90s."})
{% endhighlight %}

This will instantiate the `Comment::Create` operation for you, run it and return this very instance. The reason the instance is returned is to allow you accessing its contract, validation errors, or other objects you might need for presentation.

**Consider this operation instance as a throw-away immutual object.** Don't use it for anything but presentation or you will have unwanted side-effects.

## Operation Class

All you need in an operation is a `#process` method.

{% highlight ruby %}
class Comment::Create < Trailblazer::Operation
  def process(params)
    puts params
  end
end
{% endhighlight %}

Running this operation will result in the following.

{% highlight ruby %}
Comment::Create.(comment: {body: "MVC is so 90s."})
#=> {comment: {body: "MVC is so 90s."}}
{% endhighlight %}

The params from the invocation get passed into `#process`.

## Model

Normally, operations are working on _models_. This term does absolutely not limit you to ActiveRecord-style ORM models, though, but can be just anything, for example a `OpenStruct` composition or a ROM model.

Assigning `@model` will allow accessing your operation model from the outside.

{% highlight ruby %}
class Comment::Create < Trailblazer::Operation
  def process(params)
    @model = Comment.find params[:id]
  end
end

op = Comment::Create.(id: 1)
op.model #=> <Comment id: 1>
{% endhighlight %}

## Contract


## Run

There's two different invocation styles.

The **call style** will return the operation when the validation was successful. With invalid data, it will raise an `InvalidContract` exception.

{% highlight ruby %}
Comment::Create.(comment: {body: "MVC is so 90s."}) #=> <Comment::Create @model=..>
Comment::Create.(comment: {}) #=> exception raised!
{% endhighlight %}

The call style is popular for tests and on the console.

The **run style** returns a result set `[result, operation]` in both cases.

{% highlight ruby %}
res, operation = Comment::Create.run(comment: {body: "MVC is so 90s."})
{% endhighlight %}

However, it also accepts a block that's run in case of a _successful validation_.

{% highlight ruby %}
res, operation = Comment::Create.run(comment: {}) do |op|
  # this is not run, because validation not successful.
  puts "Hey, #{op.model} was created!"
end
{% endhighlight %}

This style is often used in framework bindings for Rails, Lotus or Roda when hooking the operation call into the endpoint.



## Design Goals

Operations decouple the business logic from the actual framework and from the persistence layer. This makes is really easy to swap ORMs or the entire framework. For instance, operations written in a Rails environment can be run in Sinatra or Lotus as the only coupling happens when querying or writing to the database.

Abstraction via Twin (for view, BL, representers)

Pages: [API](api.html)
Pages: [Collection](collection.html)
Pages: [Callback](callback.html)
Pages: [Controller](controller.html)
Pages: [representer](representer.html)
Pages: [CRUD](crud.html)
Pages: [Policy](policy.html)
Pages: [Builder](builder.html)
