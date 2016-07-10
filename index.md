---
layout: home
title: "A High-Level Architecture For The Web"
description: "Trailblazer introduces additional abstraction layers into Ruby frameworks. Operations, form objects, view models, policies, domain objects, representers and more cover every aspect of business in web apps. And developers finally know where to put their code."

---

<!-- Hero -->
<div class="hero">
  <div class="hero-unit">
    <div class="row">
      <div class="columns">
        <h1>
          <img src="images/logo.svg">
        </h1>
        <h2>A High-level Architecture For The Web</h2>
      </div>
    </div>
  </div>
</div>


<!-- About -->
<section class="about">
  <div class="row">
    <div class="columns">
      <h2>About Trailblazer</h2>

      <div class="row">
        <div class="columns medium-6">
          <p>Trailblazer gives you a high-level architecture for web applications.</p>
          <p>
            Logic that used to get violently pressed into MVC is restructured and decoupled from the Rails framework. New abstraction layers like operations, form objects, authorization policies, data twins and view models guide you towards a better architecture.
          </p>
          <p>
            By applying encapsulation and good OOP, Trailblazer maximizes reusability of components, gives you a more intuitive structure for growing applications and adds conventions and best practices on top of Rails' primitive MVC stack.
          </p>
          <p>
            A polymorphic architecture sitting between controller and persistence is designed to handle many different contexts and helps to minimize code to handle various user roles and edge cases.
          </p>

          <p>Check out who's using <a href="#users">Trailblazer in production →</a></p>

           <a href="/guides/trailblazer-in-20-minutes.html" class="button radius">Get Started:<br>
            Trailblazer in 12 Minutes</a>
        </div>
        <div class="columns medium-6">
          <img src="images/Trb-Stack.png">
        </div>
      </div>
    </div>
  </div>



<!--
<div class="row">
  <div class="columns">
    <p class="text-center">
      Check out who's using <a href="/users.html">Trailblazer in production →</a>
    </p>
  </div>
</div>
-->

<div id="code-slider" class="carousel">
<div class="section-separator">
  <div class="row">
    <div class="columns">
      <h2>Controller</h2>
    </div>
  </div>

  <div class="row">
    <div class="columns medium-6">
      <pre><code class="ruby">
  class CommentsController < ApplicationController
    def new
      form Comment::Update
    end

    def create
      run Comment::Update do |op|
        return redirect_to comments_path(op.model)
      end

      render :new
    end
      </code></pre>
    </div>
     <div class="columns medium-6">
      <p>Controllers in Trailblazer end up as lean HTTP endpoints: they instantly dispatch to an operation.</p>

      <p>No business logic is allowed in controllers, only HTTP-related tasks like redirects.</p>

      <p>More <a id="trb-more">about Trailblazer →</a></p>

      <script type="text/javascript">
        $("#trb-more").click( function(e) { e.preventDefault(); $("button.slick-next").click() } );
      </script>
    </div>
  </div>
</div>


<!-- Model -->

<div class="sub-section">
  <div class="row">
    <div class="columns">
      <h2>Model</h2>
    </div>
  </div>
  <div class="row">
    <div class="columns medium-6">
      <pre><code class="ruby">
  class Comment < ActiveRecord::Base
    has_many   :users
    belongs_to :thing

    scope :recent, -> { limit(10) }
  end
      </code></pre>

    </div>
    <div class="columns medium-6">
      <p>Models only contain associations, scopes and finders. Solely persistence logic is allowed.</p>
      <p>That's right: No callbacks, no validations, no business logic in models. </p>
    </div>
  </div>
</div>

<!-- Operation -->

<div class="section-separator">
  <div class="row">
    <div class="columns">
      <h2>Operation</h2>
    </div>
  </div>

  <div class="row">
    <div class="columns medium-6">
      <pre><code class="ruby">
  class Comment::Create < Trailblazer::Operation
    contract do
      property :body
      validates :body, length: {maximum: 160}
    end

    def process(params)
      if validate(params[:comment])
        # ..
    end
  end
      </code></pre>
    </div>
    <div class="columns medium-6">
      <p>Per public action, there's one operation orchestrating the business logic.</p>
      <p>This is where your domain code sits: Validation, callbacks, authorization and application code go here.</p>
      <p>Operations are the only place to write to persistence via models.</p>
      <a class="button radius" href="/gems/operation">Learn more</a>
    </div>
  </div>
