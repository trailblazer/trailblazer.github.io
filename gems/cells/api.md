---
layout: cells
title: "Cells API"
---

## Cell Class

Every fragment is represented by a cell class. Following the Trailblazer convention, the `Comment::Cell` sits in `app/concepts/comment/cell.rb`.

```ruby
class Comment::Cell < Cell::ViewModel
  def show
    render # renders app/concepts/comment/view[s]/show.haml.
  end
end
```

A cell has to define at least one method which in turn has to return the fragment. Per convention, this is `show`. In the public method, you may compile arbitrary strings or `render` a cell view.

The return value of this public method (also called _state_) is what will be the rendered in the view using the cell.

## Manual Invocation

Without using any helpers and in its purest form, a cell can be rendered as follows.

```ruby
Comment::Cell.new(comment).(:show) #=> "fragment string"
```

This can be split up into two steps: initialization and invocation.

## Initialize

While you will mostly use the `concept` or `cell` helper in views and controllers, you may instantiate cells manually.

```ruby
cell = Comment::Cell.new(comment)
```

This is helpful in environments where the helpers are not available, e.g. a Rails mailer or a `Lotus::Action`.

You can also pass arbitrary options into the cell, for example the controller.

```ruby
cell = Comment::Cell.new(comment, parent_controller: self)
```

However, in most cases you instantiate cells with the `concept` or `cell` helper which internally does exactly the same.

	cell = concept("comment/cell", comment)

As always in Ruby, instantiation returns the cell instance.

## Invocation

Once you got the cell instance, you may call the rendering state.

	cell.(:show)

Since `show` is the default state, you may simple _call_ the cell without arguments.

	cell.() #=> cell.(:show)

Note that in Rails controller views, this will be called automatically via cell's `ViewModel#to_s` method.

## Call

Always invoke cell methods via `call`. This will ensure that caching - if configured - is performed properly.

	concept("comment/cell", comment).(:show)

This will call the cell's `show` method and return the rendered fragment.

Note that you can invoke more than one state on a cell, if desired.

```ruby
- cell = concept("comment/cell", Song.last) # instantiate.
= cell.call(:show)                          # render main fragment.
= content_for :footer, cell.(:footer)       # render footer.
```

See how you can combine cells with global helpers like `content_for`?

## Options

A cell can wrap more than one model. This can be handy to pass in additional data you need for presentation.


	concept("comment/cell", comment, admin: true)


Inside the cell, the additional options are available via `#options`.


	class Comment::Cell < Cell::ViewModel
	  def show
	    return render :admin if options[:admin]
	    render
	  end



Class.()

Class.build (no def args)

ViewModel::cell()



## HTML Escaping

Cells per default does no HTML escaping, anywhere. This is one of the reasons that makes Cells faster than Rails.

Include `Escaped` to make property readers return escaped strings.


	class CommentCell < Cell::ViewModel
	  include Escaped
	  property :title
	end

	song.title                 #=> "<script>Dangerous</script>"
	Comment::Cell.(song).title #=> &lt;script&gt;Dangerous&lt;/script&gt;


Only strings will be escaped via the property reader.

You can suppress escaping manually.


	def raw_title
	  "#{title(escape: false)} on the edge!"
	end


Of course, this works in views, too.


	<%= title(escape: false) %>


## Nesting

## View Inheritance

Cells can inherit code from each other with Ruby's inheritance.

```ruby
class CommentCell < Cell::ViewModel
end

class PostCell < CommentCell
end
```

Even cooler, `PostCell` will now inherit views from `CommentCell`.

```ruby
PostCell.prefixes #=> ["app/cells/post", "app/cells/comment"]
```

When views can be found in the local `post` directory, they will be looked up in `comment`. This starts to become helpful when using [composed cells](#nested-cells).

If you only want to inherit views, not the entire class, use `::inherit_views`.

```ruby
class PostCell < Cell::ViewModel
  inherit_views Comment::Cell
end

PostCell.prefixes #=> ["app/cells/post", "app/cells/comment"]
```

# Collections

This will instantiate each collection cell as follows.


	Comment.(comment, style: "awesome", volume: "loud")


## Caching

Cells allow you to cache per state. It's simple: the rendered result of a state method is cached and expired as you configure it.

To cache forever, don't configure anything

```ruby
class CartCell < Cell::Rails
  cache :show

  def show
    render
  end
```

This will run `#show` only once, after that the rendered view comes from the cache.


## Cache Options

Note that you can pass arbitrary options through to your cache store. Symbols are evaluated as instance methods, callable objects (e.g. lambdas) are evaluated in the cell instance context allowing you to call instance methods and access instance variables. All arguments passed to your state (e.g. via `render_cell`) are propagated to the block.

```ruby
cache :show, :expires_in => 10.minutes
```

If you need dynamic options evaluated at render-time, use a lambda.

```ruby
cache :show, :tags => lambda { |*args| tags }
```

If you don't like blocks, use instance methods instead.

```ruby
class CartCell < Cell::Rails
  cache :show, :tags => :cache_tags

  def cache_tags(*args)
    # do your magic..
  end
```

## Conditional Caching

The `:if` option lets you define a condition. If it doesn't return a true value, caching for that state is skipped.

```ruby
cache :show, :if => lambda { |*| has_changed? }
```

## Cache Keys

You can expand the state's cache key by appending a versioner block to the `::cache` call. This way you can expire state caches yourself.

```ruby
class CartCell < Cell::Rails
  cache :show do |options|
    order.id
  end
```

The versioner block is executed in the cell instance context, allowing you to access all stakeholder objects you need to compute a cache key. The return value is appended to the state key: `"cells/cart/show/1"`.

As everywhere in Rails, you can also return an array.

```ruby
class CartCell < Cell::Rails
  cache :show do |options|
    [id, options[:items].md5]
  end
```

Resulting in: `"cells/cart/show/1/0ecb1360644ce665a4ef"`.


## Debugging Cache

When caching is turned on, you might wanna see notifications. Just like a controller, Cells gives you the following notifications.

* `write_fragment.action_controller` for cache miss.
* `read_fragment.action_controller` for cache hits.

To activate notifications, include the `Notifications` module in your cell.

```ruby
class Comment::Cell < Cell::Rails
  include Cell::Caching::Notifications
```

## Cache Inheritance

Cache configuration is inherited to derived cells.

## Testing Caching

If you want to test it in `development`, you need to put `config.action_controller.perform_caching = true` in `development.rb` to see the effect.

