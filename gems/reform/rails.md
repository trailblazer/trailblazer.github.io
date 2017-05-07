---
layout: reform
title: "Reform with Rails"
gems:
  - ["reform-rails", "trailblazer/reform-rails", "0.0"]
---

Reform works with any framework, but comes with additional Rails glue code.

## Reform-Rails

The `reform` gem itself doesn't contain any Rails-specific code but will still work, e.g. for JSON APIs. For extensive Rails support, add the [`reform-rails` gem](https://github.com/trailblazer/reform-rails).

```ruby
gem "reform", ">= 2.2.0"
gem "reform-rails"
```

Per default, `reform-rails` will assume you want `ActiveModel::Validations` as the validation engine. This will include the following into `Reform::Form`.

* `Form::ActiveModel` for form builder compliance so your form works with `form_for` and friends.
* `Reform::Form::ActiveModel::FormBuilderMethods` to make Reform consume Rails form builder's weird parameters, e.g. `{song_attributes: { number: 1 }}`.
* Uniqueness validation for `ActiveRecord`.

However, you can also use the new, [recommended `dry-validation`](validation.html#dry-validation) backend, and you should check that out!

To do so, add the gem to your Gemfile.

```ruby
gem "reform", ">= 2.2.0"
gem "reform-rails"
gem "dry-validation"
```

And configure Reform in an initializer, e.g. `config/initializer/reform.rb` to load the new validation backend.

```ruby
 Rails.application.config.reform.validations = :dry
```

Make sure you use the API when writing dry validations.


## Uniqueness Validation

Both ActiveRecord and Mongoid modules will support "native" uniqueness support from the model class when you use `validates_uniqueness_of`. They will provide options like `:scope`, etc.

You're encouraged to use Reform's non-writing `unique: true` validation, though. [Learn more](http://trailblazer.to/gems/reform/validation.html)

## ActiveModel Compliance

Forms in Reform can easily be made ActiveModel-compliant.

Note that this step is _not_ necessary in a Rails environment.

    class SongForm < Reform::Form
      include Reform::Form::ActiveModel
    end

If you're not happy with the `model_name` result, configure it manually via `::model`.

    class CoverSongForm < Reform::Form
      include Reform::Form::ActiveModel

      model :song
    end

`::model` will configure ActiveModel's naming logic. With `Composition`, this configures the main model of the form and should be called once.

This is especially helpful when your framework tries to render `cover_song_path` although you want to go with `song_path`.


## FormBuilder Support

To make your forms work with all the form gems like `simple_form` or Rails `form_for` you need to include another module.

Again, this step is implicit in Rails and you don't need to do it manually.
If you've configured dry-validation as your validation framework the inclusion will not happen.
You have to include at least the FormBuilderMethods module.
This is needed to translate Rails' suboptimal songs_attributes weirdness
back to normal `songs: ` naming in +#valiate+.
This can be controlled via `config.reform.enable_active_model_builder_methods = true`.

    class SongForm < Reform::Form
      include Reform::Form::ActiveModel
      include Reform::Form::ActiveModel::FormBuilderMethods
    end

### Simple Form

If you want full support for `simple_form` do as follows.

    class SongForm < Reform::Form
      include Reform::Form::ActiveModel::ModelReflections

Including this module will add `#column_for_attribute` and other methods need by form builders to automatically guess the type of a property.


## Validation Shortform

Luckily, this can be shortened as follows.

    class SongForm < Reform::Form
      property :title, validates: {presence: true}
      property :length, validates: {numericality: true}
    end

Use `properties` to bulk-specify fields.

    class SongForm < Reform::Form
      properties :title, :length, validates: {presence: true} # both required!
      validates :length, numericality: true
    end



## Validations From Models

Sometimes when you still keep validations in your models (which you shouldn't) copying them to a form might not feel right. In that case, you can let Reform automatically copy them.

    class SongForm < Reform::Form
      property :title

      extend ActiveModel::ModelValidations
      copy_validations_from Song
    end

Note how `copy_validations_from` copies over the validations allowing you to stay DRY.

This also works with Composition.

    class SongForm < Reform::Form
      include Composition
      # ...

      extend ActiveModel::ModelValidations
      copy_validations_from song: Song, band: Band
    end


## ActiveRecord Compatibility

Reform provides the following `ActiveRecord` specific features. They're mixed in automatically in a Rails/AR setup.

 * Uniqueness validations. Use `validates_uniqueness_of` in your form.

As mentioned in the [Rails Integration](https://github.com/apotonick/reform#rails-integration) section some Rails 4 setups do not properly load.

You may want to include the module manually then.

    class SongForm < Reform::Form
      include Reform::Form::ActiveRecord

## Mongoid Compatibility

Reform provides the following `Mongoid` specific features. They're mixed in automatically in a Rails/Mongoid setup.

 * Uniqueness validations. Use `validates_uniqueness_of` in your form.

You may want to include the module manually then.

    class SongForm < Reform::Form
      include Reform::Form::Mongoid



## Troubleshooting

1. In case you explicitly _don't_ want to have automatic support for `ActiveRecord` or `Mongoid` and form builder: `require reform/form`, only.
2. In some setups around Rails 4 the `Form::ActiveRecord` module is not loaded properly, usually triggering a `NoMethodError` saying `undefined method 'model'`. If that happened to you, `require 'reform/rails'` manually at the bottom of your `config/application.rb`.
3. Mongoid form gets loaded with the gem if `Mongoid` constant is defined.
