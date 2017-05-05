---
layout: cells
title: "Cells Render API"
gems:
  - ["cells", "trailblazer/cells", "4.1"]
---

# Rendering

## View Paths

Every cell class can have multiple view paths. However, I advise you not to have more than two, better one, unless you're implementing a cell in an engine. This is simply to prevent unexpected behavior.

View paths are set via the `::view_paths` method.


	class Cell::ViewModel
	  self.view_paths = ["app/cells"]


Use the setter to override the view paths entirely, or append as follows.


	class Shopify::CartCell
	  self.view_paths << "/var/shopify/app/cells"


The `view_paths` variable is an inheritable array.

A trick to quickly find out about the directory lookup list is to inspect the `::prefixes` class method of your particular cell.


	puts Shopify::CartCell.prefixes
	#=> ["app/cells/shopify/cart", "/var/shopify/app/cells/shopify/cart"]


This is the authorative list when finding templates. It will include inherited cell's directories as well when you used inheritance. The list is traversed from left to right.

## Partials

Even considered a taboo, you may render global partials from Cells.


	SongCell < Cell::ViewModel
	  include Partial

	  def show
	    render partial: "../views/shared/sidebar.html"
	  end


Make sure to use the `:partial` option and specify a path relative to the cell's view path. Cells will automatically add the format and the terrible underscore, resulting in `"../views/shared/_sidebar.html.erb"`.
