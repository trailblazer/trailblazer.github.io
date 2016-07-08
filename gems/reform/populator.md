---
layout: reform
title: "Reform Populators"
---

# Populating

Reform has two completely separated modes for form setup. One when rendering the form and one when populating the form in `validate`.

[Prepopulating](/gems/reform/prepopulator.html) is helpful when you want to fill out fields (aka. _defaults_) or add nested forms before rendering. [Populating](/gems/reform/populators.html) is invoked in `validate` and will add nested forms depending on the incoming hash.

This page discusses the latter.

Populators, matching by IDs, deleting items, and much more, is discussed in detail in the chapters _Nested Forms_ and _Mastering Forms_ of the [Trailblazer book](/books/trailblazer.html).

## Populators: The Problem

Populators in Reform are only involved when validating the form.

In `#validate`, you pass a nested hash to the form. Reform per default will try to match nested hashes to nested forms. But often the incoming hash and the existing object graph are not matching 1-to-1. That's where populators enter the stage.

Let's say you have the following model.

    album = Album.new(songs: [])

The album contains an empty songs collection.

Your form looks like this.

    class AlbumForm < Reform::Form
      collection :songs do
        property :name
      end
    end

Here's how you'd typically validate an incoming hash.

    form = AlbumForm.new(album)
    form.validate({songs: [{name: "Midnight Rendezvous"}]})

Reform will now try to deserialize every nested `songs` item to a nested form. So, in pseudo-code, this happens in `validate`.

    form.songs[0].validate({name: "Midnight Rendezvous"})

Intuitively, you will expect Reform to create an additional song with the name "Midnight Rendevouz".  However, this is not how it works and will crash, since `songs[0]` doesn't exist. There is no nested form to represent that fragment, yet, since the original `songs` collection in the model was empty!

Reform per design makes no assumptions about how to create nested models. You have to tell it what to do in this *out-of-sync* case.

You need to configure a populator to engage Reform in the proper deserialization.

### Populator Invocation

Regardless of the populator type, keep in mind that a populator is only called if an incoming fragment for that property is present.

    form.validate({songs: [{name: "Midnight Rendezvous"}]}) # songs present.

Running with our example, the following validation will _not_ trigger any populator.

    form.validate({})          # empty.
    form.validate({songs: []}) # not empty, but no items!

## Populate_if_empty

To let Reform create a new model wrapped by a nested form for you use `:populate_if_empty`. That's the easiest form of population.

    class AlbumForm < Reform::Form
      collection :songs, populate_if_empty: Song do
        property :name
      end
    end

When traversing the incoming `songs:` collection, fragments without a counterpart nested form will be created for you with a new `Song` object.

    form.validate({songs: [{name: "Midnight Rendezvous"}]})

Reform now creates a `Song` instance and nests it in the form since it couldn't find `form.songs[0]`.

Note that the matching from fragment to form works by index, any additional matching heuristic has to be implemented manually.

## Populate_if_empty: Custom

You can also create the object yourself and leverage data from the traversed fragment, for instance, to try to find a `Song` object by name, first, before creating a new one.


    class AlbumForm < Reform::Form
      collection :songs,
        populate_if_empty: ->(fragment:, **) do
          Song.find_by(name: fragment["name"]) or Song.new
        end


The result from this block will be automatically added to the form graph.

You can also provide an instance method on the respective form.


    class AlbumForm < Reform::Form
      collection :songs, populate_if_empty: :populate_songs! do
        property :name
      end

      def populate_songs!(fragment:, **)
        Song.find_by(name: fragment["name"]) or Song.new
      end

## Populate_if_empty: Arguments

The only argument passed to `:populate_if_empty` block or method is an options hash. It contains currently traversed `:fragment`, the `:index` (collections, only) and several more options.

The result of the block will be automatically assigned to the form for you. Note that you can't use the twin API in here, for example to reorder a collection. If you want more flexibility, use `:populator`.

## Populator

While the `:populate_if_empty` option is only called when no matching form was found for the input, the `:populator` option is always invoked and gives you maximum flexibility for population. They're exclusive, you can only use one of the two.

Again, note that populators won't be invoked if there's no incoming fragment(s) for the populator's property.

## Populator: Collections

A `:populator` for collections is executed for every collection fragment in the incoming hash.

    form.validate({
      songs: [
        {name: "Midnight Rendezvous"},
        {name: "Information Error"}
      ]
    })

The following `:populator` will be executed twice.

    class AlbumForm < Reform::Form
      collection :songs,
        populator: -> (collection:, index:, **) do
          if item = collection[index]
            item
          else
            collection.insert(index, Song.new)
          end
        end

