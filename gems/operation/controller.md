---
layout: operation
title: "Operation::Controller"
---

# Operation::Controller

The `Operation::Controller` module provides four shorthand methods to run and present operations.

Note that you're free to invoke operations manually at any time by [invoking them directly](api.html).

It works in Rails but should also be fine in Sinatra, Lotus and other frameworks that expose a `params` object.

## Overview

You have four methods to pick from.

* Use `#present` if you're only interested in _presenting_ the operation's model.
* Use `#form` to _render_ the form object. This will not run the operation.
* Use `#run` to process incoming data using the operation (and present it afterwards).
* Use `#respond` to process incoming data and present it using Rails' `respond_to`.

## Generics

Before the operation is invoked, the controller method `process_params!` is run. You can override that to normalize the incoming parameters.

You need to include the `Controller` module into the controller. This will import the `form`, `present`, `run` and `respond` methods.

    class ApplicationController < ActionController::Base
      include Trailblazer::Operation::Controller
    end

## Run

Use `#run` to invoke the operation.

    class CommentsController < ApplicationController
      def create
        run Comment::Create
      end
    end

This _runs_ the operation with `params`, sets `@operation`, `@model` and `@form` on the controller instance, and returns the operation instance.

Note that you can grab the operation and reassign it to another instance variable if you have multiple operation invocations.

    class CommentsController < ApplicationController
      def create
        create_op = run Comment::Create # returns operation instance.
        @comment  = create_op.model
      end

The call stack in `#run` is as follows.

    #run
      process_params!(params)
      result, op = Comment::Create.run(params)
      @operation = op
      @model     = op.model
      @form      = op.contract

First, you have the chance to normalize parameters. The controller's `params` hash is then passed into the operation run. After that, operation and model are assigned to controller instance variables.

An optional block for `#run` is invoked only when the operation was valid.


    class CommentsController < ApplicationController
      def create
        run Comment::Create do |op|
          flash[:notice] = "Success!" # only run for successful/valid operation.
        end
      end
    end


## Present

To setup an operation without running its `#process` method, use `#present`. This is often used if you only need the operation's model for presentation.


    class CommentsController < ApplicationController
      def show
        present Comment::Update
        # you have access to @operation and @model.
      end
    end

This _instantiates_ the operation with `params`, sets `@operation` and `@model` on the controller instance, and returns the operation instance.

Instead of running the operation, this will only instantiate the operation by passing in the controller's `params`. In turn, this only runs the operation's `#setup` (which embraces model finding logic).

The `#present` helper **does not run** `#process` and does **not instantiate** a contract (which will be faster than `#form`).

Note that you can grab the operation and reassign it to another instance variable if you have multiple operation invocations.

    class CommentsController < ApplicationController
      def show
        update_op = present Comment::Update # returns operation instance.
        @comment  = update_op.model
      end

The call stack in `#present` is as follows.

    #present
      op = Comment::Update.present(params)
      @operation = op
      @model     = op.model

Note that no `@form` is instantiated and assigned to the controller. If you need the form use the `#form` method.

## Form

To render the operation's form, use `#form`. This is identical to `#present` plus the contract is being instantiated.

    class CommentsController < ApplicationController
      def new
        form Comment::Create
      end
    end

This _instantiates_ the operation with `params` and then sets `@operation`, `@model` and `@form` on the controller instance. After that, the form's `prepopulate!` method is called and the form is ready for rendering.

The `#form` helper **does not run** `#process`.

It returns the _form_ instance.

Note that you can grab the form and reassign it to another instance variable if you use multiple operations in your endpoint.

    class CommentsController < ApplicationController
      def show
        @create_form = form Comment::Create # returns form instance.
        @post_form   = form Post::Create
      end

The call stack in `#form` is as follows.

    #form(operation, options)
      op = Comment::Create.present(params)

      @operation = op
      @model     = op.model
      @form      = op.contract

      @form.prepopulate!(options)

### Options for prepopulate!

Any options passed to `#form` are directly propagated to the form's `prepopulate!` method, allowing you to use runtime data in prepopulators. Note that the original `params` object is available in this options hash, too.

    form Comment::Create, color: "green"

This will result in the following hash being passed to `prepopulate!`.

    class Comment::Create < Trailblazer::Operation
      contract do
        def prepopulate!(options)
          options[:color]  #=> "green"
          options[:params] #=> <ActionController::Params ..>

## Respond

Rails-specific.


    class CommentsController < ApplicationController
      respond_to :json

      def create
        respond Comment::Create
      end
    end


This will do the same as `#run`, invoke the operation and then pass it to `#respond_with`.


    op = Comment::Create.(params)
    respond_with op


The operation needs to be prepared for the responder as the latter makes weird assumptions about the object being passed to `respond_with`. For example, the operation needs to respond to `to_json` in a JSON request. Read about [Representer](representer.html) here.

If the operation class has `Representer` mixed in, the params hash will be slightly modified. As the operation's model key, the request body document is passed into the operation.


    params[:comment] = request.body
    Comment::Create.(params)


By doing so the operation's representer will automatically parse and deserialize the incoming document, bypassing Rails' `ParamsParser`.

If you want the responder to compute URLs with namespaces, pass in the `:namespace` option.


    respond Comment::Create, namespace: [:api]


This will result in a call `respond_with :api, op`.

## Custom Params

If you want to manually hand in parameters to `#run`, `#respond`, `#form` or `#present`, use the `params:` option.

    def create
      run Comment::Create, params: {comment: {body: "Always the same! Boring!"}}
    end

## Document Formats

Normally, Trailblazer will pass Rails' `params` hash into any operation.

For operations that have `Operation::Representer` included, not a hash but the request body will be passed into the operation, keyed under the operation's `model_name`.

    Comment::Create.({comment: request.body.string})

This allows the operation's representer to deserialize the document and populate the contract, bypassing Rails' `ParamsParser`.

You can instruct Trailblazer not to do that and pass in the normal `params` hash if you don't want that using the `:is_document` option.

    def create
      run Comment::Create, is_document: false # will run Comment::Create(params)
    end

## Normalizing Params

Override `#params!` to return an arbitrary params object. This is called in `#run`, `#respond`, `#present` and `#form` before the operation is called.

    class CommentsController < ApplicationController
    private
      def params!(params)
        params.to_h # return arbitrary object.
      end
    end

Override `#process_params!` to add or remove values to params before the operation is run. This is called in `#run`, `#respond`, `#present` and `#form`.

    class CommentsController < ApplicationController
    private
      def process_params!(params)
        params.merge!(current_user: current_user)
      end
    end

Note that this is a mutual method where you're changing the `params` object.