</div>

<!-- Form -->

<div class="sub-section">
  <div class="row">
    <div class="columns">
      <h2>Form</h2>
    </div>
  </div>

  <div class="row">
    <div class="columns medium-6">
      <pre><code class="ruby">
  contract do
    property :body
    validates :body, length: {maximum: 160}

    property :author do
      property :email
      validates :email, email: true
    end
  end
      </code></pre>
    </div>
    <div class="columns medium-6">
      <p>Every operation contains a form object. </p>
        <p>This is the place for validations.</p>
      <p>Forms are plain Reform classes and allow all features you know from the popular form gem.</p>
      <p>Forms can also be rendered using form builders like Formtastic or Simpleform.</p>
    </div>
  </div>
</div>

<!-- Callback -->

<div class="section-separator">
  <div class="row">
    <div class="columns">
      <h2>Callback</h2>
    </div>
  </div>

  <div class="row">
    <div class="columns medium-6">
      <p>Callbacks are invoked from the operation, where you want them to be triggered.</p>
      <p>They can be configured in a separate Callback class.</p>
      <p>Callbacks are completely decoupled and have to be invoked manually, they won't run magically.</p>
    </div>
    <div class="columns medium-6">
     <pre><code class="ruby">
  callback do
    on_create :notify_owner!

    property :author do
      on_add :reset_authorship!
    end
  end
      </code></pre>
    </div>
  </div>
</div>

<!-- Policy -->

<div class="sub-section">
  <div class="row">
    <div class="columns">
      <h2>Policy</h2>
    </div>
  </div>
  <div class="row">
    <div class="columns medium-6">
      <pre><code class="ruby">
    policy do
      user.admin? or not post.published?
    end
      </code></pre>
    </div>
    <div class="columns medium-6">
      <p>Policies allow authorization on a global or fine-granular level.</p>
      <p>Again, this is a completely self-contained class without any coupling to the remaining tiers.</p>
    </div>
  </div>
</div>


<!-- View Model -->

<div class="section-separator">
  <div class="row">
    <div class="columns">
      <h2>View Model</h2>
    </div>
  </div>
  <div class="row">
    <div class="columns medium-6">
      <pre><code class="ruby">
  class Comment::Cell::Show < Trailblazer::Cell
    property :author

  private
    def author_link
      link_to "#{author.email}", author
    end
  end
      </code></pre>
  </div>
  <div class="columns medium-6">
      <p>Cells encapsulate parts of your UI in separate view model classes and introduce a widget architecture.</p>
      <p>Views are logic-less. There can be deciders and loops. Any method called in the view is directly called on the cell instance.</p>
      <p>Rails helpers can still be used but are limited to the cell's scope.</p>
    </div>
</div>
</div>

<!-- Representer -->

<div class="section-separator">
  <div class="row">
    <div class="columns">
      <h2>Representer</h2>
    </div>
  </div>
  <div class="row">
    <div class="columns medium-6">
      <p>Document APIs like JSON or XML are implemented with Representers which parse and render documents.</p>
      <p>Representers are plain Roar classes. They can be automatically infered from the contract schema.</p>
      <p>You can use media formats, hypermedia and all other Roar features.</p>
    </div>
    <div class="columns medium-6">
    <pre><code class="ruby">
  representer do
    include Roar::JSON::HAL

    property :body
    property :user, embedded: true

    link(:self) { comment_path(model) }
  end
    </code></pre>

    </div>
  </div>
</div>

<!-- Inheritance -->

<div class="sub-section">
  <div class="row">
    <div class="columns">
      <h2>Inheritance</h2>
    </div>
  </div>


  <div class="row">
    <div class="columns medium-6">
    <pre><code class="ruby">
  class Comment::Update < Create
    policy do
      is_owner?(model)
    end
  end
    </code></pre>

    </div>
    <div class="columns medium-6">
      <p>Trailblazer reintroduces object-orientation.</p>
      <p>For each public action, there's one operation class.</p>
      <p>Operations inherit contract, policies, representers, etc. and can be fine-tuned for their use case.</p>
    </div>
  </div>
