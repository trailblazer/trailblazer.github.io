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
        <h2>A High-Level Architecture For The Web</h2>
      </div>
    </div>
  </div>
</div>

{% row %}
  ~~~9,medium-centered
  <h2 class="text-center">Finally know where to put your code!</h2>

  Trailblazer gives you a high-level architecture for web applications. It extends the basic MVC pattern with new abstractions. Rock-solid conventions that go far beyond database table naming or route paths let you focus on your application code, minimize bugs and improve the maintainability.
{% endrow %}

{% row %}
   ~~~3,medium-offset-3
  <img src="/images/diagrams/files-2017.png">
  ~~~3,end
  <img src="/images/diagrams/operation-2017-grey.png">
{% endrow %}


{% row %}
  ~~~3,medium-offset-3
  Trailblazer's file structure organizes by **CONCEPT**, and then by technology.

  * **THOUSANDS** of users find this more intuitive and easier to navigate.
  * It embraces the **COMPONENT STRUCTURE** of your code.
  * Huge teams working on complex projects have it easier not to get into each others' way.
  * Once a concept's **CODE IS TESTED** it won't break anywhere else.
  * The modular structure **SIMPLIFIES REFACTORING** in hundreds of legacy production apps.
  ~~~3,end
  The new abstractions in Trailblazer are optional. Only use what you need.

  * **CONTRACT** Form objects to validate incoming data.
  * **POLICY** to authorize code execution per user.
  * **OPERATION** A service object implementation with functional flow control.
  * **VIEW MODEL** Components for your view code.
  * **REPRESENTER** for serializing and parsing API documents.
  * **DESERIALIZER** Transformers to parse incoming data into structures you can work with.
{% endrow %}


{% row %}
  ~~~9,medium-centered text-center
  <h2>Legacy app, refactoring or green-field?</h2>

  Trailblazer helps improving your software in all kinds of systems and applications.
{% endrow %}


{% row quarters %}
~~~4
<h4>
  <i class="fa fa-gamepad"></i>
  Framework-agnostic
</h4>

The Trailblazer gems work with any Ruby framework. We provide glue code for Rails and Hanami, but there are TRB-powered apps in Roda, Grape, Sinatra and many more out there.

~~~4
<h4>
  <i class="fa fa-university"></i>
  Legacy-ready
</h4>

You can start using Trailblazer in existing, massive applications today. Refactorings can be applied step-wise, legacy code can be minimized as you go. Remember: Rome wasn't build in one day, either.

~~~4
<h4>
  <i class="fa fa-leaf"></i>
  Future-compatible
</h4>

Our promise to the community: Trailblazer 2 will be supported until end of 2020 or longer. Our API design makes it easy to provide automatic upgrading and backward-compatibility so you won't have to change code when we ship updates.

{% endrow %}


  {% row quarters %}
~~~4
<h4>
  <i class="fa fa-recycle"></i>
  Build to Refactor
</h4>

Our patterns are developed to be used in highly complex, existing, messy legacy applications. Trailblazer is designed to refactor old code - you do not have to rewrite the entire system to get a better architecture.
~~~4
<h4>
  <i class="fa fa-dashboard"></i>
  Test first
</h4>

By restructuring business code, application behavior can be tested more efficiently with more unit and less integration tests. Trailblazer engineers do enjoy the simplicity of testing and the speedup of the test suites.
~~~4
<h4>
  <i class="fa fa-ship"></i>
  It's real!
</h4>

Trailblazer is in use in thousands of production applications. Our patterns have evolved over a decade of engineering, our gems are mature and battle-tested. And: we will never stop innovating.

  {% endrow %}


{% row mascots %}
  ~~~4,medium-offset-2
  <div class="mascot">
    <img src="/images/sticker/sticker2017.png">
    <h3>We walk the walk.</h3>
  </div>


  Trailblazer defines patterns for a better architecture, and gives you implementations to use those patterns in your applications. Your software will be better structured, more consistent and with stronger, faster, and way simpler tests.

  Our high-level architecture and enterprise-ready™ gems will prevent you from reinventing the wheel again and again - you and your team are free to think about the next awesome feature.

  ~~~4,end
  <div class="mascot">
    <img src="/images/sticker/consulting.jpg">
    <h3>We love legacy apps.</h3>
  </div>

  By standardizing the business logic, new developers can be onboarded faster with help of our free documentation. Trailblazer's patterns cover 75% of daily business code's structure - you will feel the power of strong conventions within the first hours.

  If that's not enough, we provide on-site training, premium support and consulting. Dozens of companies worldwide trust us already.
{% endrow %}

{% row %}
  ~~~9,medium-centered text-center
  <a href="/gems/operation/2.0/index.html" class="button">LEARN MORE ABOUT TRAILBLAZER!</a>
{% endrow %}


{% row %}
  ~~~9,medium-centered text-center
  <h2>Want some code?</h2>
{% endrow %}

{% row %}
~~~1
&nbsp;
~~~5
    class SongsController < ApplicationController
      def create
        run Comment::Update do |result|
          redirect_to songs_path(result["model"])
        end
      end
    end
~~~5
**CONTROLLER** They end up as lean HTTP endpoints. No business logic is to be found in the controller, they instantly delegate to their respective operation.

Oh, and did we say there won't be controller tests anymore? That's right. Only unit and integration tests.
~~~1
{% endrow %}

{% row grey %}
~~~4,medium-offset-1
**MODEL** Models contain associations, scopes and finders. Only persistence logic, no callbacks, no validations, no business logic here.

    class Song < ActiveRecord::Base
      has_many   :albums
      belongs_to :composer
    end

Any number of **POLICY**s can be used in an operation to grant or deny access to functionality.

    class Application::Policy < Pundit::Policy
      def create?
        user.can_create?(model)
      end
    end

