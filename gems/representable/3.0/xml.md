---
layout: representable
title: "Representable: XML"
gems:
  - ["representable", "trailblazer/representable"]
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

Namespaces in XML allow the use of different vocabularies, or set of names, in one document. [Read this great article](http://books.xmlschemata.org/relaxng/relax-CHP-11-SECT-1.html) to share our fascination about them.

<i class="fa fa-download" aria-hidden="true"></i> Where's the [**EXAMPLE CODE?**](https://github.com/trailblazer/representable/blob/master/test/xml_namespace_test.rb)

{% callout %}
  The `Namespace` module is available in Representable >= 3.0.4. It doesn't work with JRuby due to Nokogiri's extremely complex implementation. Please wait for Representable 4.0 where we replace Nokogiri.

  For future-compat: `Namespace` only works in decorator classes, not modules.
{% endcallout %}


### Namespace: Default

You can define *one* namespace per representer using `::namespace` to set the section's default namespace.

{{ "test/xml_namespace_test.rb:simple-class:../representable" | tsnippet }}

Nested representers can be inline or classes (referenced via `:decorator`). Each class can maintain its own namespace.

Without any mappings, the namespace will be used as the default one.

{{ "test/xml_namespace_test.rb:simple-xml:../representable" | tsnippet }}

### Namespace: Prefix

After defining the namespace URIs in the representers, you can map them to a document-wide *prefix* in the top representer via `::namespace_def`.

{{ "test/xml_namespace_test.rb:map-class:../representable" | tsnippet }}

Note how you can also use `:namespace` to reference a certain differing prefix per property.

When rendering or parsing, the local property will be extended, e.g. `/library/book/isbn` will become `/lib:library/lib:book/lib:isbn`.

{{ "test/xml_namespace_test.rb:map-xml:../representable" | tsnippet }}

The top representer will include all namespace definitions as `xmlns` attributes.

### Namespace: Parse

Namespaces also apply when parsing an XML document to an object structure. When defined, only the known, prefixed tags will be considered.

{{ "test/xml_namespace_test.rb:parse-call:../representable" | tsnippet }}

In this example, only the `/lib:library/lib:book/lib:character/hr:name` was parsed.

{{ "test/xml_namespace_test.rb:parse-res:../representable" | tsnippet }}

If your incoming document has namespaces, please do use and specify them properly.

### Namespace: Remove

If an incoming document contains namespaces, but you don't want to define them in your representers, you can automatically remove them.

    class AlbumRepresenter < Representable::Decorator
      include Representable::XML

      remove_namespaces!

This will ditch the namespace prefix and parse all properties as if they never had any prefix in the document, e.g. `lib:author` becomes `author`.

{% callout %}
  Removing namespaces is a Nokogiri hack. It's absolutely not recommended as it defeats the purpose of XML namespaces and might result in wrong values being parsed and interpreted.
{% endcallout %}

