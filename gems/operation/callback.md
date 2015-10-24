---
layout: operation
title: Trailblazer: Operation Callback
---

## Composable Interface

Using `Operation::callback` simply creates a new `Disposable::Callback::Group` class for you.


    class Comment::Create < Trailblazer::Operation
      callback :after_save do
        # this is a Disposable::Callback::Group class.
      end


Successive calls with the same name will extend the group.


    class Comment::Create < Trailblazer::Operation
      callback :after_save do
        on_change :notify!
      end

      callback :after_save do
        on_change :cleanup!
      end


Dispatching `:after_save` will now run `#notify!`, then `#cleanup!`.

Note that this also works when inheriting callbacks from a parent operation. You can extend it without changing the parent's callbacks.

If you prefer keeping callbacks in separate classes, you can do so.


    class AfterSave < Disposable::Callback::Group
      on_change :notify!
    end


Register it using `::callback`.


    class Comment::Create < Trailblazer::Operation
      callback :after_save, AfterSave


As always, the callback can be extended locally.


    class Comment::Create < Trailblazer::Operation
      callback :after_save, AfterSave do
        on_update :cleanup!
      end


Since Trailblazer copies the callback group, this will change the callbacks only for this operation.

## Custom Callbacks

You can attach any callback object you like to an operation. It will receive the contract in the initializer and has to respond to `#call`.


    class MyCallback
      def initialize(contract)
        @contract = contract
      end

      def call(options) # this is {context: operation} normally.
        User::Mailer.(@contract.email)
      end
    end


Use `::callback` to register it as a group.


    class Comment::Create < Trailblazer::Operation
      callback :after_save, MyCallback