Also, use your choice of authorization framework.

~~~6,end
The **OPERATION** is the heart of the Trailblazer architecture. It orchestrates validations, policies, models, callback and business logic by leveraging a functional pipeline with built-in error handling.

    class Song::Create < Trailblazer::Operation
      step Model( Song, :new )
      step Policy::Pundit( Application::Policy, :create? )
      step Contract::Build( constant: Song::Contract::Create )
      step Contract::Validate()
      step Contract::Persist()
      fail Notifier::DBError
      step :update_song_count!

      def update_song_count!(options, current_user:, **)
        current_user.increment_song_counter
      end
    end

Designed to be a stateless object, the operation passes around one mutable options hash and makes heavy use of Ruby keyword arguments - if you want it.
{% endrow %}

{% row %}
~~~5,medium-offset-1
    class Song::Contract::Create < Reform::Form
      property :title
      property :length

      validates :title, presence: true
    end
~~~5,end
Validations are implemented with **CONTRACT**.

Trailblazer supports Reform and `Dry::Schema` validations in any number.
{% endrow %}

{% row %}
  ~~~4,medium-offset-1
  Any dependency, such as the current user, must be [injected from the outside](/gems/operation/api.html#dependency-injection).

  The concept of global state does not exist in Trailblazer, which leads to simplified, mock-free testability and concurrent-ready code.

  ~~~6,end
  **And the best:** there's only one way to run an operation.

    Song::Create.(
      { title: "Roxanne", length: 300 }, # params
      "current_user": current_user       # dependencies
    )
{% endrow %}

{% row %}
  ~~~5,medium-offset-1
    describe Song::Create do
      it "prohibits empty params" do
        result = Song::Create.({})

        expect(result).to be_failure
        expect(result["model"]).to be_new
      end
    end
  ~~~4,end
  Clumsy, slow controller tests are history. Now that all your business logic is controlled by the operation, **SIMPLE UNIT TESTS** can test any edge-case scenario or avoid regressions.

  Trailblazer's encapsulation makes a programmer's life better.
{% endrow %}

{% row %}
  ~~~9,medium-centered text-center
  <a href="/gems/operation/2.0/index.html" class="button">LEARN MORE ABOUT TRAILBLAZER!</a>
{% endrow %}

<!-- Testimonials -->
<section class="sub-section testimonials">
  {% row %}
    ~~~9,medium-centered text-center
  <h2>Testimonials</h2>
  {% endrow %}

  <div class="row">
    <div class="columns">
      <a name="testimonials"></a>

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
  {% row %}
    ~~~9,medium-centered text-center
  <h2>Users</h2>
  {% endrow %}

<div class="row">
    <div class="columns">
      <a name="users"></a>

      <div class="row">
        <div class="column medium-2 text-center">
          <a href="http://mitimes.com" target="_blank">
            <img src="/images/users/mitimes.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="http://wickedweasel.com/" target="_blank">
            <img src="/images/users/ww.png" />
          </a>
        </div>

        <div class="column medium-2 text-center">
          <a href="http://www.mytappr.com/" target="_blank">
            <img src="/images/users/tappr.png" />
          </a>
        </div>

        <div class="column medium-2 text-center">
          <a href="http://zertico.com/" target="_blank">
            <img src="/images/users/zertico.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="http://serviceseeking.com.au/" target="_blank">
            <img src="/images/users/serviceseeking.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="http://weareathlon.com/" target="_blank">
            <img src="/images/users/athlon.png" />
          </a>
        </div>
      </div>

      <div class="row">
        <div class="column medium-2 text-center logo-leveler">
          <a href="http://localsearch.com.au/" target="_blank">
            <img src="/images/users/localSearch.png" />
          </a>
        </div>

        <div class="column medium-2 text-center">
          <a href="http://microminimus.com" target="_blank">
            <img src="/images/users/microminimus.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="http://shaken.com/" target="_blank">
            <img src="/images/users/shaken.png" />
          </a>
        </div>

        <div class="column medium-2 text-center">
          <a href="http://yebo.com.br/" target="_blank">
            <img src="/images/users/yebo.png" />
          </a>
        </div>


        <div class="column medium-2 text-center">
          <a href="http://ajrintl.com/" target="_blank">
            <img src="/images/users/ajr.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="http://rinica.com/" target="_blank">
            <img src="/images/users/rinica.png" />
          </a>
        </div>
      </div>

      <div class="row">
        <div class="column medium-2 text-center logo-leveler">
          <a href="https://www.skovingulv.no" target="_blank">
            <img src="/images/users/skovin.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="http://angelcompass.org/" target="_blank">
            <img src="/images/users/angelcompass.png" />
          </a>
        </div>

        <div class="column medium-2 text-center">
          <a href="https://www.gratwifi.eu" target="_blank">
            <img src="/images/users/gratwifi_logo_facebook.png" />
          </a>
        </div>

        <div class="column medium-2 text-center">
          <a href="https://mobidev.biz" target="_blank">
            <img src="/images/users/mobidev.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="https://www.pollpush.com/" target="_blank">
            <img src="/images/users/pollpush.png" />
          </a>
        </div>

        <div class="column medium-2 text-center logo-leveler">
          <a href="https://www.clickfunnels.com/" target="_blank">
            <img src="/images/users/cf-logo-dark-blue.png" />
          </a>
        </div>
      </div>

      <div class="row">
        <a href="http://companymood.com" target="_blank">
          <img src="/images/users/CompanyMood-Logo-02.png" />
        </a>
      </div>

    </div>
  </div>


</section>

  {% row %}
    ~~~9,medium-centered text-center
  Your logo here? <a href="https://gitter.im/trailblazer/chat">Send it to us →</a>
  {% endrow %}
