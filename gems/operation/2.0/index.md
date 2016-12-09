---
layout: operation2
title: Operation Overview
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0", "1.1"]
---

<img src="/images/diagrams/operation-2017-small.png" class="diagram left">

An operation is a service object.

Its goal is simple: Remove all business logic from the controller and model and instead provide a separate, streamlined object for it.


Operations implement functions of your application, like creating a comment, following a user or exporting a PDF document. Sometimes this is also called _command_.


Technically, an operation embraces and orchestrates all business logic between the controller dispatch and the persistance layer. This ranges from tasks as finding or creating a model, validating incoming data using a form object to persisting application state using model(s) and dispatching post-processing callbacks or even nested operations.

Note that operation is not a monolithic god object, but a composition of many stakeholders. It is up to you to orchestrate features like policies, validations or callbacks.

## What It Looks Like

<section class="macros">
  <div class="row">
    <div class="column medium-6">
    <p>
      Operations are usually invoked straight from the controller action, they contain all domain logic necessary to perform the app's function.
    </p>
<pre>
<code>
result = Song::Create.({ title: "SVT" })
</code>
</pre>

    <p>
      There is only one way to run an operation: using <code>Operation.call</code>. This can also be written as <code>Operation.()</code>.
    </p>

    <p>
    The absence of a method name here is per design: this object does only one thing, and hence <strong>what it does is reflected in the class name</strong>.
    </p>

<pre>
<code>
result = Song::Create.(
  params,
  "current_user" => Warden.get_user
)
</code>
</pre>

    <p>
    You have to pass all runtime data to the operation in this call. <code>params</code>, current user, you name it.
    </p>

    </div>

    <div class="column medium-6">
    <p>
    The implementation is a class.
    </p>

{{  "operation_test.rb:op" | tsnippet }}
    </div>
  </div>

</section>








The operations control flow is handled by a two-tracked pipe. It helps you dealing with errors without littering your code with `if`s and `rescue`s. You can add your own, custom steps to that workflow and use Trailblazer's built-in macros.

## Flow Control

<section class="macros">
  <div class="row">
    <div class="column medium-3">
      <img src="/images/diagrams/overview-flow-animated.gif">
    </div>

    <div class="column medium-4">
      <p>
        An operation has a two-tracked flow called a <em>pipe</em>. On the right track you add <em>steps</em> for the happy path, assuming no errors happen using <code>step</code>. They will executed in the order you add them.
      </p>

      <p>
        On the left track, you add error handler steps using <code>failure</code>. They work exactly like the right track, but won't be executed until you deviate from the right track.
      </p>
    </div>

    <div class="column medium-5">
<pre>
<code>
  step     Model( Song, :new )
  consider :assign_current_user!
  step     Contract::Build()
  step     Contract::Validate( )
  failure  :log_error!
  step     Contract::Persist(  )
</code>
</pre>
      <p>
        Steps added with <code>consider</code> will deviate to the left track, if their return value is falsey.

      </p>
    </div>

  </div>
</section>

## Macros

Trailblazer comes with a set of helpful pipe macros that give you predefined step logic to implement the most common tasks.

<section class="macros">
  <div class="row">
    <div class="column medium-4">
      <i class="fa fa-cogs"></i>

      <p><code class="name"><a href="api.html#nested">Nested</a></code>, <code class="name"><a href="api.html#wrap">Wrap</a></code> and <code class="name"><a href="api.html#rescue">Rescue</a></code> help to nest operations, or wrap parts of the pipe into a <code>rescue</code> statement, a transaction, etc.</p>
    </div>

    <div class="column medium-4">
      <i class="fa fa-search"></i>

      <p>
        <code class="name">Contract::Build</code>, <code class="name">Validate</code> and <code class="name">Persist</code> are macros to build and validate Dry schemas or Reform contracts, and to push sane data to models.
      </p>
    </div>

    <div class="column medium-4">
      <i class="fa fa-shield"></i>

      <p>
        <code class="name"><a href="policy.html#guard">Guard</a></code> and <code class="name"><a href="policy.html#pundit">Policy::Pundit</a></code> are ideal steps to protect operations (or parts of it) from being run unauthorized.
      </p>
    </div>

  </div>
</section>

Macros are easily extendable and it's you can write your own application-wide macros.




The generic logic can be found in the trailblazer-operation gem. Higher-level abstractions, such as form object or policy integration is implemented in the trailblazer gem.

