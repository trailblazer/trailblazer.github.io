---
layout: representable
title: "Representable: YAML"
---

# Representable YAML

Representable also comes with a YAML representer. Like [XML](xml.html), the declarative API is almost identical.

## Flow Style Lists

A nice feature is that `#collection` also accepts a `:style` option which helps having nicely formatted inline (or "flow") arrays in your YAML - if you want that!

    class SongRepresenter < Representable::Decorator
      include Representable::YAML

      property :title
      property :id
      collection :composers, style: :flow
    end


### Public API

To render and parse, you invoke `to_yaml` and `from_yaml`.

```ruby
Song = Struct.new(:title, :id, :composers)
song = Song.new("Fallout", 1, ["Stewart Copeland", "Sting"])
SongRepresenter.new(song).to_yaml
```

```yaml
---
title: Fallout
id: 1
composers: [Stewart Copeland, Sting]
```