</div>

<!-- Polymorphism -->

<div class="section-separator">
  <div class="row">
    <div class="columns">
      <h2>Polymorphism</h2>
    </div>
  </div>

  <div class="row">
    <div class="columns medium-6">
      <p>Operations, forms, policies, callbacks are all designed for a polymorphic environment.</p>
      <p>Different roles, contexts or rules are handled with subclasses instead of messy <code>if</code>s.</p>
    </div>
    <div class="columns medium-6">
      <pre><code class="ruby">
  class Comment::Create < Trailblazer::Operation
    build do |params|
      Admin if params[:current_user].admin?
    end

    class Admin < Create
      contract do
        remove_validations! :body
      end
    end
      </code></pre>

    </div>
  </div>
</div>

<div class="sub-section">
  <div class="row">
    <div class="columns">
      <h2>File Layout</h2>
    </div>

  </div>

  <div class="row">
    <div class="columns medium-6">
      <pre><code>
    app
    ├── concepts
    │   ├── comment
    │   │   ├── cell
    │   │   │   └── show.rb
    │   │   ├── operation
    │   │   │   ├── create.rb
    │   │   │   └── update.rb
    │   │   ├── view
    │   │   │   ├── show.haml
    │   │   │   └── list.haml
        </code>

      </pre>
    </div>
    <div class="columns medium-6">
      <p>
        In Trailblazer, files are no longer organized by technology. Classes, views, assets, policies, and more, are all grouped by <em>concept</em> and sit in one directory.
      </p>
      <p>
        A concept may embrace a simple CRUD concern, or an invoice PDF generator, and can be virtually anything.
      </p>
      <p>
        Concepts in turn can be nested again, and provide you a  more intuitive and easier to navigate file structure.
      </p>
    </div>

  </div>
</div>
</div>

</section>







<!-- Book -->
<section class="sub-section book">
  <div class="row">
    <div class="columns">
      <a name="book" />
      <h2>The Book</h2>
      <div class="row the-book">
        <div class="columns medium-3">
          <a href="https://leanpub.com/trailblazer">
          <img src="/images/3dbuch-freigestellt.png" />
          </a>
        </div>

        <div class="columns medium-9">
        <h3>Yes, there's a book!</h3>
          <p>Written by the creator of Trailblazer, this book gives you <b>300 pages full of wisdom about Trailblazer</b> and its gems, such as Reform, Cells and Roar.</p>

          <p>The book comes with a <a href="https://github.com/apotonick/gemgem-trbrb">sample app repository</a> to conveniently browse through changes per chapter.</p>

          <p>In the book, <b>we build a realistic Rails application with Trailblazer</b> that discusses convoluted requirements such as dynamic forms, polymorphic rendering and processing for signed-in users, file uploads, pagination, a JSON document API sitting on top of that, and many more problems you run into when building web applications.</p>

          <p>Check out the <a href="/books/trailblazer.html">full book description</a> for a few more details about the content.</p>

          <p>If you want to learn about this project and if you feel like supporting Open-Source, please <a href="https://leanpub.com/trailblazer">buy and read it</a> and let us know what you think.</p>
          <a href="https://leanpub.com/trailblazer" class="button radius">Buy Book</a>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- Testimonials -->
