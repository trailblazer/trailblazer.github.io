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

A representer simply defines the fields that will be mapped to the document. You can then simply decorate an object and render or parse. Here's an example.

    SongRepresenter.new(song).to_json #=> {"id": 1, title":"Fallout"}

The details are being discussed in the [public API](#public-api) section.

### Representer Modules

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