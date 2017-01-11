---
layout: roar
title: "JSON API"
---

# JSON API

Roar JSON API supports rendering and parsing documents using the [JSON API 1.0](http://jsonapi.org/format/) specification.

{% callout %}
N.B. Roar's JSON API support is now provided [as a separate gem](https://github.com/trailblazer/roar-jsonapi).
{% endcallout %}

## Overview

Here's a basic example of a JSON API representer.

```ruby
class ArticleDecorator < Roar::Decorator
  include Roar::JSON::JSONAPI.resource :articles

  # top-level link.
  link :self, toplevel: true do
    "//articles"
  end

  attributes do
    property :title
  end

  # resource object links
  link(:self) { "http://#{represented.class}/#{represented.id}" }

  # relationships
  has_one :author, class: Author, populator: ::Representable::FindOrInstantiate do # populator is for parsing, only.
    type :authors

    attributes do
      property :email
    end

    link(:self) { "http://authors/#{represented.id}" }
  end

  has_many :comments, class: Comment, decorator: CommentDecorator
end
```

## Basic Usage

By including `Roar::JSON::JSONAPI.resource` into your representer a handful of additional DSL methods get imported.

As JSON API per definition can represent singular models and collections you have two entry points.

```ruby
SongsRepresenter.new(Song.find(1)).to_json
SongsRepresenter.new(Song.new).from_json("..")
```

```ruby
SongsRepresenter.for_collection.new([Song.find(1), Song.find(2)]).to_json
SongsRepresenter.for_collection.new([Song.new, Song.new]).from_json("..")
```

## Resource Objects

http://jsonapi.org/format/#document-resource-objects

JSON API Resource Objects must contain an `id` and `type` member. You specify
the `type` when you include `Roar::JSON::JSONAPI.resource(type)`:

```ruby
class SongsRepresenter < Roar::Decorator
  include Roar::JSON::JSONAPI.resource :songs

  # ...
end
```

You do not need to specify an `id`. An `id` property will be created for you
automatically. However, if your represented object uses a method other than `id`
to represent its `id`, you must specify this with the `id_key:` option on
inclusion:

```ruby
class Song
  attr_accessor :song_id
end

class SongsRepresenter < Roar::Decorator
  include Roar::JSON::JSONAPI.resource :songs, id_key: :song_id

  # ...
end
```

## Attributes

http://jsonapi.org/format/#document-resource-object-attributes

Attributes should be defined with `::property` in an `::attributes` block.

```ruby
class SongsRepresenter < Roar::Decorator
  include Roar::JSON::JSONAPI.resource :songs

  attributes do
    property :title
  end
end
```

## Relationships

http://jsonapi.org/format/#document-resource-object-relationships

To define relationships, use `::has_one` or `::has_many` with either an [inline representer](http://trailblazer.to/gems/representable/3.0/api.html#inline-representer) or an [explicit, standalone representer](http://trailblazer.to/gems/representable/3.0/api.html#explicit-representer) (specified with the `decorates:` or `extend:` option).

```ruby
class SongsRepresenter < Roar::Decorator
  include Roar::JSON::JSONAPI.resource :songs

  has_one :album, class: Album do
    property :title
  end

  has_many :musicians, class: Musician, decorator: MusiciansRepresenter
end
```

You are able to define links and meta information for a given relationship in a
`::relationship` block:

```ruby
class SongsRepresenter < Roar::Decorator
  include Roar::JSON::JSONAPI.resource :songs

  has_many :musicians, class: Musician, decorator: MusiciansRepresenter do
    relationship do
      link(:self)     { "/songs/#{represented.id}/relationships/musicians" }
      link(:related)  { "/songs/#{represented.id}/musicians" }
    end
  end
end
```

## Member Names

http://jsonapi.org/format/#document-member-names

By default, member names will be rendered according to JSON API **recommendations**:
only non-reserved, URL safe characters specified in RFC 3986 will be used.
Following JSON API conventions, underscores will also be replaced by hyphens.

```ruby
class SongsRepresenter < Roar::Decorator
  include Roar::JSON::JSONAPI.resource :songs

  attributes do
    property :song_title        # rendered as song-title
    property :lyric_writer, as: :lyricist
  end

  has_one :album, class: Album do
    property :release_date    # rendered as release-date
  end
end
```

If you want less-strict behaviour (such as allowing non-ASCII Unicode
characters), you can override this default:

```ruby
class SongsRepresenter < Roar::Decorator
  include Roar::JSON::JSONAPI.resource :songs

  defaults do |name, _|
    { as: JSONAPI::MemberName.(name, strict: false) }
  end

  attributes do
    property :titel_des_Liedes    # rendered as titel_des_Liedes
    property :Klavierstück        # rendered as Klavierstück
  end
end
```

## Meta information

http://jsonapi.org/format/#document-meta

Meta information can be included into rendered singular and collection documents in two ways.

You can define meta information on your collection object and then let Roar compile it.

```ruby
class SongsRepresenter < Roar::Decorator
  include Roar::JSON::JSONAPI.resource :songs

  meta toplevel: true do
    property :page
    property :total
  end
end
```

Your collection object must expose the respective methods.

```ruby
collection.page  #=> 1
collection.total #=> 12
```

This will render the `{"meta": {"page": 1, "total": 12}}` hash into the JSON API document.

Alternatively, you can provide meta information as a hash when rendering.  Any values also defined on your object will be overriden.

```ruby
collection.to_json(meta: {page: params["page"], total: collection.size})
```

Both methods work for singular documents too.

```ruby
class SongsRepresenter < Roar::Decorator
  include Roar::JSON::JSONAPI.resource :songs

  meta do
    property :label
    property :format
  end
end
```

```ruby
song.to_json(meta: { label: 'EMI' })
```

## Compound Document

You can suppress rendering of the compound document using the `:included` option.

    decorator.to_json(included: false)

## Sparse Fieldsets

As per specification, JSON API allows the rendering of arbitrary fields to be suppressed. This feature is called [sparse fieldsets](http://jsonapi.org/format/#fetching-sparse-fieldsets).

With Roar, you can do that with all kinds of resource objects: Filtering attributes works for the top "primary data" and for the compound object.

For the primary data, you simply provide what to include via the `:fields` option.

    decorator.to_hash(
      fields: { articles: [:title] }
    )

This will only render the two mandatory `:id`, `:type` members and the  `:title` attribute.

    "data": {
      "type": "articles",
      "id": "1",
      "attributes": {"title": "My Article"}
    }

To include particular fields, only, in the compound document, use `:fields`.

    decorator.to_hash(
      include: [:author],
      fields: { articles: [:title], author: [:email] }
    )

You can control what types should be included in the compound document by adding them to `:include`.

The `:fields` option allows to specify what attributes for what type to include.

    "data": {
      "type": "articles",
      "id": "1",
      "attributes": {"title": "My Article"}
    },
    "included": [
      {
        "type": "author",
        "id":   "a:1",
        "attributes": {
          "email": "celsito@trb.to"
        }
      }
    ]

Note that the `author` fragment only contains the `email` in its attributes.

The `to_json` API is designed to be able to process `params` directly, where JSON API parameters like `fields` from the request URL are parsed into hashes and arrays.

    uri = Addressable::URI.parse('/articles?include=author&fields%5Barticles%5D=title,body&fields%5Bpeople%5D=name')
    => {"include"=>"author", "fields[articles]"=>"title,body", "fields[people]"=>"name"}

    query = Rack::Utils.parse_nested_query(uri.query)
    => {"include"=>"author", "fields"=>{"articles"=>"title,body", "people"=>"name"}}

    representer.to_json(include: query['include], fields: query['fields'])
