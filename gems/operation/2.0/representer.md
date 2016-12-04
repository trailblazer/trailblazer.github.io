---
layout: operation2
title: Operation Representer
gems:
  - ["trailblazer", "trailblazer/trailblazer", "2.0", "1.1"]
---

Representers help to parse and render documents for JSON or XML APIs.

After defining a representer, it can either parse an incoming document into an object graph, or, the other way round, serialize a nested object into a document.

You can use representers from the [Representable](/gems/representable) gem with your operations.

Check the [→ full example](#full-example) for a quick overview.

<div class="callout secondary">
  <p>
    Parsing needs Representable >= 3.0.2.
  </p>
</div>

## Parsing: Introduction

In Trailblazer, the normal workflow is to deserialize (parse) incoming data into an object graph, then validate this data structure, then persist parts of it. Transforming the incoming data into one or many objects is done by a representer.

Normally, this happens internally in the Reform object, which receives the data in `validate` and then uses an automatically infered representer to parse the data onto itself.

However, let's discuss representers first and ignore the validation layer.

What the representer does and how it interacts with the contract (or any Ruby object) can be explained in a simple example.

Imagine the following incoming **document** from a form submission.

    {
      "title" => "Let Them Eat War",
      "band"  => "Bad Religion"
    }

In this case the document is a hash, but Representable allows parsing JSON, XML and YAML, too.

To process this document a **representer** must be defined.

    class SongRepresenter < Representable::Decorator
      include Representable::Hash # the document format.

      property :title
      property :band
    end

Representers are provided by the Representable and Roar gems. They look a lot like contracts, but define the structure of the documents, only, no semantics or validations.

When parsing, the representer simply traverses the document and writes every known attribute to the **represented object**. The latter can be any kind of object, it only has to expose property setters.

    Song = Struct.new(:title, :band)

While you will usually use models (e.g. `ActiveRecord`) or contracts with representers, a simple struct is sufficient for explaining.

Parsing the document onto a `Song` instance is very straight-forward.

    input = { "title" => "Let Them Eat War", "band" => "Bad Religion" }

    song  = Song.new # this doesn't have to be an empty object.

    SongRepresenter.new(song).from_hash(input)

In pseudo-code, the representer literally only walks through the hash and assigns values to the model.

    # SongRepresenter#from_hash
      song.title = input["title"]
      song.band  = input["band"]

After the parsing, your represented model is populated with the values.

    song.title #=> "Let Them Eat War"
    song.band  #=> "Bad Religion"

Representers increasingly make sense with documents differing from your models, for complex media formats such as JSON API, and also for nested documents.

## Parsing: Nesting

While one-level parsing might appear trivial and easily solveable using mechanisms such as `update_attributes` and Rails' automatic parsed `params` hash, the deserialization process gets more complicated with nested fragments and models.

Let's assume the `band:` property should now be a dedicated object. Here's the new **document**.

    {
      "title" => "Let Them Eat War",
      "band"  => {
        "name" => "Bad Religion"
      }
    }

When parsing this document, a new `Band` object should be created, attached to the song, and assigned a name.

Again, the `Band` **model** could be provided by any ORM, or simply be a struct.

    Band = Struct.new(:name)

The **representer** to implement parsing and creating looks as follows.

    class SongRepresenter < Representable::Decorator
      include Representable::Hash # the document format.

      property :title
      property :band, class: Band do
        property :name
      end
    end

The `class:` option is the easiest way to tell a representer to create an object for a nested fragment. This is called *population* and deserves [its own documentation section](/gems/representable/populator.html) as it exposes a few ways, such as find-or-create, instantiate, and so on.

Parsing the nested document will now result in a nested object graph.

    input = { "title" => "Let Them Eat War", "band" => { "name" => "Bad Religion" } }

    song  = Song.new # this doesn't have to be an empty object.

    SongRepresenter.new(song).from_hash(input)

The representer will deserialize the nested fragment into its own model, the way you specified (or override) it.

    song.title #=> "Let Them Eat War"
    song.band  #=> #<struct Band name="Bad Religion">
    song.band.name #=> "Bad Religion"

As you can see, all the representer does when parsing is following its specified schema, assign property values to the model or creating/finding nested models, which it recurses then onto.

TODO: link to populator docs.

## Parsing with Contract

The aforementioned parsing also works against a Reform contract instead of a pure model. Consider the following contract.

    class SongContract < Reform::Form
      property :title
      property :band

      validates :title, presence: true
      validates :band, presence: true
    end

To validate this contract, you actually pass it a *document*.

    input = { "title" => "Let Them Eat War", "band" => "Bad Religion" }

    SongContract.new(song).validate(input)

The only real difference to the above examples is that Reform will validate itself after the deserialization. In other words: In `validate`, Reform uses a representer to deserialize the document to itself, then runs its validation logic.

<div class="row colums text-center">
<p>
  <img src="/images/diagrams/reform-architecture.png">
</p>
</div>

[→ Reform's architecture docs](/gems/reform) talk about this in detail.

Reform infers this representer (or *deserializer*) automatially in `validate` and that is fine for most HTML forms where the contract schema and form layout are identical. In document APIs, whatsoever, the documents format often doesn't match 1-to-1 with the contract's schema. For example, when validating input in a JSON API system.

This is where you can specify your own representer to be used against the contract.

<div class="callout secondary">
  <p>
    The idea is to decouple the validation (contract) from the document structure (representer). A contract shouldn't be aware of the environment it is being used in, and the representer mustn't have any knowledge about validations and the underlying persistence layer.
  </p>
</div>

How that is done is discussed in the following sections.

## Parsing: Explicit

Instead of using Reform's automatic representer to deserialize the incoming document, the `Contract::Validate` macro allows you to specify a different representer.

This requires a representer class.

{{  "representer_test.rb:explicit-rep" | tsnippet }}

While this representer could be used stand-alone, the operation helps you to leverage it for parsing.

{{  "representer_test.rb:explicit-op" | tsnippet }}

In the `Validate` macro, the `representer:` option will set the specified representer for deserialization. Note that the contract can also be an inline contract.

You may now pass a JSON document instead of a hash into the operation's call.

{{  "representer_test.rb:explicit-call" | tsnippet }}

This parses the JSON document and the representer will assign the property values and objects to the contract. Afterwards, the contract validates itself with the normal mechanics.

In fact, the contract doesn't even know its data was parsed from a JSON or XML document.

## Parsing: Inline Representer

If you quickly want to try a representer or you're facing a small amount of properties, only, you can use an inline representer.

{{  "representer_test.rb:inline" | tsnippet }}

The behavior is identical to referencing the representer class constant.

## Parsing: Infer

A representer can also be infered from the contract's schema. All you need to do is define the format, e.g. `Representable::JSON`.

{{  "representer_test.rb:infer" | tsnippet }}

The `Operation::Representer.infer` method will return a representer class.

## Parsing: Dependency Injection

You can override the parsing representer when calling the operation with dependency injection. This allows things like exchanging the representer to parse other document formats, such as XML.

{{  "representer_test.rb:di-rep" | tsnippet }}

The representer can be injected using Trailblazer's well-defined injection interface.

{{  "representer_test.rb:di-call" | tsnippet }}

Note how the XML representer replaces the built-in JSON representer and can parse the XML document to the contract. The latter doesn't know anything about the swapped documents.

## Naming

Without a name specified, the representer will be named `default`.


{{  "representer_test.rb:naming" | tsnippet }}

To maintain multiple representers per operation, you may name them.

    representer :parse, MyRepresenter
    representer :errors, ErrorsRepresenter

They are now accessable via their named path.

    Create["representer.parse.class"] #=> MyRepresenter


## Rendering: Introduction

In a document API system, after processing the operation, you usually want to render a response document. While you could use something like `ActiveModel::Serializer` for this, it makes sense to reuse a representer.

    class SongRepresenter < Representable::Decorator
      include Representable::JSON # the document format.

      property :title
      property :band
    end

Given the following model.

    song  #=> #<struct Song title="Let Them Eat War" band="Bad Religion">

The mechanics when rendering are very similar to what happens when parsing.

    SongRepresenter.new(song).to_json #=> '{"title":"Let Them Eat War","band": "Bad Religion"}'

In pseudo-code, the representer literally only walks through its schema, asks the model for the property values and serializes them into a document.

    # SongRepresenter#to_json
      json = {}
      json[:title] = song.title
      json[:band]  = song.band
      json.to_json

Representers are very helpful when introducing media formats such as HAL or JSON API, or when having to render complex XML documents from a nested object graph. The only requirement they have are the model's readers.

Go and read a bit about [Representable](/gems/representable) to learn more about mapping, aliases, media formats, and more.

## Rendering: Example

Rendering a document after the operation finished is part of the presentation layer, which should *not* happen inside the operation itself. Serializing a document is to happen where the operation was called, such as a controller.

However, you may use the result object to grab representers and models.

{{  "representer_test.rb:render" | tsnippet }}

Luckily, [`Endpoint`](endpoint.html) and `respond` in Rails controllers help you with this.

## Full Example

Often, an operation will maintain multiple representers, e.g. for parsing, to render into a specific media format, and to handle error cases.

You could have a generic errors representer.

{{  "representer_test.rb:errors-rep" | tsnippet }}

Using naming, the operation may then contain several representers.

{{  "representer_test.rb:full" | tsnippet }}

Note that you don't even have to hook those representers into the operation class - this is a convention for structuring.

An exemplary controller method to handle both outcomes could look like the following snippet.

{{  "representer_test.rb:full-call" | tsnippet }}


Make sure to check out [Endpoint](endpoint.html) which bundles the most common outcomes for you and is easily extendable.
