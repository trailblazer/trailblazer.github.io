---
layout: formular
title: "Formular: Bootstrap"
description: "API for Bootstrap 3/4 in Formular."
gems:
  - ["formular", "trailblazer/formular", "0.1"]
---

The `Bootstrap` builder can render horizontal forms, inline forms, and vertical forms, which is the default. Currently, the API to render elements is identical for BS3 and BS4.

<i class="fa fa-download" aria-hidden="true"></i> Where's the [**EXAMPLE CODE?**](https://github.com/apotonick/gemgem-sinatra/blob/formular-slim-bootstrap3/concepts/post/view/new.slim)

## Vertical Forms

To display form elements from to top to bottom use the vertical form builder.

{{ "concepts/post/view/new.slim:vertical:../gemgem-sinatra/:formular-slim-bootstrap3" | tsnippet }}

This will render a form as follows. Note how items without `.row` are aligned *vertically* by BS.

<img src="/images/formular/bs3-vertical.png">

## Form

As always, the ###fixme needs at least two arguments: `model` and `url`.

    vertical_form(model.contract, url) do |f|

## Input

The `input` method receives all Formular options (`:placeholder`, `:label`).

    = f.input :title, label: "Title"

## Group Addon

You can render a [control composition](http://getbootstrap.com/components/#input-groups-basic) using `input_group`.

{{ "concepts/post/view/new.slim:vertical-inputgroup:../gemgem-sinatra/:formular-slim-bootstrap3" | tsnippet }}

Note that `control` allows you to output the actual input control at any point.


f.hidden
 <%= f.textarea :pasteZone, value: "" %>
