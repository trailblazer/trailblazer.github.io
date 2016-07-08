---
layout: operation
permalink: /gems/operation/
title: "Trailblazer: Operation"
---

# Trailblazer::Operation

An operation is a service object.

Operations implement functions of your application, like creating a comment, following a user or exporting a PDF document. Sometimes this is also called _command_.

<img src="/images/diagrams/stack.png" style="width: 70%">

Technically, an operation embraces and orchestrates all business logic between the controller dispatch and the persistance layer. This ranges from tasks as finding or creating a model, validating incoming data using a form object to persisting application state using model(s) and dispatching post-processing callbacks or even nested operations.

Note that operation is not a monolithic god object, but a composition of many stakeholders. It is up to you to include features like policies, representers or callbacks.

## API

An operation is to be seen as a _function_ as in _Functional Programming_. You invoke an operation using the implicit `::call` class method.


    op = Comment::Create.(comment: {body: "MVC is so 90s."})


This will instantiate the `Comment::Create` operation for you, run it and return this very instance. The reason the instance is returned is to allow you accessing its contract, validation errors, or other objects you might need for presentation.

**Consider this operation instance as a throw-away immutable object.** Don't use it for anything but presentation or you will have unwanted side-effects.

## Operation Class

All you need in an operation is a `#process` method.


    class Comment::Create < Trailblazer::Operation
      def process(params)
        puts params
      end
    end


Running this operation will result in the following.


    Comment::Create.(comment: {body: "MVC is so 90s."})
    #=> {comment: {body: "MVC is so 90s."}}


The params from the invocation get passed into `#process`.

## Model

Normally, operations are working on _models_. This term does absolutely not limit you to ActiveRecord-style ORM models, though, but can be just anything, for example a `OpenStruct` composition or a ROM model.

Assigning `@model` will allow accessing your operation model from the outside.


    class Comment::Update < Trailblazer::Operation
      def process(params)
        @model = Comment.find params[:id]
      end
    end

    op = Comment::Update.(id: 1)
    op.model #=> <Comment id: 1>


Since every public function in your application is implemented as an operation, you don't access models directly anymore on the outside.

## Contract

The cool thing about Trailblazer's operation is that it integrates the validation process using a form object.

This is often done wrong in Rails applications where the controller first instantiates a form and then passes it to a service object. In Trailblazer, the operation is the place for all business logic.


    class Comment::Create < Trailblazer::Operation
      contract do
        property :body, validates: {presence: true}
      end

      def process(params)
        @model = Comment.new

        validate(params[:comment], @model) do
          contract.save
        end
      end
    end


Using the `::contract` block you can define a `Reform::Form` class that the operation will use for validation (and rendering). [Any Reform feature](/gems/reform) like nesting, populators or complex validations can be used here.

The `validate` block is only executed when the validation was successful and allows you to save the model and run arbitrary post-processing code. Here, we use the contract's `save` which will push the validated data to the model and then save it.

[Learn more](/gems/operation/api.html#contract)

## Operation::Model

Normally, a `Create` operation will instantiate a new model object, whereas `Update`, `Show`, or `Delete` operations need to find a particular model.

This is such a common workflow for CRUD operations that it is built into Trailblazer in the `Operation::Model` module.


    class Comment::Create < Trailblazer::Operation
      include Model
      model Comment, :create

      contract do
        property :body, validates: {presence: true}
      end

      def process(params)
        validate(params[:comment]) do
          contract.save
        end
      end
    end


Now, the operation takes care of creating the model in `validate`. Note that there is zero coupling to ActiveRecord: `Model` will only call `Comment.new` or `Comment.find(id)` on the configured model class to accomplish its job, allowing any kind of persistence layer with that API.


    Comment::Create.(comment: {body: "MVC is so 90s."}).model #=> <Comment body="MVC ..">


[Learn more](model.html)

## Run

There's two different invocation styles.

The **call style** will return the operation when the validation was successful. With invalid data, it will raise an `InvalidContract` exception.


    Comment::Create.(comment: {body: "MVC is so 90s."}) #=> <Comment::Create @model=..>
    Comment::Create.(comment: {}) #=> exception raised!


The call style is popular for tests and on the console.

The **run style** returns a result set `[result, operation]` in both cases.


    res, operation = Comment::Create.run(comment: {body: "MVC is so 90s."})


However, it also accepts a block that's run in case of a _successful validation_.


    res, operation = Comment::Create.run(comment: {}) do |op|
      # this is not run, because validation not successful.
      puts "Hey, #{op.model} was created!" and return
    end

    puts "That's wrong: #{operation.errors}"


This style is often used in framework bindings for Rails, Lotus or Roda when hooking the operation call into the endpoint.

## Design Goals

Operations decouple the business logic from the actual framework and from the persistence layer.

This makes it really easy to update or swap the underlying framework or ORM. For instance, operations written in a Rails environment can be run in Sinatra or Lotus as the only coupling happens when querying or writing to the database.

## Testing Operations

Operations are incredibly simple to test. All edge-cases can cleanly be tested in unit tests, without the HTTP overhead.


    describe Comment::Create do
      it "works" do
        comment = Comment::Create.(comment: {body: "Operation rules!"}).model
        expect(comment.body).to eq("Operation rules!")
      end
    end


## Testing With Operations

Another huge advantage is: operations can be used in any environment like scripts, background jobs and will do the exact same as in a controller. This is extremely helpful to use operations as a replacement for test factories.


    describe Comment::Update do
      it "updates" do
        comment = Comment::Create.(..) # this is a factory.

        Comment::Update.(id: comment.id, comment: {body: "FTW!"})
        expect(comment.body).to eq("FTW!")
      end
    end


## Presenting Operations

The operation is not only helpful for validating and processing data, it can also be used when rendering the form.


    operation = Comment::Update.present(id: 1)


`Comment::Update` will now run the model-finding logic and create the form object for you. It will _not_ run `#process`.


    # Operation finds the model..
    operation.model #=> <Comment body="FTW!">
    # and provides the Reform object.
    @form = operation.contract #=> <Reform::Form ..>


As Reform works with most form builders out-of-the-box, you can pass the form right into it.


    = simple_form_for @form do |f|
      = f.input :body
      = f.button :submit


This normally covers the logic for two controller actions, e.g. `new` and `create`.

## More

Operation has many optional features like authorization, callbacks, polymorphic builders, etc.


