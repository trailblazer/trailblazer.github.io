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

Forms have a ridiculously simple API with only a handful of public methods.

1. `#initialize` always requires a model that the form represents.
2. `#validate(params)` updates the form's fields with the input data (only the form, _not_ the model) and then runs all validations. The return value is the boolean result of the validations.
3. `#errors` returns validation messages in a classic ActiveModel style.
4. `#sync` writes form data back to the model. This will only use setter methods on the model(s).
5. `#save` (optional) will call `#save` on the model and nested models. Note that this implies a `#sync` call.
6. `#prepopulate!` (optional) will run pre-population hooks to "fill out" your form before rendering.

In addition to the main API, forms expose accessors to the defined properties. This is used for rendering or manual operations.


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

## Rendering Forms

Your `@form` is now ready to be rendered, either do it yourself or use something like Rails' `#form_for`, `simple_form` or `formtastic`.

    = form_for @form do |f|
      = f.input :title

Nested forms and collections can be easily rendered with `fields_for`, etc. Note that you no longer pass the model to the form builder, but the Reform instance.

Optionally, you might want to use the `#prepopulate!` method to pre-populate fields and prepare the form for rendering.


## Syncing Back

After validation, you have two choices: either call `#save` and let Reform sort out the rest. Or call `#sync`, which will write all the properties back to the model. In a nested form, this works recursively, of course.

It's then up to you what to do with the updated models - they're still unsaved.


## Saving Forms

The easiest way to save the data is to call `#save` on the form.

    if @form.validate(params[:song])
      @form.save  #=> populates album with incoming data
                  #   by calling @form.album.title=.
    else
      # handle validation errors.
    end

This will sync the data to the model and then call `album.save`.

Sometimes, you need to do saving manually.

## Saving Forms Manually

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

## Nested Processing

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



