---
layout: reform
permalink: /gems/reform/
title: "Reform"
---

# Overview

Reform provides form objects that maintain validations for one or multiple models, where a _model_ can be any kind of Ruby object. It is completely framework-agnostic and doesn't care about your database.

A *form* doesn't have to be a UI component, necessarily! It can be an intermediate validation before writing data to the persistence layer. While form objects may be used to render graphical web forms, Reform is used in many pure-API applications for deserialization and validation.

Note that validations no longer go into the model.


## API

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

Form fields are specified using `property` and `collection`, validations for the fields using the respective validation engine's API.

Forms can also be nested and map to more complex object graphs.

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
         required(:title).filled
        end
      end
    end

~~ActiveModel
    class AlbumForm < Reform::Form
      property :title

      validates :title, presence: true

      property :artist do
        property :name

        validation do
         required(:name).filled
        end
      end
    end
{% endtabs %}

While Reform is perfectly suited to map nested models with associations, it also allows mapping via composition, to hash fields, and more. Check out the [supported data types](data-types.html).

## Setup

In your controller or operation you create a form instance and pass in the models you want to work on.


    class AlbumsController
      def new
        @form = AlbumForm.new(Album.new)
      end


This will also work as an editing form with an existing album.

    def edit
      @form = AlbumForm.new(Album.find(1))
    end


Reform will read property values from the model in setup. In our example, the `AlbumForm` will call `album.title` to populate the `title` field.

## Rendering

Your `@form` is now ready to be rendered, either do it yourself or use something like Rails' `#form_for`, `simple_form` or `formtastic`.

    = form_for @form do |f|
      = f.input :title

Nested forms and collections can be easily rendered with `fields_for`, etc. Note that you no longer pass the model to the form builder, but the Reform instance.

Optionally, you might want to use the `#prepopulate!` method to pre-populate fields and prepare the form for rendering.

## Validation


## Persisting

The easiest way to persist validated data is to call `#save` on the form.

    if form.validate(params[:song])
      form.save
    end

This will write the data to the model(s) using [`sync`](api.html#sync) and then call `album.save`.

You may save data manually using [`save` with a block](api.html#save).

    form.save do |nested_hash|
      Album.create(title: nested_hash["title"])
    end

Or you can let Reform write the validated data to the model(s) without saving anything.

    form.sync # the album is unsaved!

This will updated the model's attributes using its setter methods, but not `save` anything.

## Installation: Dry-Validation

Add this your Gemfile.

    gem "reform"

Please use [dry-validation](http://dry-rb.org/gems/dry-validation), which is our recommended validation engine. Put the following snippet into an initializer.

    require "reform/form/dry"

    Reform::Form.class_eval do
      include Reform::Form::Dry
    end

## Installation: ActiveModel

Add this to your Gemfile.

    gem "reform"
    gem "reform-rails"

To use `ActiveModel` (not recommended as it is way behind).

    require "reform/form/active_model/validations"

    Reform::Form.class_eval do
      include Reform::Form::ActiveModel::Validations
    end

Things you should know when using ActiveModel with Reform.

* `ActiveModel` support is provided by the `reform-rails` gem. You have to add it to your `Gemfile`.
* The above last step of including `ActiveModel::Validations` is done automatically in a Rails environment.
* Reform works fine with Rails 3.1-4.2. However, inheritance of validations with `ActiveModel::Validations` is broken in Rails 3.2 and 4.0.





## Agnosticism: Mapping Data

Reform doesn't really know whether it's working with a PORO, an `ActiveRecord` instance or a `Sequel` row.

When rendering the form, reform calls readers on the decorated model to retrieve the field data (`Song#title`, `Song#length`).

When syncing a submitted form, the same happens using writers. Reform simply calls `Song#title=(value)`. No knowledge is required about the underlying database layer.

The same applies to saving: Reform will call `#save` on the main model and nested models.

Nesting forms only requires readers for the nested properties as `Album#songs`.


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


## Security

By explicitely defining the form layout using `::property` there is no more need for protecting from unwanted input. `strong_parameter` or `attr_accessible` become obsolete. Reform will simply ignore undefined incoming parameters.



