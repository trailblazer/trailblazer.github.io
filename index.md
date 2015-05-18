---
layout: default
---

# Trailblazer

[Stack]

Trailblazer gives you a high-level architecture for web applications. Logic that used to get violently pressed into MVC is restructured and decoupled from the Rails framework. New abstraction layers like operations, form objects, authorization policies, data twins and view models guide you towards a better architecture.

By applying encapsulation and good OOP, Trailblazer maximizes reusability of components, gives you a more intuitive structure for growing applications and adds conventions and best practices on top of Rails' primitive MVC stack.

![](images/Trb-Stack.png)

Controllers and models end up as lean endpoints for HTTP dispatching and persistence. A polymorphic architecture sitting between controller and persistence is designed to handle many different contexts helps to minimize code to handle various user roles and edge cases.

## Gems

Trailblazer is an integrated collection of gems. The gems itself are completely self-contained, minimalistic and solve just one particular problem. Many of them have been in use in thousands of production sites for years.

[a grid is what we need here]

### [Cells](https://github.com/apotonick/cells)

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

## [Reform](gems/reform)

## [Representable](gems/representable)

## Roar

## Twin

## The Book

<a href="https://leanpub.com/trailblazer">
![](images/book.jpg)
</a>

Yes, there's a book! It is about 60% finished and will get another 150 pages, making it 300 pages full of wisdom about Trailblazer and all the gems.

If you want to learn about this project and if you feel like supporting Open-Source, please [buy it](https://leanpub.com/trailblazer).

