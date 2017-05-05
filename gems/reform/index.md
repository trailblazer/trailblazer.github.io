---
layout: reform
permalink: /gems/reform/
title: "Reform"
gems:
  - ["reform", "trailblazer/reform"]
---

Reform provides form objects to run validations for one or multiple models.

## Overview

Validations no longer sit in model classes, but in forms. Once the data is coerced and validated, it can be written to the model.

A _model_ can be any kind of Ruby object. Reform is completely framework-agnostic and doesn't care about your database.

A *form* doesn't have to be a UI component, necessarily! It can be an intermediate validation before writing data to the persistence layer. While form objects may be used to render graphical web forms, Reform is used in many pure-API applications for deserialization and validation.


* **API** In Reform, form classes define fields and validations for the input. This input can be validated using `validate` and written to the model using `sync` or `save`. [→ API](api.html)
* **DATA TYPES** Reform can map model attributes, compositions of objects, nested models, hash fields and more. [→ DATA TYPES](data-types.html)
* **COERCION** When validating, the form can coerce input to arbitrary values using the dry-types gem. [→ COERCION](options.html#coercion)
* **POPULATOR** Deserialization of the incoming data can be customized using populators. [→ POPULATOR](populator.html)
* **VALIDATION GROUPS** Validations can be chained or run when certain criteria match, only. [→ VALIDATION GROUPS](validation.html#validation-groups)

For a technical architecture overview, read the [Architecture](#architecture) section.

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

While Reform is perfectly suited to map nested models with associations, it also allows mapping via composition, to hash fields, and more. Check out the [supported data types](data-types.html).

## Setup

In your controller or operation you create a form instance and pass in the models you want to validate data against.


    class AlbumsController < ApplicationController
      def new
        @form = AlbumForm.new(Album.new)
      end


This will also work as an editing form with an existing album.

    def edit
      @form = AlbumForm.new(Album.find(1))
    end


In setup, Reform will read values from the model.

    model = Album.find(1)
    model.title #=> "The Aristocrats"

    @form = AlbumForm.new(model)
    @form.title #=> "The Aristocrats"

Once read, the original model's values will never be accessed.

## Rendering

Your `@form` is now ready to be rendered, either do it yourself or use something like Rails' `#form_for`, `simple_form` or `formtastic`.

    = form_for @form do |f|
      = f.input :title

Nested forms and collections can be easily rendered with `fields_for`, etc. Note that you no longer pass the model to the form builder, but the Reform instance.

Optionally, you might want to use the `#prepopulate!` method to pre-populate fields and prepare the form for rendering.

## Validation

A submitted form is processed via `validate`.

    result = @form.validate(title: "Greatest Hits")

By passing the incoming hash to `validate`, the input is written to the form and validated.

This usually happens in a processing controller action.

    def create
      @form = AlbumForm.new(Album.new)

      if @form.validate(params[:album])
        # persist data
        @form.save
      end
    end

After validation, the form's values reflect the validated data.

    @form.validate(title: "Greatest Hits")
    @form.title #=> "Greatest Hits"

Note that the model remains untouched - validation solely happens on the form object.

    model.title #=> "The Aristocrats"

Reform never writes anything to the models, until you tell it to do so.

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

## Installation

{% tabs %}
~~Dry-validation
Add this your Gemfile.

    gem "reform"
    gem "dry-validation"

Please use [dry-validation](http://dry-rb.org/gems/dry-validation), which is our recommended validation engine. Put the following snippet into an initializer.

    require "reform/form/dry"

    Reform::Form.class_eval do
      include Reform::Form::Dry
    end

~~ActiveModel
Add this to your Gemfile.

    gem "reform"
    gem "reform-rails"

To use `ActiveModel` for validations put this into an initializer.

    require "reform/form/active_model/validations"

    Reform::Form.class_eval do
      include Reform::Form::ActiveModel::Validations
    end

Things you should know when using ActiveModel with Reform.

* `ActiveModel` support is provided by the `reform-rails` gem. You have to add it to your `Gemfile`.
* The above last step of including `ActiveModel::Validations` is done automatically in a Rails environment.
* Reform works fine with Rails 3.1-4.2. However, inheritance of validations with `ActiveModel::Validations` is broken in Rails 3.2 and 4.0.

{% endtabs %}


## Design Concepts

* **FRAMEWORK-AGNOSTIC** Reform is completely framework-agnostic and is used in many projects with Rails, Sinatra, Hanami and more.

  For Rails, the [reform-rails gem](rails.html) provides convenient glue code to make Reform work with Rails' form builders and `ActiveModel::Validations`.

* **ORMs** Reform works with any ORM or PORO - it has zero knowledge about underlying databases per design. The only requirements are reader and writer methods on the model(s) for defined properties.

* **DATA MAPPING** Reform helps mapping one or many models to a form object. Nevertheless, Reform is *not* a full-blown data mapper. It still is a form object. Simple data mapping like composition, delegation or hash fields come from the [Disposable](/gems/disposable/index.html) gem.

  Should you require more complex mapping, use something such as ROM and pass it to the form object.

* **SECURITY** Reform simply ignores unsolicited input in `validate`. It does so by only accepting values for defined `property`s. This makes half-baked solutions like `strong_parameter` or `attr_accessible` obsolete.


## Architecture

When experiencing Reform for the first time, it might seem to do a lot, too much: It decorates a model, parses the incoming data into some object graph, validates the data somehow and supports writing this data back to the model.

Actually, Reform is very simple and consists of several smaller objects. Each object has a very specific scope one does exactly one thing, where the actual form object orchestrates between those.

<div class="row colums text-center">
<p>

  <img src="/images/diagrams/reform-architecture.png">
</p>
</div>

**SETUP** When instantiating the form object with a model, it will read its properties' values from the model. Internally, this happens because a [form is simply a `Twin`](https://github.com/apotonick/reform/blob/777ea4730bec913582bae78fece78bbb76fb22c4/lib/reform/contract.rb#L6). [Twins are light-weight decorator objects](/gems/disposable) from the Disposable gem.

For nested properties or collections, nested form objects will be created and wrap the respective contained models.

**DESERIALIZATION** In the `validate` method, the incoming hash or document is parsed. Each known field is assigned to the form object, each nested fragment will be mapped to a nested form. This process is known as *deserialization*.

The internal deserializer used for this is actually a *representer* from the Representable gem. It is [inferred automatically by Reform](https://github.com/apotonick/reform/blob/777ea4730bec913582bae78fece78bbb76fb22c4/lib/reform/form/validate.rb#L43), but theoretically, you could provide your own deserializer that goes through the document and then calls setters on the form.

**POPULATOR** Nested fragments in the document often need to be mapped to existing or new models. This is where *populators* in Reform help to find the respective model(s), wrap them in a nested form object, and create a virtual object graph of the parsed data.

Populators are code snippets you define in the form class, but they are called from the deserializing representer and help parsing the document into a graph of objects.

**VIRTUAL OBJECT GRAPH** After deserialization, the form object graph represents the input. All data in `validate` has been written to the virtual graph, **not to the model**. Once this graph is setup, it can be validated.

The deserialization process is the pivotal part in Reform. Where simple validation engines only allow formal validations, Reform allows rich business validations such as *"When user signed in, and it's the first order, allow maximum 10 items in the shopping cart!"*.

**VALIDATION** For the actual validation, Reform uses existing solutions such as dry-validation or `ActiveModel::Validations`. It passes the data to the validation engine in the appropriate format - usually, this is a hash representing the virtual object graph and its data.

The validation is then completely up to the engine. Reform doesn't know what is happening, it is only interested in the result and error messages. Both are exposed via the form object after validation has been finished.

The decoupled validation is why Reform provides multiple validation engines.

**SYNC/SAVE**

After the `validate` call, nothing has been written to the model(s), yet. This has to be explicitly invoked via `sync` or `save`. Now, Reform will use its basic twin functionality again and write the virtual data to the models using public setter methods. Again, Reform knows nothing about ORMs or model specifics.
