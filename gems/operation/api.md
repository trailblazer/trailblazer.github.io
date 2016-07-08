---
layout: operation
title: "Operation API"
---




# Operation API

This document discusses the callstack from top to bottom.

## Call Style

The _call style_  returns the operation when the validation was successful. With invalid data, it will raise an `InvalidContract` exception.


    Comment::Create.(comment: {body: "MVC's so 90s."}) #=> <Comment::Create @model=..>
    Comment::Create.(comment: {}) #=> exception raised!


The call style is popular for tests and on the console.

## Run Style

The _run style_ returns a result set `[result, operation]` for both valid and invalid invocation.


    res, operation = Comment::Create.run(comment: {body: "MVC is so 90s."})


However, it also accepts a block that's run in case of a _successful validation_. When run with block, only the operation instance is returned as the block represents a valid state.


    operation = Comment::Create.run(comment: {}) do |op|
      puts "Hey, #{op.model} was created!" and return # not run.
    end

    puts "That's wrong: #{operation.errors}"


To conveniently handle the inverse case where the block should be run in case of an _invalid_ operation, use `::reject`.


    res, operation = Comment::Create.reject(comment: {}) do |op|
      puts "this is all wrong! #{operation.errors}"
    end


Regardless of the style, you always get the operation instance. This is only for presentation. Please treat it as immutuable.

## Operations in Tests

Operations when used test factories are usually invoked with the _call_ style.


    let(:comment) { Comment::Create.(valid_comment_params).model }


Using operations as test factories is a fundamental concept of Trailblazer to remove buggy redundancy in tests and manual factories. Note that you might use FactoryGirl to create `params` hashes.


## Callstack

Here's the default call stack of methods involved when running an Operation.


    ::call
    ├── ::build_operation
    │   ├── #initialize
    │   │   ├── #setup!
    │   │   │   ├── #assign_params!
    │   │   │   │   │   ├── #params!
    │   │   │   ├── #setup_params!
    │   │   │   ├── #build_model!
    │   │   │   │   ├── #assign_model!
    │   │   │   │   │   ├── #model!
    │   │   │   │   ├── #setup_model!
    │   ├── #run
    │   │   ├── #process


1. In case of a polymorphic setup when you want different operation classes to handle different contexts, configured [builders](builder.html) will be run by `::build_operation` to figure out the class to instantiate.
2. Override `#setup_params!` to normalize the incoming parameters. This implies that you have to change the original hash.
3. Override `#params` if you want to use a different params hash - which you simply return from this method. This allows to keep the original `params` immutable.
3. Override `#model!` to compute the operation's model.
3. Override `#setup_model!` for tasks such as adding nested models to the operation's model.
4. Implement `#process` for your business logic.

The `Operation::Model` module to [create/find models automatically](model.html) hooks into those methods.

## Process

The `#process` method is the pivot of any operation. Here, business logic and validations get executed and dispatched.

Its only argument is the `params` hash being passed into `Op.({..})`. Note that you don't even have to use a contract or a model.


    class Comment::Create < Trailblazer::Operation
      def process(params)
        # do whatever you feel like.
      end
    end



## Validate

The `validate` method will instantiate the operation's Reform form with the model and validate it. If you pass a block to it, this will be executed only if the validation was successful (valid).


    class Comment::Update < Trailblazer::Operation
      contract do
        property :body, validates: {presence: true}
      end

      def process(params)
        manual_model = Comment.find(1)

        validate(params[:comment], manual_model) do
          contract.save
        end
      end
    end


Note that when `Model` is _not_ included, you have to pass in the model as the second argument to `#validate`.

However, since most operations use `Model`, we can omit a lot of code here.


    class Comment::Update < Trailblazer::Operation
      include Model
      model Comment, :update

      contract do
        property :body, validates: {presence: true}
      end

      def process(params)
        validate(params[:comment]) do
          contract.save
        end
      end
    end


With `Model` included, `#validate` only takes one argument: the `params` to validate.

## Validate Internals

Internally, this is what happens.


    def validate(params)
      @contract = self.class.contract_class.new(model)
      @valid = @contract.validate(params)
    end


1. The contract is instantiated using the operation's `#model`. The contract is available via `#contract` throughout the operation (even before you call `#validate`, which will use the same instance).
2. It then validates the incoming `params`, assigns values and errors on the contract object and returns the result.

## Validate: Handling Invalid

You don't have to use the block-style `#validate`. It returns the validation result and allows an `if/else`, too.


    def process(params)
      if validate(params[:comment])
        contract.save # success.
      else
        notify! # invalid.
      end
    end


## Contract

Normally, the contract is instantiated when calling `validate`. However, you can access the contract before that. The `contract` is memoized and `validate` will use the existing instance.


    def process(params)
      contract.body = "Static"
      validate(params[:comment]) do # will use above contract.
        contract.save # also the same as above.
      end
    end


The `#contract` method always returns the Reform object. It has the [identical API](/gems/reform/api.html) and allows to `sync`, `save`, etc.

This is not only useful in the `validate` block, but also afterwards, for example to render the invalid form.


    operation = Comment::Create.(params)
    form      = operation.contract


Note that you don't have to `run` an operation in order to get its form object (which would invoke the `#process` method). You can [use `::present` instead](#).

## Validation Errors

You can access the contracts `Errors` object via `Operation#errors`.

## Present

To grab the operation's form object for presentation without running `process`, use `::present`.

{% highlight ruby %}
op = Comment::Create.present(params)
op.model    #=> model is available!
op.contract #=> form object, too.
{% endhighlight %}

[In the callstack](#callstack), this simply runs `#initialize`, only.

This is used when presenting the operation's form or model, for example in `new`, `edit` or `show` actions in a controller.

## Composable Interface: Contract

The operation's contract is just a plain Reform class and doesn't know anything about the composing operation.

This is why you may reference arbitrary contract classes using `::contract`. That's helpful if you keep contracts in separate files, or reuse them without inheriting from another operation.


    class Comment::Delete < Trailblazer::Operation
      contract CommentForm # a plain Reform::Form class.


You can also reference a contract from another operation.


    class Comment::Delete < Trailblazer::Operation
      contract Update.contract


Note that `::contract` will subclass the referenced contract class, making it a copy of the original, allowing you to add and remove fields and validations in the copy.

You can also copy and refine the contract.


    class Comment::Delete < Trailblazer::Operation
      contract Update.contract do
        property :upvotes
      end


To reference without copying, use `Operation::contract_class=(constant)`

## Marking Operation as Invalid

Sometimes you don't need a form object but still want the validity behavior of an operation.


    def process(params)
      return invalid! unless params[:id]

      Comment.find(params[:id]).destroy
      self
    end


## ActiveModel Semantics

When using `Reform::Form::ActiveModel` (which is used automatically in a Rails environment to make form builders work) you need to invoke `model Comment` in the contract. This can be inferred automatically from the operation by including `Model::ActiveModel`.


    class Create < Trailblazer::Operation
      include Model
      include Model::ActiveModel

      model Comment

      contract do # no need to call ::model, here.
        property :text
      end


If you want that in all CRUD operations, check out [how you can include](https://github.com/apotonick/gemgem-trbrb/blob/chapter-5/config/initializers/trailblazer.rb#L26) it automatically.
