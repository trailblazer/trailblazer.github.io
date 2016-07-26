---
layout: reform
title: "Reform: Declarative API"
---

## Disposable API

Every Reform form object inherits from `Disposable::Twin`, making every form a twin and giving each form the entire twin API such as.

* Defaults using `:default`.
* Coercion using `:type` and `:nilify`.
* Nesting
* Composition
* Hash fields

If you're looking for a specific feature, make sure to check the [Disposable documentation](/gems/disposable/api.html)

## Form Class

Forms are defined in classes. Often, these classes partially map to a model.

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

This will create accessors on the form and read the initial value from the model.

    model = Album.new(title: "Greatest Hits")

    form = AlbumForm.new(model)
    form.title #=> "Greatest Hits"

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

        validates :title, presence: true
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

## Errors

After `validate`, you can access validation errors via `errors`.

    form.errors #=> {title: ["must be filled"]}

The returned `Errors` object exposes the following methods.

{% tabs %}
~~dry-validation
{% endtabs %}

## Sync

## Save


### Turning Off Autosave

You can assign Reform to _not_ call `save` on a particular nested model (per default, it is called automatically on all nested models).

    class AlbumForm < Reform::Form
      # ...

      collection :songs, save: false do
        # ..
      end

The `:save` options set to false won't save models.


## Populator

Very often, you need to give Reform some information how to create or find nested objects when `validate`ing. This directive is called _populator_ and [documented here](http://trailblazer.to/gems/reform/populator.html).


## Manual Coercion

To filter values manually, you can override the setter in the form.

    class SongForm < Reform::Form
      property :title

      def title=(value)
        super sanitize(value) # value is raw form input.
      end
    end

Again, setters are only called in `validate`, *not* during construction.

## Deserializer

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

## Overriding Accessors

You're free to override form accessors for presentation or coercion.

    class SongForm < Reform::Form
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

# Injecting Objects

safe args can be passed in constructor


## Inflection

Properties can have arbitrary options that might become helpful, e.g. when rendering the form.

    property :title, type: String

Use `options_for` to access a property's configuration.

    form.options_for(:title) # => {:readable=>true, :coercion_type=>String}

Note that Reform renames some options (e.g. `:type` internally becomes `:coercion_type`). Those names are private API and might be changed without deprecation.

## Dirty Tracker

Every form tracks changes in `#validate` and allows to check if a particular property value has changed using `#changed?`.

    form.title => "Button Up"

    form.validate("title" => "Just Kiddin'")
    form.changed?(:title) #=> true

When including `Sync::SkipUnchanged`, the form won't assign unchanged values anymore in `#sync`.


## Deserializing and Population

A form object is just a twin. In `validate`, a representer is used to deserialize the incoming hash and populate the form twin graph. This means, you can use any representer you like and process data like JSON or XML, too.

Representers can be inferred from the contract automatically using `Disposable::Schema`. You may then extend your representer with hypermedia, etc. in order to render documents. Check out the Trailblazer book (chapter Hypermedia APIs) for a full explanation.

You can even write your own deserializer code in case you dislike Representable.

    class AlbumForm < Reform::Form
      # ..

      def deserialize!(document)
        hash = YAML.parse(document)

        self.title  = hash[:title]
        self.artist = Artist.new if hash[:artist]
      end
    end

The decoupling of deserializer and form object is one of the main reasons I wrote Reform 2.

