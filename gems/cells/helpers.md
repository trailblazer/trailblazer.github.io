---
layout: cells
title: "Cells and Helpers"
---

# Helpers

Conceptually, Cells doesn't have helpers anymore. You can still include modules to import utility methods but they won't get copied to the view. In fact, the view is evaluated in the cell instance context and hence you can simply call instance methods in the template files.

## Translation and I18N

You can use the `#t` helper.


	require "cells/translation"

	class Admin::Comment::Cell < Cell::Concept
	  include ActionView::Helpers::TranslationHelper
	  include Cell::Translation

	  def show
	    t(".greeting")
	  end
	end


This will lookup the I18N path `admin.comment.greeting`.

Setting a differing translation path works with `::translation_path`.


	class Admin::Comment::Cell < Cell::Concept
	  include Cell::Translation
	  self.translation_path = "cell.admin"


The lookup will now be `cell.admin.greeting`.

## Asset Helpers

When using asset path helpers like `image_tag` that render different paths in production, please simply delegate to the controller.


	class Comment::Cell < Cell::Concept
	  delegates :parent_controller, :image_tag


The delegation fixes the [well-known problem](https://github.com/apotonick/cells/issues/214) of the cell rendering the "wrong" path when using Sprockets. Please note that this fix is necessary due to the way Rails includes helpers and accesses global data.