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

    form(model.contract, url) do |f|

## Builder

The default builder needs to be set.

    Formular::Helper.builder = :bootstrap3

This can be overridden in the single form using the option `builder`, for example to have an inline form.

    form(model.contract, url, builder: :bootstrap3_inline)

## Input

The `input` method receives all Formular options (`:placeholder`, `:label`).

    = f.input :title, label: "Title"

## Group Addon

You can render a [control composition](http://getbootstrap.com/components/#input-groups-basic) using `input_group`.

{{ "concepts/post/view/new.slim:vertical-inputgroup:../gemgem-sinatra/:formular-slim-bootstrap3" | tsnippet }}

Note that `control` allows you to output the actual input control at any point.


## Input Options

The following snippet is an example of available options.

{{ "concepts/post/view/new.slim:input_options:../gemgem-sinatra/:formular-slim-bootstrap3" | tsnippet }}

Which will render:

<img src="/images/formular/bs3-input-options.png">

### Type
Use `type` to have for example `hidden`, `password` or `file` type. [Here](https://v4-alpha.getbootstrap.com/components/forms/#textual-inputs) the list of textual input types.

{% callout %}
Make sure to add `enctype: 'multipart/form-data'` as argument in the `form` to have the full path from the `file` type input.

This might be done automatically in future releases.
{% endcallout %}

### Value
Use `value` to set the content of an input, in our example above `id` is set as `"some_id"`.

### Help Block
Use `hint` to have an `help_block` with some useful words.

## Select

The `select` method receives the same options of input (not `type` and `prompt` instead of `placeholder`) plus the options for multiple choices: `multiple` and `collection`.

{{ "concepts/post/view/new.slim:select:../gemgem-sinatra/:formular-slim-bootstrap3" | tsnippet }}

Which will render:

<img src="/images/formular/bs3-select.png">

For multiple choices `multiple: 'multiple'` needs to be one of the options and, of course, `collection` too.
Here below the arrays used in this example:

    roles_array = [["Admin", 1], ["Owner", 2], ["Maintainer", 3]]

    complex_role = [['Team', [['England', 'e'], %w(Italy i),['Germany', 'g']]],['Roles', [['Fullback', 0], ['Hooker', 1], ['Wing', 2]]]]

## Check and Radio box

The `checkbox` and `radiobox` have the same API

{{ "concepts/post/view/new.slim:check_radio_box:../gemgem-sinatra/:formular-slim-bootstrap3" | tsnippet }}

Which will render:

<img src="/images/formular/bs3-check-radio.png">

When `value` and the form property (`is_public`)'s value are matching the check/radiobox will be checked - so make sure to set it properly.

Override the ticked/checked state using `checked: 'checked'`

## Inline Form

To render an inline form you just need to change the builder.

{{ "concepts/post/view/new.slim:inline_form:../gemgem-sinatra/:formular-slim-bootstrap3" | tsnippet }}

<img src="/images/formular/bs3-inline-form.png">

## Horizontal Form

{{ "concepts/post/view/new.slim:horizontal_form:../gemgem-sinatra/:formular-slim-bootstrap3" | tsnippet }}

<img src="/images/formular/bs3-horizontal-form.png">
