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

## Virtual Attributes

Virtual fields come in handy when there's no direct mapping to a model attribute or when you plan on displaying but not processing a value.


### Virtual

Often, fields like `password_confirmation` should neither be read from nor written back to the model. Reform comes with the `:virtual` option to handle that case.

    class PasswordForm < Reform::Form
      property :password
      property :password_confirmation, virtual: true

Here, the model won't be queried for a `password_confirmation` field when creating and rendering the form. When saving the form, the input value is not written to the decorated model. It is only readable in validations and when saving the form manually.

    form.validate("password" => "123", "password_confirmation" => "321")

    form.password_confirmation #=> "321"

The nested hash in the block-`#save` provides the same value.

    form.save do |nested|
      nested[:password_confirmation] #=> "321"

### Read-Only

Use `writeable: false` to display a value but skip processing it in `validate`.

    property :country, writeable: false

1. The form will invoke `model.country` to read the initial value.
2. It will invoke `form.country=` in `validate`.
3. The model's setter `model.country` **won't** be called in `sync`.

Non-writeable values are still readable in the nested hash and through the form itself.

    form.save do |nested|
      nested[:country] #=> "Australia"

### Write-Only

Use `readable: false` to hide a value but still write it to the model.

    property :credit_card_number, readable: false

1. The form **won't** invoke `model.credit_card_number` and will display an empty field.
2. In `validate`, the form calls `form.credit_card_number=`.
3. In `sync, the setter `model.credit_card_number=` is called and the value written to the database.

## Access Protection

Use `parse: false` to protect the form setters from being called in `validate`.

    property :uuid, parse: false

1. This will call `model.uuid` to display the field via the form.
2. In `validate`, the form's setter **won't** be called, leaving the value as it is.
3. In `sync`, the setter `model.uuid` is called and restored to the original value.

Note that the `:parse` option works by leveraging [:deserializer](#deserializer).

## Coercion

Incoming form data often needs conversion to a specific type, like timestamps. Reform uses [dry-types](http://dry-rb.org/gems/dry-types/) for coercion. The DSL is seamlessly integrated with the `:type` option.

Be sure to add `dry-types` to your `Gemfile` when requiring coercion.

    gem "dry-types"

To use coercion, you need to include the `Coercion` module into your form class.

    require "reform/form/coercion"

    class SongForm < Reform::Form
      feature Coercion

      property :written_at, type: Types::Form::DateTime
    end

    form.validate("written_at" => "26 September")

Coercion only happens in `#validate`, *not* during construction.

    form.written_at #=> <DateTime "2014 September 26 00:00">

Available coercion types are [documented here](http://dry-rb.org/gems/dry-types/built-in-types/).

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

You're free to override form accessors for presentation and coercion.

    class SongForm < Reform::Form
      property :title

      def title
        super.capitalize
      end
    end

As always, use `super` for the original method.

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

## Skip_if

Use `:skip_if` to ignore properties in `#validate`.

    property :hit, skip_if: lambda { |fragment, *| fragment["title"].blank? }

This works for both properties and entire nested forms. The property will simply be ignored when deserializing, as if it had never been in the incoming hash/document.

For nested properties you can use `:skip_if: :all_blank` as a macro to ignore a nested form if all values are blank.

Note that this still runs validations for the property.

## Inflection

Properties can have arbitrary options that might become helpful, e.g. when rendering the form.

    property :title, type: String

Use `options_for` to access a property's configuration.

    form.options_for(:title) # => {:readable=>true, :coercion_type=>String}

Note that Reform renames some options (e.g. `:type` internally becomes `:coercion_type`). Those names are private API and might be changed without deprecation.
