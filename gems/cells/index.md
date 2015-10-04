---
layout: default
permalink: /gems/cells/
---
[API](api.html) - [Testing](testing.html) - [Rendering](render.html) - [Engine Cells](engine.html) - [Rails](rails.html) - [Helpers](helpers.html) - [Templates](templates.html) - [Troubleshooting](troubleshooting.html)

# Cells

Out of the frustration with Rails' view layer, its lack of encapsulation and the convoluted code resulting from partials and helpers both accessing global state, the [Cells](https://github.com/apotonick/cells) gem emerged.

The cells gem is completely stand-alone and can be used without Trailblazer.

A cell is an object that represent a fragment of your UI. The scope of that fragment is up to you: it can embrace an entire page, a single comment container in a thread or just an avatar image link.

Cells are faster than ActionView. While exposing a better performance, you step-wise encapsulate fragments into cell widgets and enforce interfaces.

## View Model

Think of cells, or _view models_, as small Rails controllers, but without any HTTP coupling. Cells embrace all presentation and rendering logic to present a fragment of the UI.

## Rendering a Cell

Cells can be rendered anywhere in your application. Mostly, you want to use them in controller views or actions to replace a complex helper/partial mess.

{% highlight haml %}
- # app/views/comments/index.html.haml
%h1 Comments
@comments.each do |comment|
  = concept("comment/cell", comment) #=> Comment::Cell.new(comment).show
{% endhighlight %}

This will instantiate and invoke the `Comment::Cell` for each comment. It is completely up to the cell how to return the necessary markup.

## Cell Class

Following the Trailblazer convention, the `Comment::Cell` sits in `app/concepts/comment/cell.rb`.

{% highlight ruby %}
class Comment::Cell < Cell::ViewModel
  def show
    "This: #{model.inspect}"
  end
end
{% endhighlight %}

Per default, the `#show` method of a cell is called when it is invoked from a view. This method is responsible to compile the HTML (or whatever else you want to present) that is returned and displayed.

Whatever you pass into the cell via the `concept` helper will be available as the cell's `#model`.
Whatever you return from the `show` method will be displayed in the page invoking the cell.

{% highlight haml %}
= concept("comment/cell", comment) #=> "This: <Comment body=\"MVC!\">"
{% endhighlight %}

Note that you can pass anything into a cell. This can be an ActiveRecord model, a PORO or an array of attachments. The cell provides access to it via `model` and it's your job do use it correctly.

## Cell Views

While we already have a cleaner interface as compared to helpers accessing to global state, the real power of Cells comes when rendering views. This, again, is similar to controllers.

{% highlight ruby %}
class Comment::Cell < Cell::ViewModel
  def show
    render # renders app/concepts/comment/views/show.haml
  end
end
{% endhighlight %}

Using `#render` without any arguments will parse and interpolate the `app/concepts/comment/views/show.haml` template. Note that you're free to use [ERB](https://github.com/trailblazer/cells-erb), [Haml](https://github.com/trailblazer/cells-haml), or [Slim](https://github.com/trailblazer/cells-slim).

{% highlight haml %}
- # app/concepts/comment/views/show.haml
%li
  = model.body
  By
  = link_to model.author.email, author_path(model.author)
{% endhighlight %}

That's right, you can use Rails helpers in cell views.

## No Helpers

While you could reference `model` throughout your view and strongly couple view and model, Cells makes it extremely simple to have logicless views and move presentation code to the cell instance itself.

{% highlight haml %}
- # app/concepts/comment/views/show.haml
%li
  = body
  By #{author_link}
{% endhighlight %}

Every method invoked in the view is called on the cell instance. This means we have to implement `#body` and `#author_link` in the cell class. Note that how that completely replaces helpers with clean object-oriented methods.

{% highlight ruby %}
class Comment::Cell < Cell::ViewModel
  def show
    render
  end

private
  def body
    model.body
  end

  def author_link
    link_to model.author.email, author_path(model.author)
  end
end
{% endhighlight %}

What were global helper functions are now instance methods. All Rails helpers like `link_to` are available on the cell instance.

## Properties

Delegating attributes to the model is so common it is built into Cells.

{% highlight ruby %}
class Comment::Cell < Cell::ViewModel
  property :body
  property :author

  def show
    render
  end

private
  def author_link
    link_to author.email, author_path(author)
  end
end
{% endhighlight %}

The `::property` declaration will create a delegating method for you.

## Testing

The best part about Cells is: you can test them in isolation. If they work in a test, they will work just anywhere.

{% highlight ruby %}
describe Comment::Cell do
  it do
    html = concept("comment/cell", Comment.find(1)).()
    expect(html).to have_css("h1")
  end
end
{% endhighlight %}

The `concept` helper will behave exactly like in a controller or view and allows you to write rock-solid test for view components with a very simple API.

## More

Cells comes with a bunch of helpful features like nesting, caching, view inheritance, and more.
