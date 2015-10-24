---
layout: cells
title: "Trailblazer: Cells Templates"
---

# Template Engines

Cells supports various template engines.

We provide support for Haml, Erb, and Slim. You can also write [your own](#your-own) template engine.

In a non-Rails environment, you need to include the respective module into your cells, so it knows what template to find.


	class SongCell < Cell::ViewModel
	  include Cell::Erb
	  # include Cell::Haml
	  # include Cell::Slim


Note that you can only include _one engine per class_. This is due to problems with helpers in Rails and the way they have to be fixed in combination with Cells.

### Multiple Template Engines in Rails

When including more than one engine in your Gemfile in Rails, the last one wins. Since each gem includes itself into `Cell::ViewModel`, unfortunately there can only be one global engine.

Currently, there's no clean way but to disable automatic inclusion from each gem (not yet implemented) and then include template modules into your application cells manually.

## ERB

## Haml

## Slim

## Your Own

Theoretically, you can use any template engine supported by Tilt.

To activate it in a cell, you only need to override `#template_options_for`.


	class SongCell < Cell::ViewModel
	  def template_options_for(options)
	    {
	      template_class: Tilt, # or Your::Template.
	      suffix:         "your"
	  }
	  end


This will use `Tilt` to instantiate a template to be evaluated. The `:suffix` is needed for Cells when finding the view.