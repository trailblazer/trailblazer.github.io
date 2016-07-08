---
layout: cells
title: "Formular"
description: "Formular is a form builder for Ruby. It's fast and framework-agnostic, supports Bootstrap, Foundation, and UIKit."
---

## Bootstrap 3

### Inline Forms

Instruct Formular to render an [inline form](http://getbootstrap.com/css/#forms-inline) via `style: :inline`.

    form(model, "/posts", style: :inline) do |f|

You can not pass a `:label` into the control to skip rendering a label. Make sure to use `:placeholder`, then. Alternatively, you can do as follows to suppress the label (this is the recommended Bootstrap way).

    = f.input :url_slug,
      label:       "URL slug",
      placeholder: "URL slug",
      label_attrs: { class: ["sr-only"] }
