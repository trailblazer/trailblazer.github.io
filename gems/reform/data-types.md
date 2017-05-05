---
layout: reform
title: "Reform Data Types"
gems:
  - ["reform", "trailblazer/reform"]
---

## Composition

Reform allows to map multiple models to one form. The [complete documentation](https://github.com/apotonick/disposable#composition) is here, however, this is how it works.

    class AlbumForm < Reform::Form
      include Composition

      property :id,    on: :album
      property :title, on: :album
      property :songs, on: :cd
      property :cd_id, on: :cd, from: :id

      validates :title, presence: true
    end

Note that Reform now needs to know about the source of properties. You can configure that by using the `on:` option.

### Composition: Setup

When initializing a composition, you have to pass a hash that contains the composees.

    form = AlbumForm.new(album: album, cd: CD.find(1))

The form now hides the fact that it represents more than one model. Accessors for properties are defined directly on the form.

    form.title #=> "Greatest Hits"

### Composition: Save/Sync

On a composition form, `sync` will write data back to the composee models. `save` will additionally call `save` on all composee models.

When using `#save' with a block, here's what the block parameters look like.

    form.save do |nested|
      nested #=>
        {
          album:  {
            id:    9,
            title: "Rio"
          },
          cd:     {
            songs: [],
            id: 1
          }
        }
    end

The hash is now keyed by composee name with the private property names.


### Composition: ActiveModel

With ActiveModel, the form needs to have a main object configured. This is where ActiveModel-methods like `#persisted?` or '#id' are delegated to. Use `::model` to define the main object.

    class AlbumForm < Reform::Form
      include Composition

      property :id,    on: :album
      property :title, on: :album
      property :songs, on: :cd
      property :cd_id, on: :cd, from: :id

      model :album # only needed in ActiveModel context.

      validates :title, presence: true
    end

## Hash Fields

Reform can also handle deeply nested hash fields from serialized hash columns. This is [documented here](https://github.com/apotonick/disposable#struct).

## Nesting