This populator checks if a nested form is already existing by using `collection[index]`. While the `index` keyword argument represents where we are in the incoming array traversal, `collection` is a convenience from Reform, and is identical to `self.songs`.

Note that you manually have to check whether or not a nested form is already available (by index or ID) and then need to add it using the form API writers.

BTW, the `:populator` option accepts blocks and instance method names.

## Populator: Return Value

It is very important that each `:populator` invocation returns the *form* that represents the fragment, and not the model. Otherwise, deserialization will fail.

Here are some return values.

    populator: -> (collection:, index:, **) do
      songs[index]              # works, unless nil
      collection[index]         # identical to above
      songs.insert(1, Song.new) # works, returns form
      songs.append(Song.new)    # works, returns form
      Song.new                  # crashes, that's no form
      Song.find(1)              # crashes, that's no form

Always make sure you return a form object, and not a model.

## Populator: Avoiding Index

In many ORMs, the order of has_many associations doesn't matter, and you don't need to use the `index` for appending.

    collection :songs,
      populator: -> (collection:, index:, **) do
        if item = collection[index]
          item
        else
          collection.append(Song.new)
        end
      end

Often, it is better to [match by ID](#populator-match-by-id) instead of indexes.

## Populator: Single Property

Naturally, a `:populator` for a single property is only called once.

    class AlbumForm < Reform::Form
      property :composer,
        populator: -> (model:, **) do
          model || self.composer= Artist.new
        end

A single populator works identical to a collection one, except for the `model` argument, which is equally to `self.composer`.

## Populator: Match by ID

[This is described in chapter _Authentication_ in the Trailblazer book.]

Per default, Reform matches incoming hash fragments and nested forms by their order. It doesn't know anything about IDs, UUIDs or other persistence mechanics.

You can use `:populator` to write your own matching for IDs.

    collection :songs,
      populator: ->(fragment:, **) {
        # find out if incoming song is already added.
        item = songs.find { |song| song.id == fragment["id"].to_i }

        item ? item : songs.append(Song.new)
      }

Note that a `:populator` requires you to add/replace/update/delete the model yourself. You have access to the form API here since the block is executed in form instance context.

Again, it is important to [return the new form](#populator-return-value) and not the model.

This naturally works for single properties, too.

    property :artist,
      populator: ->(fragment:, **) {
        artist ? artist : self.artist = Artist.find_by(id: fragment["id"])
      }

## Delete

Populators can not only create, but also destroy. Let's say the following input is passed in.

    form.validate({
      songs: [
        {"name"=>"Midnight Rendezvous", "id"=>2, "delete"=>"1"},
        {"name"=>"Information Error"}
      ]
    })

You can implement your own deletion.

    collection :songs,
      populator: ->(fragment:, **) {
        # find out if incoming song is already added.
        item = songs.find { |song| song.id.to_s == fragment["id"].to_s }

        if fragment["delete"] == "1"
          songs.delete(item)
          return skip!
        end

        item ? item : songs.append(Song.new)
      }

You can delete items from the graph using `delete`. To avoid this fragment being further deserialized, use `return skip!` to stop processing for this fragment.

Note that you can also use the twin's `Collection` API for finding nested twins by any field.

    populator: ->(fragment:, **) {
      item = songs.find_by(id: fragment["id"])

## Skip

Since Reform 2.1, populators can skip processing of a fragment by returning `skip!`. This will ignore this fragment as if it wasn't present in the incoming hash.

    collection :songs,
      populator: ->(fragment:, **) do
        return skip! if fragment["id"]
        # ..
      end

This won't process items that have an `"id"` field in their corresponding fragment.

## Uninitialized Collections

A problem with populators can be an uninitialized `collection` property.


    class AlbumForm < Reform::Form
      collection :songs, populate_if_empty: Song do
        property :title
      end
    end

    album = Album.new
    form  = AlbumForm.new(album)

    album.songs #=> nil
    form.songs  #=> nil

    form.validate(songs: [{title: "Friday"}])
    #=> NoMethodError: undefined method `original' for nil:NilClass


What happens is as follows.

1. In `validate`, the form can't find a corresponding nested songs form and calls the `populate_if_empty` code.
2. The populator will create a `Song` model and assign it to the parent form via `form.songs << Song.new`.
3. This crashes, as `form.songs` is `nil`.

The solution is to initialize your object correctly. This is per design. It is your job to do that as Reform/Disposable is likely to do it wrong.


    album = Album.new(songs: [])
    form  = AlbumForm.new(album)


With ORMs, the setup happens automatically, this only appears when using `Struct` or other POROs as models.