<section class="sub-section testimonials">
  <div class="row">
    <div class="columns">
      <a name="testimonials"></a>

      <h2>
        Testimonials
      </h2>


      <div class="carousel">

        <div>
          <div class="row testimonial">
            <div class="columns medium-2">
              <img src="../images/igor.jpg" class="avatar">
            </div>
            <div class="columns medium-10">
              <blockquote>
                "At some point of time we started to decouple our form objects from models. Things got a lot easier when we found out there is a ready to use solution which solves our exact problem. That was Reform. Soon after, we started using all other parts of Trailblazer and haven't regretted a second of our time we spent using it."
                <cite><strong>Igor Pstyga</strong>, PeerStreet</cite>
              </blockquote>
            </div>
          </div>

          <div class="row testimonial">
            <div class="columns medium-2">
              <img src="../images/paulo.jpg" class="avatar">
            </div>
            <div class="columns medium-10">
              <blockquote>
                "Here at Chefsclub, we are very happy with Trailblazer. Our application already has 32 concepts, 130+ operations, and Cells surprised us as an awesome feature. We feel pretty safe with it."
                <cite><strong>Paulo Fabiano Langer</strong>, Chefsclub</cite>
              </blockquote>
            </div>
          </div>
        </div>

        <div>
          <div class="row testimonial">
            <div class="columns medium-2">
              <img src="../images/yuri.jpg" class="avatar">
            </div>
            <div class="columns medium-10">
              <blockquote>
                "Trailblazer helps organize my code, the book showed me how. You can assume what each component does by its name, it's very easy and intuitive, it should be shipped as an essential part of Rails."
                <cite><strong>Yuri Freire Lima</strong>, AzClick</cite>
              </blockquote>
            </div>
          </div>

          <div class="row testimonial">
            <div class="columns medium-2">
              <img src="../images/eric.jpg" class="avatar">
            </div>
            <div class="columns medium-10">
              <blockquote>
                Trailblazer has brought the fun back to Rails for me. It helps me organize large codebases into small, smart, testable chunks. Nick has brought together his years of insight in managing Rails projects and made them available for everyone. Any Rails engineer looking to expand past the default Rails Way should take a look at Trailblazer.
                <cite><strong>Eric Skogen</strong>, Software Inventor</cite>
              </blockquote>
            </div>
          </div>
        </div>

        <div>
          <div class="row testimonial">
            <div class="columns medium-2">
              <img src="../images/nick.jpg" class="avatar">
            </div>
            <div class="columns medium-10">
              <blockquote>
                I haven't been this excited about Rails since 2007! Trailblazer - makes Rails development fun again. Especially on large projects. It's one of the better implementations of the ServiceObject / ViewModel / Form Object / Policy layers I've seen, which sooner or later ( rather sooner) you'll need.
                <cite><strong>Nick Gorbikoff</strong>, Rinica Company</cite>
              </blockquote>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</section>

<section id="trb-users">
<div class="row">
    <div class="columns">
      <a name="users"></a>

      <h2>
        Companies using Trailblazer
      </h2>

      <div class="row">
        <div class="column medium-2 text-center">
          <a href="http://mitimes.com">
            <img src="/images/users/mitimes.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="http://wickedweasel.com/">
            <img src="/images/users/ww.png" />
          </a>
        </div>

        <div class="column medium-2 text-center">
          <a href="http://www.mytappr.com/">
            <img src="/images/users/tappr.png" />
          </a>
        </div>

        <div class="column medium-2 text-center">
          <a href="http://zertico.com/">
            <img src="/images/users/zertico.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="http://serviceseeking.com.au/">
            <img src="/images/users/serviceseeking.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="http://weareathlon.com/">
            <img src="/images/users/athlon.png" />
          </a>
        </div>
      </div>

      <div class="row">
        <div class="column medium-2 text-center logo-leveler">
          <a href="http://localsearch.com.au/">
            <img src="/images/users/localSearch.png" />
          </a>
        </div>

        <div class="column medium-2 text-center">
          <a href="http://microminimus.com">
            <img src="/images/users/microminimus.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="http://shaken.com/">
            <img src="/images/users/shaken.png" />
          </a>
        </div>

        <div class="column medium-2 text-center">
          <a href="http://yebo.com.br/">
            <img src="/images/users/yebo.png" />
          </a>
        </div>


        <div class="column medium-2 text-center">
          <a href="http://ajrintl.com/">
            <img src="/images/users/ajr.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="http://rinica.com/">
            <img src="/images/users/rinica.png" />
          </a>
        </div>
      </div>

      <div class="row">
        <div class="column medium-2 text-center logo-leveler">
          <a href="https://www.skovingulv.no">
            <img src="/images/users/skovin.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="http://angelcompass.org/">
            <img src="/images/users/angelcompass.png" />
          </a>
        </div>

        <div class="column medium-2 text-center">
          <a href="https://www.gratwifi.eu">
            <img src="/images/users/gratwifi_logo_facebook.png" />
          </a>
        </div>
      </div>



      <div class="row">
        <div class="columns">
          <p class="text-center">
            Your logo here? <a href="https://gitter.im/trailblazer/chat">Send it to us →</a>
          </p>
        </div>
      </div>
    </div>
  </div>
</section>

