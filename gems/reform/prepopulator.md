---
layout: reform
permalink: /gems/reform/prepopulator.html
title: "Trailblazer: Reform Prepopulators"
---

# Prepopulating

Reform has two completely separated modes for form setup. One when rendering the form and one when populating the form in `validate`.

[Prepopulating](/gems/reform/prepopulator.html) is helpful when you want to fill out fields (aka. _defaults_) or add nested forms before rendering.

[Populating](/gems/reform/populators.html) is invoked in `validate` and will add nested forms depending on the incoming hash.

This page explains prepopulation used to prepare the form for rendering.

## Configuration

You can use the `:prepopulator` option on every property or collection.

  class AlbumForm < Reform::Form
    property :artist, prepopulator: ->(options) { self.artist = Artist.new } do
      property :name
    end


The option value can be a lambda or an instance method name.

In the block/method, you have access to the form API and can invoke any kind of logic to prepopulate your form. Note you need to assign models for nested form using their writers.


## Invocation

Prepopulation must be invoked manually.


    form = AlbumForm.new(Album.new)
    form.artist #=> nil

    form.prepopulate!

    form.artist #=> <nested ArtistForm @model=<Artist ..>>


This explicit call must happen before the form gets rendered. For instance, in Trailblazer, this happens in the controller action.


## Prepopulate is not Populate

`:populator` and `:populate_if_empty` will be run automatically in `validate`. Do not call `prepopulate!` before `validate` if you use the populator options. This will usually result in "more" nested forms being added as you wanted (unless you know what you're doing).

Prepopulators are a concept designed to **prepare a form for rendering**, whereas populators are meant to **set up the form in `validate`** when the input hash is deserialized.

This is explained in the _Nested Forms_ chapter of the Trailblazer book. Please read it first if you have trouble understanding this, and then open an issue.

## Options

Options may be passed. They will be available in the `:prepopulator` block.


    class AlbumForm < Reform::Form
      property :title, prepopulator: ->(options) { self.title = options[:def_title] }
    end


You can then pass arbitrary arguments to `prepopulate!`.


    form.title #=> nil

    form.prepopulate!(def_title: "Roxanne")

    form.title #=> "Roxanne"


The arguments passed to the `prepopulate!` call will be passed straight to the block/method.


This call will be applied to the entire nested form graph recursively _after_ the currently traversed form's prepopulators were run.


## Execution

The blocks are run in form instance context, meaning you have access to all possible data you might need. With a symbol, the same-named method will be called on the form instance, too.

Note that you have to assign the pre-populated values to the form by using setters. In turn, the form will automatically create nested forms for you.

This is especially cool when populating collections.


    property :songs,
      prepopulator: ->(*) { self.songs << Song.new if songs.size < 3 } do


This will always add an empty song form to the nested `songs` collection until three songs are attached. You can use the `Twin::Collection` [API](/gems/disposable/collection.html) when adding, changing or deleting items from a collection.

Note that when calling `#prepopulate!`, your `:prepopulate` code for all existing forms in the graph will _be executed_ . It is up to you to add checks if you need that.

## Overriding

You don't have to use the `:prepopulator` option. Instead, you can simply override `#prepopulate!` itself.


    class AlbumForm < Reform::Form
      def prepopulate!(options)
        self.title = "Roxanne"
        self.artist = Artist.new(name: "The Police")
      end



# Defaults

There's different alternatives for setting a default value for a formerly empty field.

1. Use `:prepopulator` as [described here](#configuration). Don't forget to call `prepopulate!` before rendering the form.
2. Override the reader of the property. This is not recommended as you might screw things up. Remember that the property reader is called for presentation (in the form builder) and for validation in `#validate`.


    property :title

    def title
      super or "Unnamed"
    end
