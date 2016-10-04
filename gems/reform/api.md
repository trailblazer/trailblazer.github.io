---
layout: reform
title: "Reform: API"
---

This document discusses Reform's declarative API to define form classes and the instance API that is used at run-time on the form object, e.g. to validate an incoming hash.

More specific documentation about options to be passed to the `property` and `collection` method are to be found in the [options documentation](options.html).

## Overview

Forms have a ridiculously simple API with only a handful of public methods.

1. `#initialize` always requires a model that the form represents.
2. `#validate(params)` updates the form's fields with the input data (only the form, _not_ the model) and then runs all validations. The return value is the boolean result of the validations.
3. `#errors` returns validation messages in a classic ActiveModel style.
4. `#sync` writes form data back to the model. This will only use setter methods on the model(s).
5. `#save` (optional) will call `#save` on the model and nested models. Note that this implies a `#sync` call.
6. `#prepopulate!` (optional) will run pre-population hooks to "fill out" your form before rendering.

In addition to the main API, forms expose accessors to the defined properties. This is used for rendering or manual operations.

### Disposable API

Every Reform form object inherits from `Disposable::Twin`, making every form a twin and giving each form the entire twin API such as.

* Defaults using `:default`.
* Coercion using `:type` and `:nilify`.
* Nesting
* Composition
* Hash fields

If you're looking for a specific feature, make sure to check the [Disposable documentation](/gems/disposable/api.html)

## Form Class

Forms are defined in classes. Often, these classes partially map to one or many model(s).

{% tabs %}
~~dry-validation
    class AlbumForm < Reform::Form
      property :title

      validation do
       required(:title).filled
      end
    end

~~ActiveModel
    class AlbumForm < Reform::Form
      property :title

      validates :title, presence: true
    end
{% endtabs %}

Form fields are declared using `::property`.

Validations leverage the respective validation engine's API, which be either `ActiveModel` or dry-validations.

## Property

Use `property` to map scalar fields of your model to the form.

    class AlbumForm < Reform::Form
      property :title
    end

