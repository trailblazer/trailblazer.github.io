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


## Validation

You now invoke the operation with a JSON document, not with a hash anymore.


    Song::Create.(song: '{"title": "Fury"}')


In `Operation#validate`, the incoming `params[:song]` will now be treated as a document.

The operation's representer will be passed into the form's `validate` and used as the deserializer, as it can read JSON and understands the format's specific semantics.

After deserialization/population is finished, validation and processing is analogue to a "normal" non-representer operation.



## Rendering

The `Representer` module also imports `to_json`.


    Song::Create.(song: '{"title": "Fury"}').to_json
    #=> '{"title": "Fury","_links":{"self":"/songs/1"}}'


In `to_json`, the operation's contract will be passed to the representer and rendered using the representer.

## Composable Interface

You can set your own representer class if you don't want it to be inferred.


    class Create < Trailblazer::Operation
      self.representer_class = SongRepresenter


## Responder

The `Operation::Responder` module uses `Representer` and allows using an operation instance directly with Rails responders.