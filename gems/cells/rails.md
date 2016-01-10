---
layout: cells
title: "Cells and Rails"
---

# Rails

When using cells in a Rails app there's several nice features to benefit from.

## Asset Pipeline

Cells can bundle their own assets in the cell's view directory. This is a very popular way of writing highly reusable components.

It works with both engine cells and application cells.



	├── cells
	│   ├── comment_cell.rb
	│   ├── comment
	│   │   ├── show.haml
	│   │   ├── comment.css
	│   │   ├── comment.coffee



You need to register the cells with bundled assets. Preferably, this happens in `config/application.rb` of the main application.


	class Application < Rails::Application
	  # ..
	  config.cells.with_assets = ["comment_cell"]


The names added to `with_assets` have to be the fully qualified, underscored cell name. They will get `constantize`d to find the cell name at runtime.

If using namespaces, this might be something along `config.cells.with_assets = ["my_engine/song/cell"]`.

In `app/assets/application.js`, you need to add the cell JavaScript assets manually.


	//=# require comments


Likewise, you have to reference the cell's CSS files in `app/assets/application.css`.


	/*
	 *= require comment
	 */


## Assets Troubleshooting

The Asset Pipeline is a complex system. If your assets are not compiled, start debugging in [Cells' railtie](https://github.com/apotonick/cells/blob/master/lib/cell/railtie.rb) and uncomment the `puts` in the `cells.update_asset_paths` initializer to see what directories get added.

Cell classes need to be loaded when precompiling assets! Make sure your `application.rb` contains the following setting (per default, this is turned _on_).


	config.assets.initialize_on_precompile = true


You need to compile assets using this command, which is [explained here](http://stackoverflow.com/a/12167790/465070).


	rake assets:precompile:all RAILS_ENV=development RAILS_GROUPS=assets


## Global Partials

Although not recommended, you can also render global partials from a cell. Be warned, though, that they will be rendered using our stack, and you might have to include helpers into your view model.

This works by including `Partial` and the corresponding `:partial` option.

```ruby
class Cell < Cell::ViewModel
  include Partial

  def show
    render partial: "../views/shared/map.html" # app/views/shared/map.html.haml
  end
```

The provided path is relative to your cell's `::view_paths` directory. The format has to be added to the file name, the template engine suffix will be used from the cell.

You can provide the format in the `render` call, too.

```ruby
render partial: "../views/shared/map", formats: [:html]
```

This was mainly added to provide compatibility with 3rd-party gems like [Kaminari and Cells](https://github.com/apotonick/kaminari-cells) that rely on rendering partials within a cell.

## Generators

In Rails, you can generate cells and concept cells.

```
rails generate cell comment
```

Or, TRB-style concept cells.

```
rails generate concept comment
```
