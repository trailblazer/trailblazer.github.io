##

## Trailblazer brings more abstraction layers

Abstraction layers simplify implementing sets of functionality, allowing for separation of concerns.

While this might sound like more technical complexity, Trailblazer identifies the workflows of processing web requests from dispatching to rendering a response and provides a place for each step.

The new abstraction layers are more intuitive: developers now understand where to put code.

## Trailblazer picks you up, where Rails left off

Rails is a popular web framework for ruby. It is used as a teaching aid to teach people of all ages how to program web applications.

Rails does an awesome job at introducing the basics to developers, however, code can grow and Rails code can be a bit unwieldy once it becomes a monolith. Trailblazer provides that next piece of the puzzle, to refactor your applications into lean trailblazers.

## Loose Coupling

Trailblazer decouples your business logic from the framework you use.

The components of Trailblazer are usable in any framework: Rails, Sinatra, Lotus, Roda, Grape or Webmachine - you name it.

This provides your applications with a cleaner architecture, which allows for easier framework updates, increased performance and simple, concise tests, which decreases overall development time.

## Faster, Easier to Debug, Understandable

Each layer in Trailblazer has a minimal scope and no access to global state. Debugging turns into quick tests against the problematic components. Where finding performance bottlenecks in Rails is difficult, in Trailblazer this is a matter of observing profilers, disabling suspicous components and fixing the leaks.

## Intuitive File Layout

A new file layout organizes files by domain, not by technology. Functions in your application now belong to standalone components that can easily be shared as gems and make navigation easier.

New developers will find their way into the project much faster than in a traditional Rails setup.

By structuring the application into concepts, less merge conflicts will happen, and duplication is almost ausgeschlossen as locations of logic are very clear.

## Modular: Pick What You Need

Trailblazer is a collection of very mature gems. Gems that have been around for many years and are in use in ten-thousands of production apps.

You pick what you need.

Cells

Operation

Reform

Representable/Roar

Disposable
