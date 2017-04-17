---
layout: representable
title: "Representable: XML"
---

# Representable XML

If you're enjoying the pleasure of working with XML, Representable can help you. It does render and parse XML, too, with an almost identical declarative API.

    require "representable/xml"

    class SongRepresenter < Representable::Decorator
      include Representable::XML

      property :title
      collection :composers
    end

Note that you have to include the `Representable::XML` module.

The public API then gives you `to_xml` and `from_xml`.

```ruby
Song = Struct.new(:title, :composers)
song = Song.new("Fallout", ["Stewart Copeland", "Sting"])
SongRepresenter.new(song).to_xml
```

```xml
<song>
  <title>Fallout</title>
  <composers>Stewart Copeland</composers>
  <composers>Sting</composers>
</song>
```

## Tag Attributes

You can also map properties to tag attributes in Representable. This works only for the top-level node, though (seen from the representer's perspective).

```ruby
class SongRepresenter < Representable::Decorator
  include Representable::XML

  property :title, attribute: true
  collection :composers
end

SongRepresenter.new(song).to_xml
```

```xml
<song title="Fallout">
  <composers>Stewart Copeland</composers>
  <composers>Sting</composers>
</song>
```

Naturally, this works both ways.

## Mapping Content

The same concept can also be applied to content. If you need to map a property to the top-level node's content, use the `:content` option. Again, _top-level_ refers to the document fragment that maps to the representer.

```ruby
class SongRepresenter < Representable::Decorator
  include Representable::XML

  property :title, content: true
end

SongRepresenter.new(song).to_xml
```

```xml
<song>Fallout</song>
```

## Wrapping Collections

It is sometimes unavoidable to wrap tag lists in a container tag.

    class AlbumRepresenter < Representable::Decorator
      include Representable::XML

      collection :songs, as: :song, wrap: :songs
    end

Album = Struct.new(:songs)
album = Album.new(["Laundry Basket", "Two Kevins", "Wright and Rong"])

album_representer = AlbumRepresenter.new(album)
album_representer.to_xml

Note that `:wrap` defines the container tag name.

```xml
<album>
  <songs>
    <song>Laundry Basket</song>
    <song>Two Kevins</song>
    <song>Wright and Rong</song>
  </songs>
</album>
```

## Namespace

### Namespace: Remove

If an incoming document contains namespaces, but you don't want to define them in your representers, you can automatically remove them.

    class AlbumRepresenter < Representable::Decorator
      include Representable::XML

      remove_namespaces!

This will ditch the namespace prefix and parse all properties as if they never had any prefix in the document, e.g. `lib:author` becomes `author`.

{% callout %}
  Removing namespaces is a Nokogiri hack. It's absolutely not recommended as it defeats the purpose of XML namespaces and might result in wrong values being parsed and interpreted.
{% endcallout %}

