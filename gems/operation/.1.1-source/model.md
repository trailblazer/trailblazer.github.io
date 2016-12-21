---
layout: operation
title: "Operation::Model"
redirect_from:
  - /gems/operation/model.html
---

# Operation::Model

Including `Model` will add simple CRUD semantics to your operation to find/create a model in `#setup!`.

Note that this is not limited to ActiveRecord.


	class Create < Trailblazer::Operation
	  include Model
	  model Comment, :create


Using the `::model` method you _have to_ define what model class to work with. The second argument specifies the action.

This will override `model!` as follows.


	class Create < Trailblazer::Operation
	  def model!
	    Comment.new
	  end


The model is automatically created for you in `#setup!` and hence available in `process`.

## Validation

In `validate`, you don't need to provide the model anymore.


	def process(params)
	  model #=> <Comment body=""> # created via #model!.
	  validate(params[:thing]) do
	    ..
	  end
	end


## Actions

The following actions for `::model` are available.

* `:create` calls `Comment.new`
* `:update` or `:find` will execute `Comment.find(params[:id])`

In `process`, you now have a new or existing `model` available.


## API

You may override `#instantiate_model!`, `create_model!` or `update_model!` from the `Model` module if you need to change behavior.


## Discussion

Note that this is really simple behavior. Do not use this module when you plan to use more complex models.
