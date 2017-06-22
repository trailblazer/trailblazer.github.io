---
layout: reform
title: "Validation"
gems:
  - ["reform", "trailblazer/reform", "2.2"]
---

Validation in Reform happens in the `validate` method, and only there.

Reform will deserialize the fragments and their values to the form and its nested subforms, and once this is done, run validations.

It returns the result boolean, and provide potential errors via `errors`.

## Validation Engine

Since Reform 2.0, you can pick your validation engine. This can either be `ActiveModel::Validations` or `dry-validation`. The validation examples included on this page are using `dry-validation`.

<div class="callout secondary">
  <p>
    Reform 2.2 drops <code>ActiveModel</code>-support. You can still use it (and it will work!), but we won't maintain it actively, anymore. In other words, <code>ActiveModel::Validations</code> and Reform should be working until at least Reform 4.0.
  </p>
</div>

Note that you are not limited to one validation engine. When switching from `ActiveModel::Validation` to `dry-validation`, you should set the first as the default validation engine.

{% tabs %}
~~Rails
The configuration assumes you have `reform-rails` installed.

    config.reform.validations = :active_model

~~Ruby
In a Ruby environment, you'd usually monkey-patch the `Form` class.

    Reform::Form.send(:include, Reform::Form::ActiveModel::Validations)
{% endtabs %}

In forms you're upgrading to dry-validation, you can include the validation module explicitly.

    require 'reform/form/dry'

    module Album::Contract
      class Create < Reform::Form
        feature Reform::Form::Dry # override the default.

        validation do
          required(:title).filled
        end
      end
    end

This replaces the ActiveModel backend with dry for this specific form class, only.


## Validation Groups

Grouping validations enables you to run them conditionally, or in a specific order. You can use `:if` to specify what group had to be successful for it to be validated.

    validation :default do
      required(:title).filled
    end

    validation :unique, if: :default do
      configure do
        def unique?(value)
          # ..
        end
      end

      required(:title, &:unique?)
    end

This will only run the database-consuming `:unique` validation group if the `:default` group was valid.

Chaining groups works via the `:after` option. This will run the group regardless of the former result. Note that it still can be combined with `:if`.

    validation :email, after: :default do
      configure do
        def email?(value)
          # ..
        end
      end
      required(:email, &:email?)
    end

At any time you can extend an existing group using `:inherit`.

    validation :email, inherit: true do
      required(:email).filled
    end

This appends validations to the existing `:email` group.

## Dry-validation

Dry-validation is the preferred backend for defining and executing validations.

The purest form of defining validations with this backend is by using a [validation group](#validation-group). A group provides the exact same API as a `Dry::Validation::Schema`. You can learn all the details on the [gem's website](https://github.com/dryrb/dry-validation).

    require "reform/form/dry"

    class AlbumForm < Reform::Form
      feature Reform::Form::Dry

      property :title

      validation :default do
        required(:title).filled
      end
    end

Custom predicates have to be defined in the validation group. If you need access to your form you must pass `with: {form: true}` to your validation block.

    validation :default, with: {form: true} do
      configure do
        def unique?(value)
          Album.where.not(id: form.model.id).find_by(title: value).nil?
        end
      end

      required(:title).filled(:unique?)
    end

In addition to dry-validation's API, you have access to the form that contains the group via `form`.

    validation :default, with: {form: true} do
      configure do
        def same_password?(value)
          value == form.password
        end
      end

      required(:confirm_password).filled(:same_password?)
    end

Make sure to read the [documentation](http://dry-rb.org/gems/dry-validation) for dry-validation, as it contains some very powerful concepts like high-level rules that give you much richer validation semantics as compared to AM:V.

### Dry: Error Messages

You need to provide custom error messages via dry-validation mechanics.

    validation :default do
      configure do
        config.messages_file = 'config/error_messages.yml'
      end
      # ..
    end

This is automatically configured to use the I18n gem if it's available, which is true in a Rails environment.

A simple error messages file might look as follows.

    en:
      errors:
        same_password?: "passwords not equal"

## ActiveModel

In Rails environments, the AM support will be automatically loaded.

In other frameworks, you need to include `Reform::Form::ActiveModel::Validations` either into a particular form class, or simply into `Reform::Form` and make it available for all subclasses.


    require "reform/form/active_model/validations"

    Reform::Form.class_eval do
      feature Reform::Form::ActiveModel::Validations
    end


### Uniqueness Validation

Both ActiveRecord and Mongoid modules will support "native" uniqueness support where the validation is basically delegated to the "real" model class. This happens when you use `validates_uniqueness_of` and will respect options like `:scope`, etc.


    class SongForm < Reform::Form
      include Reform::Form::ActiveRecord
      model :song

      property :title
      validates_uniqueness_of :title, scope: [:album_id, :artist_id]
    end

Be warned, though, that those validators write to the model instance. Even though this _usually_ is not persisted, this will mess up your application state, as in case of an invalid validation your model will have unexpected values.

This is not Reform's fault but a design flaw in ActiveRecord's validators.

### Unique Validation

You're encouraged to use Reform's non-writing `unique: true` validation, though.


    require "reform/form/validation/unique_validator"

    class SongForm < Reform::Form
      property :title
      validates :title, unique: true
    end


This will only validate the uniqueness of `title`.

For uniqueness validation of multiple fields, use the `:scope` option.

```ruby
validates :user_id, unique: { scope: [:user_id, :song_id] }
```

Feel free to [help us here](https://github.com/trailblazer/reform-rails/blob/master/lib/reform/form/validation/unique_validator.rb)!

### Confirm Validation

Likewise, the `confirm: true` validation from ActiveResource is considered dangerous and should not be used. It also writes to the model and probably changes application state.

Instead, use your own virtual fields.


    class SignInForm < Reform::Form
      property :password, virtual: true
      property :password_confirmation, virtual: true

      validate :password_ok? do
        errors.add(:password, "Password mismatch") if password != password_confirmation
      end
    end


This is discussed in the _Authentication_ chapter of the [Trailblazer book](https://leanpub.com/trailblazer).

## Validations For File Uploads

In case you're processing uploaded files with your form using CarrierWave, Paperclip, Dragonfly or Paperdragon we recommend using the awesome [file_validators](https://github.com/musaffa/file_validators) gem for file type and size validations.

    class SongForm < Reform::Form
      property :image

      validates :image, file_size: {less_than: 2.megabytes},
        file_content_type: {allow: ['image/jpeg', 'image/png', 'image/gif']}
