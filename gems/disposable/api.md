---
layout: disposable
title: "Disposable API"
---

# Twin API

**A twin is an intermediate object** that usually sits between persistence layer and your application code. It's a _domain object_ that helps you model your application domain. Sometimes this is called _decorator_.

Often, a twin maps directly to one persistent _"model"_. However, twins are absolutely not limited to your database layout - the opposite is the case. One twin can be a composition of many underlying models, with renaming, delegating, and more mapping features, that allow you modelling objects for your application, and not objects dictated by your database layout.

## Declarative API

Every twin is based on a schema which comes in form of a `Disposable::Twin` class.

	class AlbumTwin < Disposable::Twin
	  property :title

	  collection :songs do
	    property :name
	    property :index
	  end

	  property :artist do
	    property :full_name
	  end
	end

The self-explaining DSL known from many Trailblazer gems allows to define flat or nested twins.

## Unnest

To expose a nested property on an outer level, use `::unnest`.

    class AlbumTwin < Disposable::Twin
      property :artist do
        property :email
      end

      unnest :email, from: :artist
    end

The `email` accessors will now be on top-level, hiding the nested structure to the outside world.

    album = Album.find(1)
    twin  = AlbumTwin.new(album)

    twin.email #=> "duran@duran.to"
    twin.email = "duran@duran.com"

When `sync`ing, only the nested structure will be considered.

    twin.sync
    album.artist.email #=> "duran@duran.com"

## Public API

The public twin API is unbelievably simple.

1. `Twin::new` creates and populates the twin.
1. `Twin#"reader"` returns the value or nested twin of the property.
1. `Twin#"writer"=(v)` writes the value to the twin, not the model.
1. `Twin#sync` writes all values to the model.
1. `Twin#save` writes all values to the model and calls `save` on configured models.


## Constructor

Twins get populated from the decorated models.

```ruby
Song   = Struct.new(:name, :index)
Artist = Struct.new(:full_name)
Album  = Struct.new(:title, :songs, :artist)
```

You need to pass model and the facultative options to the twin constructor.

```ruby
album = Album.new("Nice Try")
twin  = AlbumTwin.new(album, playable?: current_user.can?(:play))
```

## Readers

This will create a composition object of the actual model and the hash.

```ruby
twin.title     #=> "Nice Try"
twin.playable? #=> true
```

You can also override `property` values in the constructor:

```ruby
twin = AlbumTwin.new(album, title: "Plasticash")
twin.title #=> "Plasticash"
```

## Writers

Writers change values on the twin and are _not_ propagated to the model.

```ruby
twin.title = "Skamobile"
twin.title  #=> "Skamobile"
album.title #=> "Nice Try"
```

Writers on nested twins will "twin" the value.

```ruby
twin.songs #=> []
twin.songs << Song.new("Adondo", 1)
twin.songs  #=> [<Twin::Song name="Adondo" index=1 model=<Song ..>>]
album.songs #=> []
```

The added twin is _not_ passed to the model. Note that the nested song is a twin, not the model itself.

## Sync

Given the above state change on the twin, here is what happens after calling `#sync`.

```ruby
album.title  #=> "Nice Try"
album.songs #=> []

twin.sync

album.title  #=> "Skamobile"
album.songs #=> [<Song name="Adondo" index=1>]
```

`#sync` writes all configured attributes back to the models using public setters as `album.name=` or `album.songs=`. This is recursive and will sync the entire object graph.

Note that `sync` might already trigger saving the model as persistence layers like ActiveRecord can't deal with `collection= []` and instantly persist that.

You may implement your syncing manually by passing a block to `sync`.

```ruby
twin.sync do |hash|
  hash #=> {
  #  "title"     => "Skamobile",
  #  "playable?" => true,
  #  "songs"     => [{"name"=>"Adondo"...}..]
  # }
end
```

Invoking `sync` with block will _not_ write anything to the models.

Needs to be included explicitly (`Sync`).

## Save

Calling `#save` will do `sync` plus calling `save` on all nested models. This implies that the models need to implement `#save`.

```ruby
twin.save
#=> album.save
#=>      .songs[0].save

```

