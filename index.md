---
layout: home
---

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

<div class="sub-section section-separator">
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
      if validate(params)

      else

      end
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

<div class="sub-section section-separator">
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
      </code>
      </pre>
    </div>
    <div class="columns medium-6">
      <p>Policies allow authentication on a global or fine-granular level.</p>
      <p>Again, this is a completely self-contained class without any coupling to the remaining tiers.</p>
    </div>
  </div>
</div>


<!-- View Model -->

<div class="sub-section section-separator">
  <div class="row">
    <div class="columns">
      <h2>View Model</h2>
    </div>
  </div>
  <div class="row">
    <div class="columns medium-6">
      <p>Cells encapsulate parts of your UI in separate view model classes and introduce a widget architecture.</p>
      <p>Views are logic-less. There can be deciders and loops. Any method called in the view is directly called on the cell instance.</p>
      <p>Rails helpers can still be used but are limited to the cell's scope.</p>
    </div>
    <div class="columns medium-6">
      <div class="code-box">
          {% highlight ruby %}
      class Comment::Cell < Cell::ViewModel
        property :body
        property :author

        def show
          render
        end

      private
        def author_link
          link_to "#{author.email}", author
        end
      end
      {% endhighlight %}
      </div>
        <div class="code-box">
    {% highlight erb %}
    <div class="comment">
      <%= body %>
      By <%= author_link %>
    </div>
    {% endhighlight %}
  </div>
</div>
</div>
</div>


<!-- View Model -->

<div class="sub-section">
  <div class="row">
    <div class="columns">
      <h2>Views</h2>
    </div>
  </div>
  <div class="row">
    <div class="columns medium-6">
      {% highlight erb %}
      <h1>Comments for <%= @thing.name %></h1>

      This was created <%= @thing.created_at %>

        <%= concept("comment/cell",
        collection: @thing.comments) %>
          {% endhighlight %}
    </div>
    <div class="columns medium-6">
      <p>Controller views are still ok to use.</p>
      <p>However, replacing huge chunks with cells is encouraged and will simplify your views.</p>
    </div>
  </div>
</div>

<!-- Representer -->

<div class="sub-section section-separator">
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
      {% highlight ruby %}
      representer do
        include Roar::JSON::HAL

        property :body
        property :user, embedded: true

        link(:self) { comment_path(model) }
      end
      {% endhighlight %}
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
      {% highlight ruby %}
        class Comment::Update < Create
        policy do
          is_owner?(model)
        end
        end
      {% endhighlight %}
    </div>
    <div class="columns medium-6">
      <p>Trailblazer reintroduces object-orientation.</p>
      <p>For each public action, there's one operation class.</p>
      <p>Operations inherit contract, policies, representers, etc. and can be fine-tuned for their use case.</p>
    </div>
  </div>
</div>

<!-- Polymorphism -->

<div class="sub-section section-separator">
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
      {% highlight ruby %}
        class Comment::Create < Trailblazer::Operation
          build do |params|
            Admin if params[:current_user].admin?
          end

          class Admin < Create
            contract do
              remove_validations! :body
            end
          end
        {% endhighlight %}
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
    │   │   ├── crud.rb
    │   │   ├── cell.rb
    │   │   ├── views
    │   │   │   ├── show.haml
    │   │   │   ├── list.haml
    │   │   │   ├── comment.css.sass
    │   │   └── twin.rb
    │   │
    │   └── post
    │       └── crud.rb
        </code>
      
      </pre>
    </div>
    <div class="columns medium-6">
      <p>
        In Trailblazer, files that belong to one group are called _concepts_. They sit in one directory as Trailblazer introduces and new, more intuitive and easier to navigate file structure.
      </p>
    </div>

  </div>
</div>

