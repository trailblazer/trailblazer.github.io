# Pipeline

property :title, parse_pipeline: ->(*) { [Upcase, Pluralize] }

array has to be callable


Pipeline is always (input, options), return new input

## Insert

### Replace
 pipeline = P[R::Get, R::Collect[R::Get, R::StopOnSkipable], R::StopOnNil]

      P::Insert.(pipeline, R::Default, replace: R::StopOnSkipable).extend(P::Debug).inspect.must_equal "Pipeline[Get, Collect[Get, Default], StopOnNil]"
      pipeline.must_equal P[R::Get, R::Collect[R::Get, R::StopOnSkipable], R::StopOnNil]


### Delete
      P::Insert.(pipeline, R::Get, delete: true).extend(P::Debug).inspect.must_equal "Pipeline[Collect[Get, StopOnSkipable], StopOnNil]"
