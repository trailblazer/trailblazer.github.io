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

    class SongRepresenter < Representable::Decorator
      include Representable::XML

      property :id, attribute: true
      property :track, attribute: true
    end

    song.to_xml
    #=> <song title="American Idle" id="1" />

Naturally, this works both ways.

## Mapping Content

The same concept can also be applied to content. If you need to map a property to the top-level node's content, use the `:content` option. Again, _top-level_ refers to the document fragment that maps to the representer.

    class SongRepresenter < Representable::Decorator
      include Representable::XML

      property :title, content: true
    end

    song.to_xml
    #=> <song>American Idle</song>

## Wrapping Collections

It is sometimes unavoidable to wrap tag lists in a container tag.

    class AlbumRepresenter < Representable::Decorator
      include Representable::XML

      collection :songs, as: :song, wrap: :songs
    end

Note that `:wrap` defines the container tag name.

    song.to_xml #=>
    <album>
        <songs>
            <song>Laundry Basket</song>
            <song>Two Kevins</song>
            <song>Wright and Rong</song>
        </songs>
    </album>

## Namespaces

Support for namespaces are not yet implemented. However, if an incoming parsed document contains namespaces, you can automatically remove them.

    class AlbumRepresenter < Representable::Decorator
      include Representable::XML

      remove_namespaces!


## Development Status

The `Representable::XML` module is currently not being further developed. If you are interested in working on it, feel free to PR. In case you need a feature but want us to build it, consider [hiring us](/inc/oss.html) for an OSS feature project.