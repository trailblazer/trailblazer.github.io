---
layout: representable
title: "Representable API"
---

# Representable API

In Representable, we differentiate between three different APIs.

The [declarative API](#declarative-api) is how we define representers. You can learn how to use those representers by reading about the very brief [public API](#public-api). Representable is extendable without having to hack existing code: the [function API](#function-api) documents how to use its options to achieve what you need.

## Declarative API

To render objects to documents or parse documents to objects, you need to define a representer.

A representer can either be a class (called _decorator_) or a module (called _representer module_). Throughout the docs, we will use decorators as they are cleaner and faster, but keep in mind you can also use modules.

    require 'representable/json'

    class SongRepresenter < Representable::Decorator
      include Representable::JSON

      property :id
      property :title
    end

A representer simply defines the fields that will be mapped to the document using `property` or `collection`. You can then decorate an object and render or parse. Here's an example.

    SongRepresenter.new(song).to_json #=> {"id": 1, title":"Fallout"}

The details are being discussed in the [public API](#public-api) section.

### Representer Modules

Instead of using classes as representers, you can also leverage modules which will then get mixed into the represented object.

    module SongRepresenter
      include Representable::JSON

      property :id
      property :title
    end

The API in a module representer is identical to decorators. However, the way you apply them is different.

    song.extend(SongRepresenter).to_json #=> {"id": 1, title":"Fallout"}

There's two drawbacks with this approach.

1. You pollute the represented object with the imported representer methods (e.g. `to_json`).
2. Extending an object at run-time is costly and with many `extend`s there will be a noteable performance decrease.

Throughout this documentation, we will use decorator as examples to encourage this cleaner and faster approach.

### Collections

Not everything is a scalar value. Sometimes an object's property can be a collection of values. Use `collection` to represent arrays.

    class SongRepresenter < Representable::Decorator
      include Representable::JSON

      property :id
      property :title
      collection :composer_ids
    end

The new collection `composer_ids` has to be enumeratable object, like an array.

    Song = Struct.new(:id, :title, :composer_ids)
    song = Song.new(1, "Fallout", [2, 3])

    song.to_json #=> {"id": 1, title":"Fallout", composer_ids:[2,3]}

Of course, this works also for parsing. The incoming `composer_ids` will override the old collection on the represented object.

### Nesting

Representable can also handle compositions of objects. For example, a song could nest an artist object.

    Song   = Struct.new(:id, :title, :artist)
    Artist = Struct.new(:id, :name)

    artist = Artist.new(2, "The Police")
    song = Song.new(1, "Fallout", artist)

### Inline Representer

The easiest way to nest representers is by using an inline representer.

    class SongRepresenter < Representable::Decorator
      include Representable::JSON

      property :id
      property :title

      property :artist do
        property :id
        property :name
      end
    end

Note that you can have any levels of nesting.

### Explicit Representer

Sometimes you want to compose two existing, stand-alone representers.

    class ArtistRepresenter < Representable::Decorator
      include Representable::JSON

      property :id
      property :name
    end

To maximize reusability of representers, you can reference a nested representer using the `:decorator` option.

    class SongRepresenter < Representable::Decorator
      include Representable::JSON

      property :id
      property :title

      property :artist, decorator: ArtistRepresenter
    end

This is identical to an inline representer, but allows you to reuse `ArtistRepresenter` elsewhere.

Note that the `:extend` and `:decorator` options are identical. They can both reference a decorator or a module.

### Nested Rendering

Regardless of the representer types you use, rendering will result in a nested document.

    SongRepresenter.new(song).to_json
    #=> {"id": 1, title":"Fallout", artist:{"id":2, "name":"The Police"}}

### Nested Parsing

When parsing, .......

    song = Song.new(nil, nil, Artist.new)

    SongRepresenter.new(song).
        from_json('{"id":1,title":"Fallout",artist:{"id":2,"name":"The Police"}}')

    song.artist.name #=> "The Police"

Note that the artist object has to be present

## Public API

When decorating an object with a representer, the object needs to provide readers for every defined `property` - and writers, if you're planning to parse.

### Accessors

In our small `SongRepresenter` example, the represented object has to provide `#id` and `#title` for rendering.

    Song = Struct.new(:id, :title)
    song = Song.new(1, "Fallout")

### Rendering

You can render the document by decorating the object and calling the serializer method.

    SongRepresenter.new(song).to_json #=> {"id":1, title":"Fallout"}

When rendering, the document fragment is read from the represented object using the getter (e.g. `Song#id`).

Since we use `Representable::JSON` the serializer method is `#to_json`.

For other format engines the serializer method will have the following name.

* `Representable::JSON#to_json`
* `Representable::JSON#to_hash` (provides a hash instead of string)
* `Representable::Hash#to_hash`
* `Representable::XML#to_xml`
* `Representable::YAML#to_yaml`

### Parsing

Likewise, parsing will read values from the document and write them to the represented object.

    song = Song.new
    SongRepresenter.new(song).from_json('{"id":1, "title":"Fallout"}')
    song.id    #=> 1
    song.title #=> "Fallout"

When parsing, the read fragment is written to the represented object using the setter (e.g. `Song#id=`).

For other format engines, the deserializing method is named analogue to the serializing counterpart, where `to` becomes `from`. For example, `Representable::XML#from_xml` will parse XML if the format engine is mixed into the representer.

### User Options

You can provide options when representing an object using the `user_options:` option.

    decorator.to_json(user_options: { is_admin: true })

Note that the `:user_options` will be accessable on all levels in a nested representer. They act like a "global" configuration and are passed to all option functions.

Here's an example where the `:if` option function evaluates a dynamic user option.

    property :id, if: ->(options) { options[:user_options][:is_admin] }

This property is now only rendered or parsed when `:is_admin` is true.

Using Ruby 2.1's keyword arguments is highly recommended - to make that look a bit nicer.

    property :id, if: ->(user_options:, **) { user_options[:is_admin] }

### Nested User Options

Representable also allows passing nested options to particular representers. You have to provide the property's name to do so.

    decorator.to_json(artist: { user_options: { is_admin: true } })

This will pass the option to the nested `artist`, only. Note that this works with any level of nesting.

### Include and Exclude

Representable supports two top-level options.

`:include` allows defining a set of properties to represent. The remaining will be skipped.

    decorator.to_json(include: [:id])  #=> {"id":1}

 The other, `:exclude`, will - you might have guessed it already - skip the provided properties and represent the remaining.

    decorator.to_json(exclude: [:id, :artist])  #=> {"title":"Fallout"}

As always, these options work both ways, for rendering _and_ parsing.

Note that you can also nest `:include` and `:exclude`.

    decorator.to_json(artist: { include: [:name] })
    #=> {"id":1, "title":"Fallout", "artist":{"name":"Sting"}}

## Function API



## Standalone Collections

You can also represent collections without a "real" object holding that collection. This is sometimes also called _lonely collection_.


    collection :to_a do
      property :id
    end