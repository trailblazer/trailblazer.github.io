---
layout: default
---

# Trailblazer

Trailblazer gives you a high-level architecture for web applications.

Logic that used to get violently pressed into MVC is restructured and decoupled from the Rails framework. New abstraction layers like operations, form objects, authorization policies, data twins and view models guide you towards a better architecture.

![](images/Trb-Stack.png){: .left }

By applying encapsulation and good OOP, Trailblazer maximizes reusability of components, gives you a more intuitive structure for growing applications and adds conventions and best practices on top of Rails' primitive MVC stack.


A polymorphic architecture sitting between controller and persistence is designed to handle many different contexts and helps to minimize code to handle various user roles and edge cases.


<div class="row">
  <h3>Controller</h3>

  <div class="box">
    <div class="description">
      <p>Controllers in Trailblazer end up as lean HTTP endpoints: they instantly dispatch to an operation.</p>

      <p>No business logic is allowed in controllers, only HTTP-related tasks like redirects.</p>
    </div>
  </div>

  <div class="code-box">
    {% highlight ruby %}
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
    {% endhighlight %}
  </div>
</div>



<div class="row">
    <div class="left-code">
    {% highlight ruby %}
class Comment < ActiveRecord::Base
  has_many   :users
  belongs_to :thing

  scope :recent, -> { limit(10) }
end
    {% endhighlight %}
  </div>


  <div class="right-text">
    <h3>Model</h3>

    <div class="description">
      <p>Models only contain associations, scopes and finders. Solely persistence logic is allowed.</p>

      <p>That's right: No callbacks, no validations, no business logic in models. </p>
    </div>
  </div>
</div>


<div class="row">
  <h3>Operation</h3>

  <div class="box">
    <div class="description">
      <p>Per public action, there's one operation orchestrating the business logic.</p>
      <p>This is where your domain code sits: Validation, callbacks, authorization and application code go here.</p>
      <p>Operations are the only place to write to persistence via models.</p>
    </div>

    <a href="/gems/operation">Learn more</a>
  </div>

  <div class="code-box">
    {% highlight ruby %}
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
    {% endhighlight %}
  </div>
</div>



<div class="row">
  <div class="left-code-50">
    {% highlight ruby %}
contract do
  property :body
  validates :body, length: {maximum: 160}

  property :author do
    property :email
    validates :email, email: true
  end
end
    {% endhighlight %}
  </div>


  <div class="right-text">
    <h3>Form</h3>

    <div class="description">
      <p>Every operation contains a form object. </p>
        <p>This is the place for validations.</p>
      <p>Forms are plain Reform classes and allow all features you know from the popular form gem.</p>
      <p>Forms can also be rendered using form builders like Formtastic or Simpleform.</p>
    </div>
  </div>
</div>




<div class="row">
  <h3>Callback</h3>

  <div class="box">
    <div class="description">
      <p>Callbacks are invoked from the operation, where you want them to be triggered.</p>
      <p>They can be configured in a separate Callback class.</p>
      <p>Callbacks are completely decoupled and have to be invoked manually, they won't run magically.</p>
    </div>
  </div>

  <div class="code-box">
    {% highlight ruby %}
callback do
  on_create :notify_owner!

  property :author do
    on_add :reset_authorship!
  end
end
    {% endhighlight %}
  </div>
</div>


<div class="row">
  <div class="left-code">
    {% highlight ruby %}
policy do
  user.admin? or not post.published?
end
    {% endhighlight %}
  </div>


  <div class="box">
    <h3>Policy</h3>

    <div class="description">
      <p>Policies allow authentication on a global or fine-granular level.</p>
      <p>Again, this is a completely self-contained class without any coupling to the remaining tiers.</p>
    </div>
  </div>
</div>




<div class="row">
  <h3>View Model</h3>

  <div class="box">
    <div class="description">
      <p>Cells encapsulate parts of your UI in separate view model classes and introduce a widget architecture.</p>
      <p>Views are logic-less. There can be deciders and loops. Any method called in the view is directly called on the cell instance.</p>
      <p>Rails helpers can still be used but are limited to the cell's scope.</p>
    </div>
  </div>


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




