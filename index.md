---
layout: default
---

### Hello!

## Gems

Trailblazer is an integrated collection of gems. The gems itself are completely self-contained, minimalistic and solve just one particular problem. Many of them have been in use in thousands of production sites for years.

[a grid is what we need here]

### [Cells](https://github.com/apotonick/cells)

<div class="box">
  <div class="description">
    Cells provide view models to encapuslate parts of your views into classes. A view model is an object-oriented partial and doesn't know anything about the controller or the rendering view.
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


## Operation

## Reform

## Representable

## Roar

## Twin

