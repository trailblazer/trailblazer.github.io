---
layout: representable
title: "Representable API"
---

# Representable API

In Representable, we differentiate between three APIs.

The [declarative API](#declarative-api) is how we define representers. You can learn how to use those representers by reading about the very brief [public API](#public-api). Representable is extendable without having to hack existing code: the [function API](function-api.html) documents how to use its options to achieve what you need.

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

A representer module is also a good way to share configuration and logic across decorators.

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

Representable can also handle compositions of objects. This works for both `property` and `collection`.

For example, a song could nest an artist object.

    Song   = Struct.new(:id, :title, :artist)
    Artist = Struct.new(:id, :name)

    artist = Artist.new(2, "The Police")
    song = Song.new(1, "Fallout", artist)

Here's a better view of that object graph.

    #<struct Song
      id=1,
      title="Fallout",
      artist=#<struct Artist
        id=2,
        name="The Police">>

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

When parsing, per default Representable will want to instantiate an object for every nested, typed fragment.

You have to tell Representable what object to instantiate for the nested `artist:` fragment.

    class SongRepresenter < Representable::Decorator
      # ..
      property :artist, decorator: ArtistRepresenter, class: Artist
    end

This happens via the `:class` option. Now, the document can be parsed and a nested `Artist` will be created by the parsing.

    song = Song.new # nothing set.

    SongRepresenter.new(song).
        from_json('{"id":1,title":"Fallout",artist:{"id":2,"name":"The Police"}}')

    song.artist.name #=> "The Police"

The default behavior is - admittedly - very primitive. Representable's parsing allow rich mapping, object creation and runtime checks. Read about [populators](populator.html) to learn how that works.

### Document Nesting

Not always does the structure of the desired document map to your objects. The `::nested` method allows structuring properties within a separate section while still mapping the properties to the outer object.

Imagine the following document.

    {"title": "Roxanne",
     "details":
       {"track": 3,
        "length": "4:10"}
    }

However, in the `Song` class, there's no such concept as `details`.

    Song = Struct.new(:title, :track, :length)


Both track and length are properties of the song object itself. Representable gives you ::nested to map the virtual `details` section to the song instance.

    class SongRepresenter < Representable::Decorator
      include Representable::JSON

      property :title

      nested :details do
        property :track
        property :length
      end
    end

Accessors for the nested properties will still be called on the song object. And as always, this works both ways - for rendering and parsing.

### Wrapping

You can automatically wrap a document.

    class SongRepresenter < Representable::Decorator
      include Representable::JSON

      self.representation_wrap= :song

      property :title
      property :id
    end

This will add a container for rendering and parsing.

    SongRepresenter.new(song).to_json
    #=> {"song":{"title":"Fallout","id":1}}

Setting `self.representation_wrap = true` will advice representable to figure out the wrap itself by inspecting the represented object class.

Note that `representation_wrap` is a dynamic function option.

    self.representation_wrap = ->(user_options:) { user_options[:my_wrap] }

This would allow to provide the wrap manually.

    decorator.to_json(user_options: { my_wrap: "hit" })

### Suppressing Nested Wraps

When reusing a representer for a nested document, you might want to suppress its `representation_wrap=` for the nested fragment.

Reusing `SongRepresenter` from the last section in a nested setup allows suppressing the wrap via the `:wrap` option.

```ruby
class AlbumRepresenter < Representable::Decorator
  include Representable::JSON

  collection :songs,
    decorator: SongRepresenter, # SongRepresenter defines representation_wrap.
     wrap:     false            # turn off :song wrap.
end
```

The `representation_wrap` from the nested representer now won't be rendered and parsed.

```ruby
AlbumRepresenter.new(album).to_json
#=> "{\"songs\": [{\"name\": \"Roxanne\"}]}"
```

Note that this only works for JSON and Hash at the moment.


### Inheritance

Properties can be inherited across representer classes and modules.

    class SongRepresenter < Representable::Decorator
      include Representable::JSON

      property :id
      property :title
    end

What if you need a refined representer to also add the artist. Use inheritance.

    class SongWithArtistRepresenter < SongRepresenter
      property :artist do
        property :name
      end
    end

All configuration from `SongRepresenter` will be inherited, making the properties on `SongWithArtistRepresenter`: `id`, `title`, and `artist`. The original `SongRepresenter` will stay as it is.

### Composition

You can also use modules and decorators together to compose representers.

    module GenericRepresenter
      include Representable::JSON

      property :id
    end

This can be included in other representers and will extend their configuration.

    class SongRepresenter < Representable::Decorator
      include GenericRepresenter

      property :title
    end

As a result, `SongRepresenter` will contain the good old `id` and `title` property.

### Overriding Properties

You might want to override a particular property in an inheriting representer. Successively calling `property(name)` will override the former definition - exactly as you know it from overriding methods in Ruby.

    class CoverSongRepresenter < SongRepresenter
      include Representable::JSON

      property :title, as: :name # overrides that definition.
    end

### Partly Overriding Properties

Instead of fully replacing a property, you can extend it with `:inherit`. This will _add_ your new options and override existing options in case the one you provided already existed.

    class SongRepresenter < Representable::Decorator
      include Representable::JSON

      property :title, as: :name, render_nil: true
    end

You can now inherit properties but still override or add options.

    class CoverSongRepresenter < SongRepresenter
      include Representable::JSON

      property :title, as: :songTitle, default: "n/a", inherit: true
    end


Using the :inherit, this will result in a property having the following options.

    property :title,
      as:         :songTitle, # overridden in CoverSongRepresenter.
      render_nil: true        # inherited from SongRepresenter.
      default:    "n/a"       # defined in CoverSongRepresenter.

The `:inherit` option works for both inheritance and module composition.

### Inherit With Inline Representers

`:inherit` also works applied with inline representers.

    class SongRepresenter < Representable::Decorator
      include Representable::JSON

      property :title
      property :artist do
        property :name
      end
    end

You can now override or add properties within the inline representer.

    class HitRepresenter < SongRepresenter
      include Representable::JSON

      property :artist, inherit: true do
        property :email
      end
    end

Results in a combined inline representer as it inherits.

    property :artist do
      property :name
      property :email
    end

Naturally, `:inherit` can be used within the inline representer block.

Note that the following also works.

    class HitRepresenter < SongRepresenter
      include Representable::JSON

      property :artist, as: :composer, inherit: true
    end

This renames the property but still inherits all the inlined configuration.

Basically, `:inherit` copies the configuration from the parent property, then merges in your options from the inheriting representer. It exposes the same behaviour as `super` in Ruby - when using `:inherit` the property must exist in the parent representer.

## Feature

If you need to include modules in all inline representers automatically, register it as a feature.

```ruby
class AlbumRepresenter < Representable::Decorator
  include Representable::JSON
  feature Link # imports ::link

  link "/album/1"

  property :hit do
    link "/hit/1" # link method imported automatically.
  end
```

Nested representers will `include` the provided module automatically.

## Execution Context

Readers and Writers for properties will usually be called on the `represented` object. If you want to change that, so the accessors get called on the decorator instead, use `:exec_context`.

```ruby
class SongRepresenter < Representable::Decorator
  property :title, exec_context: :decorator

  def title
    represented.name
  end
end
```

## Callable Options

While lambdas are one option for dynamic options, you might also pass a "callable" object to a directive.

```ruby
class Sanitizer
  include Uber::Callable

  def call(represented, fragment, doc, *args)
    fragment.sanitize
  end
end
```

Note how including `Uber::Callable` marks instances of this class as callable. No `respond_to?` or other magic takes place here.

```ruby
property :title, parse_filter: Santizer.new
```

This is enough to have the `Sanitizer` class run with all the arguments that are usually passed to the lambda (preceded by the represented object as first argument).

## Read/Write Restrictions

Using the `:readable` and `:writeable` options access to properties can be restricted.

```ruby
property :title, readable: false
```

This will leave out the `title` property in the rendered document. Vice-versa, `:writeable` will skip the property when parsing and does not assign it.

## Coercion

If you need coercion when parsing a document you can use the Coercion module which uses [virtus](https://github.com/solnic/virtus) for type conversion.

Include Virtus in your Gemfile, first.

```ruby
gem 'virtus', ">= 0.5.0"
```

Use the `:type` option to specify the conversion target. Note that `:default` still works.

```ruby
class SongRepresenter < Representable::Decorator
  include Representable::JSON
  include Representable::Coercion

  property :recorded_at, type: DateTime, default: "May 12th, 2012"
end
```

Coercing values only happens when rendering or parsing a document. Representable does not create accessors in your model as `virtus` does.

Note that we think coercion in the representer is wrong, and should happen on the underlying object. We have a rich [coercion/constraint API for twins](/gems/disposable/coercion.html).


## Symbol Keys

When parsing, Representable reads properties from hashes using their string keys.

```ruby
song.from_hash("title" => "Road To Never")
```

To allow symbol keys also include the `AllowSymbols` module.

```ruby
class SongRepresenter < Representable::Decorator
  include Representable::Hash
  include Representable::Hash::AllowSymbols
  # ..
end
```

This will give you a behavior close to Rails' `HashWithIndifferentAccess` by stringifying the incoming hash internally.


## Defaults

The `defaults` method allows setting options that will be applied to all property definitions of a representer.

    class SongRepresenter < Representable::Decorator
      include Representable::JSON

      defaults render_nil: true

      property :id
      property :title
    end

This will include `render_nil: true` in both `id` and `title` definitions, as if you'd provided that option each time.

You can also have dynamic option computation at compile-time.

    class SongRepresenter < Representable::Decorator
      include Representable::JSON

      defaults do |name, options|
        { as: name.camelize }
      end

The `options` hash combines the user's and Representable computed options.

    property :id, skip: true

    defaults do |name, options|
      options[:skip] ? { as: name.camelize } : {}
    end

Note that the dynamic `defaults` block always has to return a hash.

Combining those two forms also works.

    class SongRepresenter < Representable::Decorator
      include Representable::JSON

      defaults render_nil: true do |name|
        { as: name.camelize }
      end

All defaults are inherited to subclasses or including modules.

## Standalone Hash

If it's required to represent a bare hash object, use `Representable::JSON::Hash` instead of `Representable::JSON`.

This is sometimes called a _lonely hash_.

    require "representable/json/hash"

    class SongsRepresenter < Representable::Decorator
      include Representable::JSON::Hash
    end

You can then use this hash decorator on instances of `Hash`.

    hash = {"Nick" => "Hyper Music", "El" => "Blown In The Wind"}
    SongsRepresenter.new(hash).to_json
    #=> {"Nick":"Hyper Music","El":"Blown In The Wind"}

This works both ways.

A lonely hash starts to make sense especially when the values are nested objects that need to be represented, too. You can configure the nested value objects using the `values` method. This works exactly as if you were defining an inline representer, accepting the same options.

    class SongsRepresenter < Representable::Decorator
      include Representable::JSON::Hash

      values class: Song do
        property :title
      end
    end

You can now represents nested objects in the hash, both rendering and parsing-wise.

    hash = {"Nick" => Song.new("Hyper Music")}
    SongsRepresenter.new(hash).to_json

In XML, use `XML::Hash`. If you want to store hash attributes in tag attributes instead of dedicated nodes, use `XML::AttributeHash`.

## Standalone Collection

Likewise, you can represent _lonely collections_, instances of `Array`.

    require "representable/json/collection"

    class SongsRepresenter < Representable::Decorator
      include Representable::JSON::Collection

      items class: Song do
        property :title
      end
    end


Here, you define how to represent items in the collection using `items`.

Note that the items can be simple scalar values or deeply nested objects.

    ary = [Song.new("Hyper Music"), Song.new("Screenager")]
    SongsRepresenter.new(ary).to_json
    #=> [{"title":"Hyper Music"},{"title":"Screenager"}]

Note that this also works for XML.

## Standalone Collection: to_a

Another trick to represent collections is using a normal representer with exactly one collection property named `to_a`.

    class SongsRepresenter < Representable::Decorator
      include Representable::JSON # note that this is a plain representer.

      collection :to_a, class: Song do
        property :title
      end
    end


You can use this representer the way you already know and appreciate, but directly on an array.

    ary = []
    SongsRepresenter.new(ary).from_json('[{"title": "Screenager"}]')

In order to grab the collection for rendering or parsing, Representable will now call `array.to_a`, which returns the array itself.

## Automatic Collection Representer

Instead of explicitly defining representers for collections using a ["lonely collection"](#standalone-collection), you can let Representable  do that for you.

You define a singular representer, Representable will infer the collection representer.

Rendering a collection of objects comes for free, using `for_collection`.

    songs = Song.all
    SongRepresenter.for_collection.new(songs).to_json
    #=> '[{"title": "Sevens"}, {"title": "Eric"}]'

`SongRepresenter.for_collection` will return a collection representer class.

For parsing, you need to provide the class for the nested items. This happens via `collection_representer` in the representer class.

```ruby
class SongsRepresenter < Representable::Decorator
  include Representable::JSON
  property :title

  collection_representer class: Song
end
```

You can now parse collections to `Song` instances.

    json  = '[{"title": "Sevens"}, {"title": "Eric"}]'

    SongRepresenter.for_collection.new([]).from_json(json)

Note: the implicit collection representer internally is implemented using a lonely collection. Everything you pass to `::collection_representer` is simply provided to the `::items` call in the lonely collection. That allows you to use `:populator` and all the other goodies, too.

## Automatic Singular and Collection

In case you don't want to know whether or not you're working with a collection or singular model, use `represent`.

    # singular
    SongRepresenter.represent(Song.find(1)).to_json
    #=> '{"title": "Sevens"}'

    # collection
    SongRepresenter.represent(Song.all).to_json
    #=> '[{"title": "Sevens"}, {"title": "Eric"}]'
```

`represent` figures out the correct representer for you. This works for parsing, too.

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

### to_hash and from_hash
