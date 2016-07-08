---
layout: reform
title: "Reform Validation"
---

# Validation

Validation in Reform happens in the `validate` method, and only there.

Since Reform 2.0, you can pick your validation backend. This can either be `ActiveModel::Validations` or `dry-validation`.

<div class="panel">
  <p>
    Reform 2.2 drops <code>ActiveModel</code>-support. You can still use it (and it will work!), but we won't maintain it actively, anymore. In other words, <code>ActiveModel::Validations</code> and Reform should be working until at least Reform 4.0.
  </p>
</div>

## Refactoring Legacy Forms

Note that you are not limited to one validation backend. When switching from ActiveModel::Validation to dry-validation, you should set the first as the default validation engine.

{% tabs %}
~~Rails
The configuration assumes you have `reform-rails` installed.

    config.reform.validations = :active_model

~~Ruby
In a Ruby environment, you'd usually monkey-patch the `Form` class.

    Reform::Form.send(:include, Reform::Form::ActiveModel::Validations)
{% endtabs %}

In forms you're upgrading to dry-validation, you can include the validation module explicitly.

    module Album::Contract
      class Create < Reform::Form
        feature Reform::Form::Dry # override the default.

        validation do
          required(:title).filled
        end
      end
    end

This replaces the ActiveModel backend with dry for this specific form class, only.

## Overview

Validation in Reform works by invoking `validate` and passing in a hash. This hash can be deeply nested, Reform will deserialize the fragments and their values to the form and its nested subforms, and once this is done, run validations.

`Form#validate` will return the result boolean, and provide potential errors via `Form#errors`.

## Dry-validation

Dry-validation is the preferred backend for defining and executing validations.

The purest form of defining validations with this backend is by using a [validation group](#validation-group). A group provides the exact same API as a `Dry::Validation::Schema`. You can learn all the details on the [gem's website](https://github.com/dryrb/dry-validation).

    require "reform/form/dry"

    class AlbumForm < Reform::Form
      feature Reform::Form::Dry

      property :title

      validation :default do
        key(:title, &:filled?)
      end
    end

Custom predicates have to be defined in the validation group.

    validation :default do
      key(:title) { |title| title.filled? & title.unique? }

      def unique?(value)
        Album.find_by(title: value).nil?
      end
    end

In addition to dry-validation's API, you have access to the form that contains the group via `form`.

    validation :default do
      key(:confirm_password, &:same_password?)

      def same_password?(value)
        value == form.password
      end
    end

Make sure to read the documentation for dry-validation, as it contains some very powerful concepts like high-level rules that give you much richer validation semantics as compared to AM:V.

### Dry: Error Messages

You need to provide custom error messages via dry-validation mechanics.

    validation :default do
      configure { |config|
        config.messages_file = 'config/error_messages.yml'
      }

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

## Validation Group

Grouping validataions allows running them conditionally. You can use `:if` to specify what group had to be successful validated.

    validation :default do
      key(:title, &:filled?)
    end

    validation :unique, if: :default do
      key(:title, &:unique?)

      def unique?(value)
      # ..
    end

This will only run the database-consuming `:unique` validation group if the `:default` group was valid.

Chaining groups works via the `:after` option. This will run the group regardless of the former result. Note that it still can be combined with `:if`.

    validation :email, after: :default do
      key(:email, &:email?)

      def email?(value)
      # ..
    end

At any time you can extend an existing group using `:inherit`.

    validation :email, inherit: true do
      key(:email, &:filled?)
    end

This appends validations to the existing `:email` group.

## Uniqueness Validation

Both ActiveRecord and Mongoid modules will support "native" uniqueness support where the validation is basically delegated to the "real" model class. This happens when you use `validates_uniqueness_of` and will respect options like `:scope`, etc.


    class SongForm < Reform::Form
      include Reform::Form::ActiveRecord
      model :song

      property :title
      validates_uniqueness_of :title, scope: [:album_id, :artist_id]


Be warned, though, that those validators write to the model instance. Even though this _usually_ is not persisted, this will mess up your application state, as in case of an invalid validation your model will have unexpected values.

This is not Reform's fault but a design flaw in ActiveRecord's validators.

# Unique Validation

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

Feel free to [help us here](https://github.com/apotonick/reform/blob/master/lib/reform/form/validation/unique_validator.rb)!

## Confirm Validation

Likewise, the `confirm: true` validation from ActiveResource is considered dangerous and should not be used. It also writes to the model and probably changes application state.

Instead, use your own virtual fields.


    class SignInForm < Reform::Form
      property :password, virtual: true
      property :password_confirmation, virtual: true

      validate :passwork_ok? do
        errors.add(:password, "Password mismatch") if password != password_confirmation
      end


This is discussed in the _Authentication_ chapter of the [Trailblazer book](https://leanpub.com/trailblazer).