This will create accessors on the form and read the initial value from the model in [setup](#setup).

    model = Album.new(title: "Greatest Hits")
    form  = AlbumForm.new(model)

    form.title #=> "Greatest Hits"

### Overriding Accessors

You're free to override the form's accessors for presentation or coercion.

    class AlbumForm < Reform::Form
      property :title

      def title
        super.capitalize
      end
    end

As always, use `super` for the original method.

This can also be used to provide a default value.

    def title
      super || "not available"
    end

## Collection

When mapping an array field of the model, use `collection`.

    class AlbumForm < Reform::Form
      collection :song_titles
    end

This will create accessors on the form and read the initial

    model = Album.new(song_titles: ["The Reflex", "Wild Boys"])

    form = AlbumForm.new(model)
    form.song_titles[0] #=> "The Reflex"

## Nesting

To create forms for nested objects, both `property` and `collection` accept a block for the nested form definition.

    class AlbumForm < Reform::Form
      property :artist do
        property :name
      end

      collection :songs do
        property :title
      end
    end

Nesting will simply create an anonymous, nested `Reform::Form` class for the nested property.

It's often helpful with `has_many` or `belongs_to` associations.

    artist = Artist.new(name: "Duran Duran")
    songs  = [Song.new(title: "The Reflex"), Song.new(title: "Wild Boys")]
    model  = Album.new(artist: artist, songs: songs)

The accessors will now be nested.

    form   = AlbumForm.new(model)
    form.artist.name #=> "Duran Duran"
    form.songs[0].title #=> "The Reflex"

All API semantics explained here may be applied to both the top form and nested forms.


### Nesting: Explicit Form

Sometimes you want to specify an explicit form constant rather than an inline form. Use the `form:` option here.

    property :song, form: SongForm

The nested `SongForm` refers to a stand-alone form class you have to provide.

## Setup

Injecting Objects: safe args can be passed in constructor

## Validate

You can define validation for every form property and for nested forms.

{% tabs %}
~~dry-validation
    class AlbumForm < Reform::Form
      property :title

      validation do
       required(:title).filled
      end

      property :artist do
        property :name

        validation do
         required(:name).filled
        end
      end
    end

~~ActiveModel
    class AlbumForm < Reform::Form
      property :title

      validates :title, presence: true

      property :artist do
        property :name

        validates :name, presence: true
      end
    end
{% endtabs %}

Validations will be run in `validate`.

    form.validate(
      {
        title: "Best Of",
        artist: {
          name: "Billy Joel"
        }
      }
    ) #=> true

The returned value is the boolean result of the validations.

Reform will read all values it knows from the incoming hash, and it **will ignore any unknown key/value pairs**. This makes `strong_parameters` redundant. Accepted values will be written to the form using the public setter, e.g. `form.title = "Best Of"`.

After `validate`, the form's values will be overwritten.

    form.artist.name #=> "Billy Joel"

The model won't be touched, its values are still the original ones.

    model.artist.name #=> "Duran Duran"

### Deserialization and Populator

Very often, you need to give Reform some information how to create or find nested objects when `validate`ing. This directive is called _populator_ and [documented here](http://trailblazer.to/gems/reform/populator.html).

## Errors

After `validate`, you can access validation errors via `errors`.

    form.errors #=> {title: ["must be filled"]}

The returned `Errors` object exposes the following methods.

{% tabs %}
~~dry-validation
{% endtabs %}

## Sync

## Save

### Saving Forms Manually

Calling `#save` with a block will provide a nested hash of the form's properties and values. This does **not call `#save` on the models** and allows you to implement the saving yourself.

The block parameter is a nested hash of the form input.

    @form.save do |hash|
      hash      #=> {title: "Greatest Hits"}
      Album.create(hash)
    end

You can always access the form's model. This is helpful when you were using populators to set up objects when validating.

    @form.save do |hash|
      album = @form.model

      album.update_attributes(hash[:album])
    end


Reform will wrap defined nested objects in their own forms. This happens automatically when instantiating the form.

    album.songs #=> [<Song name:"Run To The Hills">]

    form = AlbumForm.new(album)
    form.songs[0] #=> <SongForm model: <Song name:"Run To The Hills">>
    form.songs[0].name #=> "Run To The Hills"

### Nested Saving

`validate` will assign values to the nested forms. `sync` and `save` work analogue to the non-nested form, just in a recursive way.

The block form of `#save` would give you the following data.

    @form.save do |nested|
      nested #=> {title:  "Greatest Hits",
             #    artist: {name: "Duran Duran"},
             #    songs: [{title: "Hungry Like The Wolf"},
             #            {title: "Last Chance On The Stairways"}]
             #   }
      end

The manual saving with block is not encouraged. You should rather check the Disposable docs to find out how to implement your manual tweak with the official API.

### Turning Off Autosave

You can assign Reform to _not_ call `save` on a particular nested model (per default, it is called automatically on all nested models).

    class AlbumForm < Reform::Form
      # ...

      collection :songs, save: false do
        # ..
      end

The `:save` options set to false won't save models.

## Inheritance

Forms can be derived from other forms and will inherit all properties and validations.

    class AlbumForm < Reform::Form
      property :title

      collection :songs do
        property :title

        validates :title, presence: true
      end
    end

Now, a simple inheritance can add fields.

    class CompilationForm < AlbumForm
      property :composers do
        property :name
      end
    end

This will _add_ `composers` to the existing fields.

You can also partially override fields using `:inherit`.

    class CompilationForm < AlbumForm
      property :songs, inherit: true do
        property :band_id
        validates :band_id, presence: true
      end
    end

Using `inherit:` here will extend the existing `songs` form with the `band_id` field. Note that this simply uses [representable's inheritance mechanism](https://github.com/apotonick/representable/#partly-overriding-properties).

## Forms In Modules

To maximize reusability, you can also define forms in modules and include them in other modules or classes.

    module SongsForm
      include Reform::Form::Module

      collection :songs do
        property :title
        validates :title, presence: true
      end
    end

This can now be included into a real form.

    class AlbumForm < Reform::Form
      property :title

      include SongsForm
    end

Note that you can also override properties [using inheritance](#inheritance) in Reform.

When using coercion, make sure the including form already contains the `Coercion` module.

If you want to provide accessors in the module, you have to define them in the `InstanceMethods` module.

    module SongForm
      include Reform::Form::Module

      property :title

      module InstanceMethods
        def title=(v)
          super(v.trim)
        end
      end
    end

This is important so Reform can add your accessors after defining the default ones.

## Dirty Tracker

Every form tracks changes in `#validate` and allows to check if a particular property value has changed using `#changed?`.

    form.title => "Button Up"

    form.validate("title" => "Just Kiddin'")
    form.changed?(:title) #=> true

When including `Sync::SkipUnchanged`, the form won't assign unchanged values anymore in `#sync`.

## Deserialization

When invoking `validate`, Reform will parse the incoming hash and transform it into a graph of nested form objects that represent the input. This is called *deserialization*.

The deserialization is an important (and outstanding) feature of Reform and happens by using an internal *representer* that is automatically created for you. You can either configure that representer using the [`:deserializer` option](options.html#deserializer) or provide code for deserialization yourself, bypassing any representer logic.

The `deserialize!` method is called before the actual validation of the graph is run and can be used for deserialization logic.

      class AlbumForm < Reform::Form
        property :title

        def deserialize!(document)
          hash = YAML.parse(document)

          self.title  = hash[:title]
          self.artist = Artist.new if hash[:artist]
        end
      end

We encourage you to use Reform's deserialization using a representer, though. The representer is highly configurable and optimized for its job of parsing different data structures into Ruby objects.

## Population

To hook into the [deserialization](#deserialization) process, the easiest way is using [the `:populator` option](populator.html). It allows manually creating, changing or adding nested objects to the form to represent the input.

## Inflection

Properties can have arbitrary options that might become helpful, e.g. when rendering the form.

    property :title, type: String

Use `options_for` to access a property's configuration.

    form.options_for(:title) # => {:readable=>true, :coercion_type=>String}

Note that Reform renames some options (e.g. `:type` internally becomes `:coercion_type`). Those names are private API and might be changed without deprecation.
