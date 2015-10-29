##

## Loose Coupling

The components of Trailblazer are usable in any framework: Rails, Sinatra, Lotus, Roda, Grape or Webmachine - you name it.

Trailblazer decouples your business code from the framework you use. This will not only give you a simpler architecture, it will also speed up framework updates, increase performance and simplify testing.


## Trailblazer brings more abstraction layers

While this might sound like more technical complexity, this actually simplifies crafting applications.

Trailblazer identifies the workflows of processing web requests from dispatching to rendering a response and provides a place for each step.

The new abstraction layers are more intuitive: developers now understand where to put code.

## Trailblazer picks you up where Rails left you

where to put code?

## Modular: Pick What You Need

Trailblazer is a collection of very mature gems. Gems that have been around for many years and are in use in ten-thousands of production apps.

You pick what you need.

Cells

Operation

Reform

Representable/Roar

Disposable

## Faster, Easier to Debug, Understandable

Each layer in Trailblazer has a minimal scope and no access to global state. Debugging turns into quick tests against the problematic components. Where finding performance bottlenecks in Rails is impossible as you need a degree in ActiveRecord, in Trailblazer this is a matter of observing profilers, disabling suspicous components and fixing the leaks.

## Intuitive File Layout

A new file layout organizes files by domain, not by technology. Functions in your application now belong to standalone components that can easily be shared as gems and make navigation easier.

New developers will find their way into the project much faster than in a traditional Rails setup.

By structuring the application into concepts, less merge conflicts will happen, and duplication is almost ausgeschlossen as locations of logic are very clear.