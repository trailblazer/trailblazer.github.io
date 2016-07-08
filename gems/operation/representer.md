---
layout: operation
title: "Operation with Representers"
---

# Operation::Representer

Representer are a concept from Representable and [Roar](/gems/roar) and help to parse and render documents, as found in JSON or XML APIs.

Operations usually receive the `params` hash and pass this to the form's `#validate` method. The same works with documents, with the exception that the form needs a representer to deserialize the document.

With `Representer` included, operations can infer a representer from the contract class. The representer can be further customized in the `::representer` block.


    class Song::Create < Trailblazer::Operation
      include Representer

      contract do
        property :name
        validates :name, presence: true
      end

      representer do
        # inherited :name
        include Roar::JSON::HAL

        link(:self) { song_path(represented.id) }
      end

      def process(params)
        validate(params[:song]) do # params[:song] is a JSON document.
          contract.save
        end
      end
    end


## Deserialization

You now invoke the operation with a JSON document, not with a hash anymore.


    Song::Create.(song: '{"title": "Fury"}')


In `Operation#validate`, the incoming `params[:song]` will now be treated as a document.

The operation's representer will be passed into the form's `validate` and used as the deserializer, as it can read JSON and understands the format's specific semantics.

If you prefer to use the `params` hash for deserialization, include `Deserializer::Hash`.

    class Create < Trailblazer::Operation
      include Representer
      include Representer::Deserializer::Hash

You can now pass the params hash into operation call. This will still use the representer, but no JSON parsing will happen.

## Validation

After deserialization/population is finished, validation and processing is analogue to a "normal" non-representer operation.


## Rendering

The `Representer` module also imports `to_json`.

    Song::Create.(song: '{"title": "Fury"}').to_json
    #=> '{"title": "Fury","_links":{"self":"/songs/1"}}'

In `to_json`, the operation's _model_ will be passed to the representer and rendered using the representer.

For a better understanding, here are the pseudo mechanics.

    module Representer
      def to_json(options={})
        self.class.representer. # retrieve operation's representer.
          new(represented).     # instantiate decorator. #represented returns #model.
          to_json(options)      # call decorator's rendering.
      end
    end

If you want to render the contract instead (or anything else), override `Operation#represented`.

    class Show < Trailblazer::Operation
      include Trailblazer::Operation::Representer

      def represented
        contract
      end

### Passing Options

Note that you can also pass your own options to the rendering.

    class Show < Trailblazer::Operation
      include Trailblazer::Operation::Representer

      def to_json(*)
        super(
          include:      [:title, :comments],
          user_options: { is_admin: policy.signed_in? }
        )
      end

To learn how Representable processes options, read [the docs](/gems/representable/3.0/api.html#user-options).

## Input and Output Representers

The idea when including `Representer` is that you want the same representer to deserialize input and render the response document.

Sometimes, this is not desired, and you want to use different representers for handling input and output.

To use a representer for rendering, only, include `Rendering`.

    class Create < Trailblazer::Operation
      extend Representer::DSL
      include Representer::Rendering

      representer do # will be used in #to_json.
        property :genre, as: :songGenre
      end

This will only add `Operation#to_json`. Parsing will still be done without a representer.

Alternatively, you can implement the rendering yourself by only including a `Deserializer` module.

    class Create < Trailblazer::Operation
      extend Representer::DSL
      include Representer::Deserializer::Hash

      representer do # will be used in #validate.
        property :genre, as: :songGenre
      end

      def to_json(*)
        Create::Representer.new(model).to_json
      end

Note that you need to always extend `Representer::DSL` to import the `representer` block.

## Composable Interface

You can set your own representer class if you don't want it to be inferred.


    class Create < Trailblazer::Operation
      self.representer_class = SongRepresenter


## Responder

The `Operation::Responder` module adds methods to use an operation instance directly with Rails responders. This is why this module comes from the `traiblazer-rails` gem.

```ruby
class Create < Trailblazer::Operation
  include Responder
  include Representer

  representer ..
end
```

The operation can now be passed to `respond_to`.

```ruby
def create
  op = Comment::Create.(params)
  respond_to op
end
```

This is done automatically when using `Trailblazer::Controller#respond`.

```ruby
def create
  respond Comment::Create
end
```
