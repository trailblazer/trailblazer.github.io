# Operation Architecture

## Too Much DSL!

basically, every "DSL" block in Operation will just "delegate" the block to a separate class from a separate gem

## Too Many Objects!

GC? Every fucking string is an object. these are a few mid-size business objects.

## Too Many Layers

In Rails, you're happy with "MVC". In JS, we had the same with jQuery, but now you accept a full-blown React component system.