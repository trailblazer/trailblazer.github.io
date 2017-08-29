---
layout: operation2
title:  Operation Overview
url:    /gems/operation/2.0/index.html
gems:
  - ["operation", "trailblazer/trailblazer-operation", "2.0", "1.1"]
description: "An overview about the Operation in Trailblazer: an object that embraces and orchestrates all business logic for one function."
imageurl: http://trailblazer.to/images/diagrams/operation-2017-small.png
redirect_from:
  - /gems/operation/
  - /gems/operation/index.html
---

<img src="/images/diagrams/operation-2017-small.png" class="diagram left">

An operation is a service object.

Its goal is simple: **Remove all business logic from the controller and model and provide a separate, streamlined object for it.**


Operations implement functions of your application, like creating a comment, following a user or exporting a PDF document. Sometimes this is also called _command_.


Technically, an operation embraces and orchestrates all business logic between the controller dispatch and the persistence layer. This ranges from tasks as finding or creating a model, validating incoming data using a form object to persisting application state using model(s) and dispatching post-processing callbacks or even nested operations.

Note that an operation is not a monolithic god object, but a composition of many stakeholders. It is up to you to orchestrate features like policies, validations or callbacks.

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
    The absence of a method name here is by design: this object does only one thing, and hence <strong>what it does is reflected in the class name</strong>.
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

{{  "operation_test.rb:op:../trailblazer/test/docs:2-0" | tsnippet }}
    </div>
  </div>

</section>








The operation's control flow is handled by a two-tracked pipe. This helps you deal with errors without littering your code with `if`s and `rescue`s. You can add your own, custom steps to that workflow and use Trailblazer's built-in macros.

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
  step     :assign_current_user!
  step     Contract::Build()
  step     Contract::Validate( )
  failure  :log_error!
  step     Contract::Persist(  )
</code>
</pre>
      <p>
        Steps will deviate to the left track if their return value is falsey.

      </p>
    </div>

  </div>
</section>

## Macros

Trailblazer comes with a set of helpful pipe macros that give you predefined step logic to implement the most common tasks.

{% row %}
~~~4
  <i class="engage fa fa-cogs"></i>

  <code class="name"><a href="api.html#nested">Nested</a></code>, <code class="name"><a href="api.html#wrap">Wrap</a></code> and <code class="name"><a href="api.html#rescue">Rescue</a></code> help to nest operations, or wrap parts of the pipe in a <code>rescue</code> statement, a transaction, etc.

~~~4
  <i class="engage fa fa-search"></i>

  <code class="name">Contract::Build</code>, <code class="name">Validate</code> and <code class="name">Persist</code> help dealing with Dry schemas or Reform contracts to validate input, and push sane data to models.
~~~4
  <i class="engage fa fa-shield"></i>

  <code class="name"><a href="policy.html#guard">Guard</a></code> and <code class="name"><a href="policy.html#pundit">Policy::Pundit</a></code> are ideal steps to protect operations (or parts of it) from being run unauthorized.
{% endrow %}

Macros are easily extendable and you can write your own application-wide macros.


## State and Result

{% row %}
~~~7
  Each step in the operation can write to the `options` object that is passed from step to step, and in the end will be in the result of the operation call.

    class Song::Update < Trailblazer::Operation
      step :find_model!
      step :assign_current_user!

      def find_model!(options, params:, **)
        options["model"] = Song.find_by(id: params[:id])
      end

      def assign_current_user!(options, current_user:, **)
        options["model"].created_by = current_user
      end
    end

~~~5

  Maintaining one stateful object, only, allows using callable objects and lambdas as steps as well.

    class Song::Update < Trailblazer::Operation
      step MyCallable
      step ->(options, params:, **) { ... }

  After running, this object is the result.

    result = Song::Update.(id: 1, ..)

    result.success? #=> true
    result["model"] #=> #<Song ..>

{% endrow %}

## Testing

{% row %}
~~~6
  Since operations embrace the entire workflow for an application's function, you can write simple and fast unit-tests to assert the correct behavior.

    describe Song::Create do
      it "prohibits empty params" do
        result = Song::Create.({})

        expect(result).to be_failure
        expect(result["model"]).to be_new
      end
    end

  All edge-cases and bugs can be tested via unit tests. Slow, inefficient integration tests are reduced to a minimum.
~~~6
  Operations can also replace factories.

    describe Song::Create do
      let(:song) { Song::Create.(params) }

  This will make sure your application test state is always inline with what happens in production. You won't have an always diverging *factory vs. production state* ever again.

  Check out [our Rspec gem](https://github.com/trailblazer/rspec-trailblazer) for TRB matcher integration. Matchers for Minitest are coming, too!
{% endrow %}

## Learn More

A mix of documentation and guides will help you to understand the operation quickly and how to use it to clean up existing codebases or start a new app.

{% row %}
~~~4
  <i class="engage fa fa-map"></i>

  Read the [**→API DOCS**](api.html) to learn about the pipe and step implementations and what macros Trailblazer provides for you.
~~~4
  <i class="engage fa fa-book"></i>

  Make sure to spend some hours reading the [**→GETTING STARTED**](/guides/trailblazer/2.0/01-operation-basics.html) guide.

  You will be ready to work with Trailblazer 2.
~~~4
  <i class="engage fa fa-comments-o"></i>

  Jump on our public [**→SUPPORT CHAT**](https://gitter.im/trailblazer/chat).

  It doesn't matter whether you have specific questions or just want to chat about software architecture, whisky or TDD - we'll be there!
{% endrow %}

{% row %}
  ~~~12,text-center
  <a href="/guides/trailblazer/2.0/01-operation-basics" class="button">GET STARTED!</a>
{% endrow %}
