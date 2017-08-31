## Result

### Primary Binary State

The primary state is decided by the activity's end event superclass. If derived from `Railway::End::Success`, it will be interpreted as successful, and `result.success?` will return true, whereas a subclass of `Railway::End::Failure` results in the opposite outcome. Here, `result.failure?` is true.

### Result: End Event

You can access the end event the Result wraps via `event`. This allows to interpret the outcome on a finer level and without having to guess from data in the options context. (See Endpoint)

    result = Create.( params )

    result.event #=> #<Railway::FastTrack::PassFast ...>