* Overview
* Papi::Operation extend Contract::DSL


<hr>


An operation is a Ruby object that embraces all logic needed to implement one function, or *use case*, of your application. It does so by orchestrating various objects like form objects for validations, models for persistence or callbacks to implement post-processing logic.

While you could do all that in a nested, procedural way, the Trailblazer operation uses a pipetree to structure the control flow and error handling.

    class Create < Trailblazer::Operation
    end

## Invocation

An operation is designed like a function and it can only be invoked in one way: via `Operation::call`.

    Create.call( name: "Roxanne" )

Ruby allows a shorthand for this which is commonly used throughout Trailblazer.

    Create.( name: "Roxanne" )

The absence of a method name here is per design: this object does only one thing, has only one public method, and hence **what is does is reflected in the class name**. Likewise, you never instantiate operations manually - this contradicts its functional concept and prevents you from randomly running methods on it in the wrong order.

Running an operation will always return a result object. It is up to you to interpret the content of it or push data onto the result object during the operation's cycle.

    result = Create.call( name: "Roxanne" )

[→ Result object](#result-object)


## Flow Control: Procedural

There's nothing wrong with implementing your operation's logic in a procedural, nested stack of method calls, the way Trailblazer 1.x worked. The behavior here was orchestrated from within the `process` method.

    class Create < Trailblazer::Operation
      self.> Process

      def process(params)
        model = Song.new

        if validate(params)
          unless contract.save
            handle_persistence_errors!
          end
          after_save!
        else
          handle_errors!
        end
      end
    end

Even though this might seem to be more "readable" at first glance, it is impossible to extend without breaking the code up into smaller methods that are getting called in a predefined order - sacrificing its aforementioned readability.

Also, error handling needs to be done manually at every step. This is the price you pay for procedural, statically nested code.

## Flow Control: Pipetree

You can also use TRB2's new *pipetree*. Instead of nesting code statically, the code gets added sequentially to a pipeline in a functional style. This pipeline is processed top-to-bottom when the operation is run.

    class Create < Trailblazer::Operation
      self.> :model!
      self.> :validate!
      self.> :persist!

      def model!(options)
        Song.new
      end
      # ...
    end

Logic can be added using the `Operation::>` operator. The logic you add is called *step* and can be [an instance method, a callable object or a proc](api.html).

Under normal conditions, those steps are simply processed in the specified order. Imagine that as a track of tasks. The track we just created, with steps being applied when things go right, is called the *right track*.

The operation also has a *left track* for error handling. Steps on the right side can deviate to the left track and remaining code on the right track will be skipped.

    class Create < Trailblazer::Operation
      self.> :model!
      self.> :validate!
      self.< :validate_error!
      self.> :persist!
      self.< :persist_error!
      # ...
    end

Adding steps to the left track happens via the `Operation::<` operator.

## Pipetree Visualization

Visualizing the pipetree you just created makes is very obvious what is going to happen when you run this operation. Note that you can render any operation's pipetree anywhere in your code for a better understanding.

    Create["pipetree"].inspect

     0 =======================>>operation.new
     1 ===============================>:model
     2 ============================>:validate
     3 <:validate_error!=====================
     4 ============================>:persist!
     5 <:persist_error!======================

Once deviated to the left track, the pipetree processing will skip any steps remaining on the right track. For example, should `validate!` deviate, the `persist!` step is never executed (unless you want that).

Now, how does a step make the pipetree change tracks, e.g. when there's a validation error?

## Track Deviation

The easiest way for changing tracks is letting the pipetree interpret the return value of a step. This is accomplished with the `Operation::&` operator.

    class Create < Trailblazer::Operation
      self.> :model!
      self.& :validate!
      self.< :validate_error!
      # ...
    end

Should the `validate!` step return a falsey value, the pipetree will change tracks to the left.

    class Create < Trailblazer::Operation
      # ...
      def validate!(*)
        self["params"].has_key?(:title) # returns true of false.
      end
    end

Check the [API docs for pipetree](pipetree.html) to learn more about tracks.

## Step Macros

Trailblazer provides predefined steps to for all kinds of business logic.

* [Contract](contract.html) implements contracts, validation and persisting verified data using the model layer.

## Orchestration


## Result Object

result.contract [.errors, .success?, failure?]
result.policy [, .success?, failure?]
