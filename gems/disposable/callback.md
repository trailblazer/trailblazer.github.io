---
layout: disposable
title: "Disposable Callbacks"
gems:
  - ["disposable", "apotonick/disposable", "0.4"]
---

# Disposable: Callback

Callbacks in Disposable implement the [Imperative Callback](/gems/operation/callback.html) pattern.

## Declarative API

A `Callback::Group` allows defining nested callbacks.

    class Group < Disposable::Callback::Group
      on_change :change!

      collection :songs do
        on_add :notify_album!
      end

      # on_change :rehash_name!, property: :title
    end

Per default, callback methods will be invoked on the respective group. In nested setups, this means you also need to nest the method implementation.

    class Group < Disposable::Callback::Group
      on_change :change!

      def change!(twin, options)
        options[:string] << "change!"
      end

      collection :songs do
        on_add :notify_album!

        def notify_album!(twin, options)
          options[:string] << "notify_album!"
        end
      end
    end

## Invocation

A group is invoked using `call`.

    Group.new(twin).()

## Context

You can use an arbitrary context object to implement the callback methods.

    class CallbackImplementation
      def change!(twin, options)
        options[:string] << "change!"
      end

      def notify_album!(twin, options)
        options[:string] << "notify_album!"
      end
    end

When invoking, specify it using the `:context` option.

    Group.new(twin).(context: CallbackImplementation.new)

This allows leaving the `Group` free of implementation, as a pure definition of events, only. Also, note that you don't have any nesting with a context object, all methods are implemented on the same level in a simple object.

## Options

You may pass arbitrary options to all callback methods.

    Group.new(twin).(context: CallbackImplementation.new, string: "")

This allows injecting dependencies without global state.

    class CallbackImplementation
      def change!(twin, options)
        options[:string] << "change!"
      end