<div class="row">
  <div class="left-code-50">
    {% highlight erb %}
<h1>Comments for <%= @thing.name %></h1>

This was created <%= @thing.created_at %>

<%= concept("comment/cell",
  collection: @thing.comments) %>
    {% endhighlight %}
  </div>


  <div class="box">
    <h3>Views</h3>

    <div class="description">
      <p>Controller views are still ok to use.</p>
      <p>However, replacing huge chunks with cells is encouraged and will simplify your views.</p>
    </div>
  </div>
</div>



<div class="row">
  <h3>Representer</h3>

  <div class="box">
    <div class="description">
      <p>Document APIs like JSON or XML are implemented with Representers which parse and render documents.</p>
      <p>Representers are plain Roar classes. They can be automatically infered from the contract schema.</p>
      <p>You can use media formats, hypermedia and all other Roar features.</p>
    </div>
  </div>


  <div class="code-box">
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




<div class="row">
  <div class="left-code">
    {% highlight ruby %}
class Comment::Update < Create
  policy do
    is_owner?(model)
  end
end
    {% endhighlight %}
  </div>

  <h3>Inheritance</h3>

  <div class="right-text">
    <div class="description">
      <p>Trailblazer reintroduces object-orientation.</p>

      <p>For each public action, there's one operation class.</p>

      <p>Operations inherit contract, policies, representers, etc. and can be fine-tuned for their use case.</p>
    </div>
  </div>
</div>



<div class="row">
  <h3>Polymorphism</h3>

  <div class="box">
    <div class="description">
      <p>Operations, forms, policies, callbacks are all designed for a polymorphic environment.</p>
      <p>Different roles, contexts or rules are handled with subclasses instead of messy <code>if</code>s.</p>
    </div>
  </div>


  <div class="code-box">
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


## File Layout

In Trailblazer, files that belong to one group are called _concepts_. They sit in one directory as Trailblazer introduces and new, more intuitive and easier to navigate file structure.

<pre>
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
</pre>


## Gems

Trailblazer is an architectural style. However, what sounds nice in theory is backed by gems for you to implement that style.

The gems itself are completely self-contained, minimalistic and solve just one particular problem. Many of them have been in use in thousands of production sites for years.

All gems are documented here.

* [Cells](/gems/cells)
* [Operation](gems/operation)
* [Reform](gems/reform)
* [Representable](gems/representable)
* Roar
* [Disposable](gems/disposable)


## The Book

<div class="row">
  <div class="box">
    <a href="https://leanpub.com/trailblazer">
    <img src="images/3dbuch-freigestellt.png" />
    </a>
  </div>

  <div class="right-text">
    <p>Yes, there's a book!</p>
    <p>Written by the busy creator of Trailblazer, it is about 70% finished and will get another 150 pages, making it 300 pages full of wisdom about Trailblazer and all the gems.</p>

    <p>If you want to learn about this project and if you feel like supporting Open-Source, please <a href="https://leanpub.com/trailblazer">buy and read it</a> and let us know what you think.</p>
  </div>
</div>


<!-- ## Testimonials

* _"At some point of time we started to decouple our form objects from models. Things got a lot easier when we found out there is a ready to use solution which solves our exact problem. That was Reform. Soon after, we started using all other parts of Trailblazer and haven't regretted a second of our time we spent using it."_ -- **Igor Pstyga, Shop Hers Inc.**

* _"Here at Chefsclub, we are very happy with Trailblazer. Our application already has 32 concepts, 130+ operations, and Cells surprised us as an awesome feature. We feel pretty safe with it."_ -- **Paulo Fabiano Langer, Chefsclub**

* _"Trailblazer helps organize my code, the book showed me how. You can assume what each component does by its name, it's very easy and intuitive, it should be shipped as an essential part of Rails."_ -- **Yuri Freire Lima, AzClick**
 -->
