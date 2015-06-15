---
layout: default
---

# Trailblazer

Trailblazer gives you a high-level architecture for web applications.

Logic that used to get violently pressed into MVC is restructured and decoupled from the Rails framework. New abstraction layers like operations, form objects, authorization policies, data twins and view models guide you towards a better architecture.

![](images/Trb-Stack.png){: .left }

By applying encapsulation and good OOP, Trailblazer maximizes reusability of components, gives you a more intuitive structure for growing applications and adds conventions and best practices on top of Rails' primitive MVC stack.


Controllers and models end up as lean endpoints for HTTP dispatching and persistence. A polymorphic architecture sitting between controller and persistence is designed to handle many different contexts helps to minimize code to handle various user roles and edge cases.


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
    <div class="box">
    {% highlight ruby %}
class Comment < ActiveRecord::Base
  has_many   :users
  belongs_to :thing

  scope :recent -> { limit(10) }
end
    {% endhighlight %}
  </div>


  <div class="code-box">
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
      <p>Operations contain business logic per action. This is where your domain code sits: Validation, callbacks and application code sits here.</p>

      <p></p>
    </div>
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
    <div class="code-box">
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


  <div class="box">
    <h3>Forms</h3>

    <div class="description">
      <p>Every operation contains a form object.</p>
      <p>This is a plain Reform class and allows all features you know from the popular form gem.</p>
      <p>Forms can also be rendered.</p>
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
  <div class="code-box">
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

<h3>View Model</h3>
<h3>Representer</h3>
<h3>Polymorphism</h3>


## File Layout

## Gems

Trailblazer is an architectural style. However, what sounds nice in theory is backed by gems for you to implement that style.

The gems itself are completely self-contained, minimalistic and solve just one particular problem. Many of them have been in use in thousands of production sites for years.

[a grid is what we need here]

## [Cells](/gems/cells)

<div class="box">
  <div class="description">
    Cells provide view models to encapsulate parts of your views into classes. A view model is an object-oriented partial and doesn't know anything about the controller or the rendering view.
  </div>

  <div class="example">
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
</div>

<div class="box">
  <div class="description">
    Views can be Haml, ERB, or Slim. Method calls are the only way to retrieve data. Methods are directly called on the cell instance.
  </div>

  <div class="example">
    {% highlight haml %}
%h3 New Comment
  = body

By #{author_link}
    {% endhighlight %}
  </div>
</div>


## [Operation](gems/operation)

An operation is the central concept of Trailblazer. It contains all business logic for one use case in your application.

Operation acts as an orchestrating object that benefits from internal policies, form object, models and more.

Contract: central schema. infer representer (serialization and parsing docs). data structure. whitelist of what to process.

## [Reform](gems/reform)

## [Representable](gems/representable)

## Roar

## Twin

## The Book

<a href="https://leanpub.com/trailblazer">
![](images/3dbuch-freigestellt.png)
</a>

Yes, there's a book! It is about 60% finished and will get another 150 pages, making it 300 pages full of wisdom about Trailblazer and all the gems.

If you want to learn about this project and if you feel like supporting Open-Source, please [buy it](https://leanpub.com/trailblazer).

