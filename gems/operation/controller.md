---
layout: operation
---

# Operation::Controller

The `Operation::Controller` module provides four shorthand methods to run and present operations. It works in Rails but should also be fine in Sinatra.

## Generics

Before the operation is invoked, the controller method `process_params!` is run. You can override that to normalize the incoming parameters.

Each method will set the `@operation` and `@model` instance variables on the controller which allows using them in views, too. Each method returns the operation instance.

You need to include the `Controller` module.


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


Internally, this will do as follows.


    process_params!(params)

    result, op = Comment::Create.run(params)
    @operation = op
    @model     = op.model
    @form      = op.contract


First, you have the chance to normalize parameters. The controller's `params` hash is then passed into the operation run. After that, the three instance variables on the controller are set, giving you access to operation instance, form and model.

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


Instead of running the operation, this will only instantiate the operation by passing in the controller's `params`. In turn, this only runs the operation's `#setup` (which embraces model finding logic) and does **not instantiate** a contract and **doesn't run** `#process`.


    Comment::Update.new(params)
    @operation = op
    @model     = op.model


## Form

To render the operation's form, use `#form`.


    class CommentsController < ApplicationController
      def show
        form Comment::Create
      end
    end


This is identical to `#present` with two additional step: besides the `@operation` and `@model` instance variables, the `@form` will be assigned, too. After that, the form's `prepopulate!` method is called and the form is ready for rendering, e.g. via `#form_for`.


    op = Comment::Create.present(params)
    op.contract.prepopulate!
    @operation = op
    @model     = op.model
    @form      = op.contract


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

In a non-HTML request (e.g. for `application/json`) the params hash will be slightly modified. As the operation's model key, the request body document is passed into the operation.


    params[:comment] = request.body
    Comment::Create.(params)


By doing so the operation's representer will automatically parse and deserialize the incoming document, bypassing Rails' `ParamsParser`.

If you want the responder to compute URLs with namespaces, pass in the `:namespace` option.


  respond Comment::Create, namespace: [:api]


This will result in a call `respond_with :api, op`.

## Normalizing Params

Override #process_params! to add or remove values to params before the operation is run. This is called in #run, #respond and #present and #form.

{% highlight ruby %}
class CommentsController < ApplicationController
private
  def process_params!(params)
    params.merge!(current_user: current_user)
  end
end
{% endhighlight %}

This centralizes params normalization and doesn't require you to do that in every action manually.