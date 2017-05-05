---
layout: representable
title: "Representable: Getting Started"
gems:
  - ["representable", "trailblazer/representable", "3.0"]
---

# Getting Started with Representable

## Debugging

Representable is a generic mapper using recursions, pipelines and things that might be hard to understand from the outside. That's why we got the `Debug` module which will give helpful output about what it's doing when parsing or rendering.

You can extend objects on the run to see what they're doing.

    SongRepresenter.new(song).extend(Representable::Debug).from_json("..")
    SongRepresenter.new(song).extend(Representable::Debug).to_json

It's probably a good idea not to do this in production.
