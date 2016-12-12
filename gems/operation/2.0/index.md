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
      Operations are usually invoked straight from the controller action. They orchestrate all domain logic necessary to perform the app's function.
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
        <code class="name">Contract::Build</code>, <code class="name">Validate</code> and <code class="name">Persist</code> help dealing with Dry schemas or Reform contracts to validate input, and push sane data to models.
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


## Result