Needs to be included explicitly (`Save`).

## Nested Twin

Nested objects can be declared with an inline twin.

```ruby
property :artist do
  property :full_name
end
```

The setter will automatically "twin" the model.

```ruby
twin.artist = Artist.new
twin.artist #=> <Twin::Artist model=<Artist ..>>
```

You can also specify nested objects with an explicit class.

```ruby
property :artist, twin: TwinArtist
```

## Features

You can simply `include` feature modules into twins. If you want a feature to be included into all inline twins of your schema, use `::feature`.

```ruby
class AlbumTwin < Disposable::Twin
  feature Coercion

  property :artist do
    # this will now include Coercion, too.
```

## Coercion

Twins can use [dry-types](https://github.com/dry-rb/dry-types) coercion. This will override the setter in your twin, coerce the incoming value, and call the original setter. _Nothing more_ will happen.

Disposable already defines a module `Disposable::Twin::Coercion::Types` with all the Dry::Types built-in types. So you can use any of the [documented types](http://dry-rb.org/gems/dry-types/built-in-types/).

```ruby
class AlbumTwin < Disposable::Twin
  feature Coercion

  property :id, type: Types::Form::Int
```

The `:type` option defines the coercion type. You may incluce `Setup::SkipSetter`, too, as otherwise the coercion will happen at initialization time and in the setter.

```ruby
twin.id = "1"
twin.id #=> 1
```

Again, coercion only happens in the setter.

## Nilify

Coercion also supports the conversion of blank strings (`""`) into `nil`. This is known as _nilify_ and provided via the `:nilify` option.

	property :id, type: Types::Form::Int, nilify: true

This will result in the following behavior.

	twin.id = ""
	twin.id #=> nil

Note that you can use `:nilify` without specifying a `:type`.

## Defaults

Default values can be set via `:default`.

```ruby
class AlbumTwin < Disposable::Twin
  feature Default

  property :title, default: "The Greatest Songs Ever Written"
  property :composer, default: Composer.new do
    property :name, default: -> { "Object-#{id}" }
  end
end
```

Default value is applied when the model's getter returns `nil` when _initializing_ the twin.

Note that `:default` also works with `:virtual` and `readable: false`. `:default` can also be a lambda which is then executed in twin context.

## Collections

Collections can be defined analogue to `property`. The exposed API is the `Array` API.

* `twin.songs = [..]` will override the existing value and "twin" every item.
* `twin.songs << Song.new` will add and twin.
* `twin.insert(0, Song.new)` will insert at the specified position and twin.

You can also delete, replace and move items.

* `twin.songs.delete( twin.songs[0] )`

None of these operations are propagated to the model.

## Collection Semantics

In addition to the standard `Array` API the collection adds a handful of additional semantics.

* `songs=`, `songs<<` and `songs.insert` track twin via `#added`.
* `songs.delete` tracks via `#deleted`.
* `twin.destroy( twin.songs[0] )` deletes the twin and marks it for destruction in `#to_destroy`.
* `twin.songs.save` will call `destroy` on all models marked for destruction in `to_destroy`. Tracks destruction via `#destroyed`.

Again, the model is left alone until you call `sync` or `save`.

<a name="jsonb"></a>

<h2>
  Property::Hash
  <span class="gem-version">0.3.2</span>
</h2>

The `Property::Hash` module allows working with generic hash fields with any level of nesting. Instead of clumsy hash operations, you have Ruby objects.

<div class="panel">
   This module is not limited to Postgres' JSONB and hstore column type, but may also interact with <a href="http://apidock.com/rails/v4.2.1/ActiveRecord/AttributeMethods/Serialization/ClassMethods/serialize">JSON or serialized-hash columns</a>.
</div>

A serialized hash field must return a Ruby hash.

    album = Album.find(1)
    album.payload #=>
      {
        "title"=> "A View To A Kill",
        "band" => {
          "name" => "Duran Duran"
        }
      }

Here, the `payload` field is such a serialized hash field.

Letting the twin handle the hash field works via the `:field` option.

    require "disposable/twin/property/hash"

    class Album::Twin < Disposable::Twin
      feature Sync
      include Property::Hash

      property :id # or whatever you need.
      property :payload, field: :hash do
        property :title
        property :band do
          property :name
        end
      end
    end

Note that you can have any level of nesting, and are free to use `collection`.

You get fully object-oriented access to your properties.

```ruby
twin = Album::Twin.new(album)

twin.payload.band.name #=> "Duran Duran"
```

This works for writing, too.

```ruby
twin.payload.band.name = "James Bond"
```

After `sync`ing, the model's hash field will be updated.

    album.payload #=>
      {
        "title"=> "A View To A Kill",
        "band" => {
          "name" => "James Bond"
        }
      }


If you don't know the field names, you can define a scalar `property`.

    class Album::Twin < Disposable::Twin
      feature Sync
      include Property::Hash

      property :id # or whatever you need.
      property :payload, field: :hash do
        property :title
        property :band # scalar!
      end
    end

This will return the native hash.

    twin.payload.band #=> { "band" => { "name" => "Duran Duran" } }

The `Property::Hash` module also works great with [::unnest](#unnest) and is a fantastic way to get rid of migrations and data that doesn't need a dedicated column.

## Twin Collections

To twin a collection of models, you can use `::from_collection`.

```ruby
SongTwin.from_collection([song, song])
```

This will decorate every song instance using a fresh twin.

## Renaming

The `Expose` module allows renaming properties.

```ruby
class AlbumTwin < Disposable::Twin
  feature Expose

  property :song_title, from: :title
```

The public accessor is now `song_title` whereas the model's accessor needs to be `title`.

```ruby
album = OpenStruct.new(title: "Run For Cover")
AlbumTwin.new(album).song_title #=> "Run For Cover"
```

## Composition

Compositions of objects can be mapped, too.

```ruby
class AlbumTwin < Disposable::Twin
  include Composition

  property :id,    on: :album
  property :title, on: :album
  property :songs, on: :cd
  property :cd_id, on: :cd, from: :id
```

When initializing a composition, you have to pass a hash that contains the composees.

```ruby
AlbumTwin.new(album: album, cd: CD.find(1))
```

Note that renaming works here, too.


## With Representers

they indirect data, the twin's attributes get assigned without writing to the persistence layer, yet.

## With Contracts

## Overriding Getter for Presentation

You can override getters for presentation.

```ruby
class AlbumTwin < Disposable::Twin
    property :title

    def title
      super.upcase
    end
  end
```

Be careful, though. The getter normally is also called in `sync` when writing properties to the models.

You can skip invocation of getters in `sync` and read values from `@fields` directly by including `Sync::SkipGetter`.

```ruby
class AlbumTwin < Disposable::Twin
  feature Sync
  feature Sync::SkipGetter
```

## Manual Coercion

You can override setters for manual coercion.

```ruby
class AlbumTwin < Disposable::Twin
    property :title

    def title=(v)
      super(v.trim)
    end
  end
```

Be careful, though. The setter normally is also called in `setup` when copying properties from the models to the twin.

Analogue to `SkipGetter`, include `Setup::SkipSetter` to write values directly to `@fields`.

```ruby
class AlbumTwin < Disposable::Twin
  feature Setup::SkipSetter
```

## Change Tracking

The `Changed` module will allow tracking of state changes in all properties, even nested structures.


	class AlbumTwin < Disposable::Twin
	  feature Changed


Now, consider the following operations.


	twin.name = "Skamobile"
	twin.songs << Song.new("Skate", 2) # this adds second song.


This results in the following tracking results.


	twin.changed?             #=> true
	twin.changed?(:name)      #=> true
	twin.changed?(:playable?) #=> false
	twin.songs.changed?       #=> true
	twin.songs[0].changed?    #=> false
	twin.songs[1].changed?    #=> true


Assignments from the constructor are _not_ tracked as changes.


twin = AlbumTwin.new(album)
twin.changed? #=> false


When used with `Coercion`, note that first coercion happens, then the assignment, then the tracking logic.

That will lead to the following assignment _not_ being marked as change.


	twin.released #=> true
	twin.released = 1
	twin.released #=> true
	twin.changed?(:released) #=> false
