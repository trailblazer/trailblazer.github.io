---
layout: representable
title: "Representable: Function API"
---

# Function API

Both rendering and parsing have a rich API that allows you to hook into certain steps and change behavior.

If that still isn't enough, you can create your own [pipeline](pipeline.html).

## Overview

Function option are passed to `property`.

    property :id, default: "n/a"

Most options accept a static value, like a string, or a dynamic lambda.

    property :id, if: ->(options) { options[:fragment].nil? }

The `options` hash is passed to **all options** and has the following members.
{doc: doc, options: options, represented: represented, decorator: self}

`options[:doc]` | When rendering, the document as it gets created. When parsing, the entire document.
`options[:fragment]` | When parsing, this is the fragment read from the document corresponding to this property.
`options[:input]` | When rendering, this is the value read from the represented object corresponding to this property.
`options[:represented]` | The currently represented object.
`options[:decorator]` | The current decorator instance.
`options[:binding]` | The current binding instance. This allows to access the currently used definition, e.g. `options[:binding][:name]`.
`options[:options]` | All options that have been passed into the render or parse method.
`options[:user_options]` | The `:user_options` for the current representer. These are only the [nested options](api.html#nested-user-options) from the user, for a particular representer.

In your option function, you can either receive the entire options hash and use it in the block.

    if: ->(options) { options[:fragment].nil? }

Or, and that is the preferred way, use Ruby's keyword arguments.

    if: ->(fragment:, **) { fragment.nil? }

## Options

Here's a list of all available options.

`:as` | [Renames property](#as)
`:getter` | [Custom getter logic for rendering](#getter)
`:setter` | [Custom setter logic after parsing](#setter)
`:if` | [Includes property when rendering/parsing when evaluated to true](#if)
`:reader` | [Overrides entire parsing process for property](#reader)
`:writer` | [Overrides entire rendering process for property](#writer)
`:skip_parse` | [Skips parsing when evaluated to true](#skip-parse)
`:skip_render` | [Skips rendering when evaluated to true](#skip-render)
`:parse_filter` | [Pipeline to process parsing result](#parse-filter)
`:skip_render` | [Pipeline to process rendering result](#render-filter)


class: lambda { |fragment, [i], args| } (see Nesting)
extend: lambda { |object, args| } (see Nesting)
instance: lambda { |fragment, [i], args| } (see Object Creation)
prepare: lambda { |object, args| } (see docs)
serialize: lambda { |object, args| } (see docs)
deserialize: lambda { |object, fragment, args| } (see docs)

## As

If your property name doesn't match the name in the document, use the :as option.

    property :title, as: :name

This will render using the `:as` value. Vice-versa for parsing

    song.to_json #=> {"name":"Fallout","track":1}

## Getter

When rendering, Representable calls the property's getter on the represented object. For a property named `:id`, this will result in `represented.id` to retrieve the value for rendering.

You can override this, and instead of having Representable call the getter, run your own logic.

    property :id, getter: ->(represented:, **) { represented.uuid.human_readable }

In the rendered document, you will find the UUID now where should be the ID.

    decorator.to_json #=> {"id": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6"}

As helpful as this option is, please do not overuse it. A representer is not a data mapper, but a document transformer. If your underlying data model and your representers diverge too much, consider using a [twin](/gems/disposable) to simplify the representer.

## Setter

After parsing has happened, the fragment is assigned to the represented object using the property's setter. In the above example, Representable will call `represented.id=(fragment)`.

Override that using `:setter`.

    property :id,
      setter: ->(fragment:, represented:, **) { represented.uuid = fragment.upcase }

Again, don't overuse this method and consider a twin if you find yourself using `:setter` for every property.

## If

You can exclude properties when rendering or parsing, as if they were not defined at all. This works with `:if`.

    property :id, if: ->(user_options) { user_options[:is_admin] }

When parsing (or rendering), the `id` property is only considered when `is_admin` has been passed in.

This will parse the `id` field.

    decorator.from_json('{"id":1}', user_options: {is_admin: true})


## Reader

To override the entire parsing process, use `:reader`. You won't have access to `:fragment` here since parsing hasn't happened, yet.

    property :id,
      reader: ->(represented:,doc:) { represented.payload = doc[:uuid] || "n/a" }

With `:reader`, parsing is completely up to you. Representable will only invoke the function and do nothing else.

## Writer

To override the entire rendering process, use `:writer`. You won't have access to `:input` here since the value query to the represented object hasn't happened, yet.

    property :id,
      writer: ->(represented:,doc:) { doc[:uuid] = represented.id }

With `:writer`, rendering is completely up to you. Representable will only invoke the function and do nothing else.

## Skip Parse

To suppress parsing of a property, use `:skip_parse`.

    property :id,
      skip_parse: ->(fragment:) { fragment.nil? || fragment=="" }

No further processing happens with this property, should the option evaluate to true.

## Skip Render

To suppress rendering of a property, use `:skip_render`.

    property :id,
      skip_render: ->(represented:) { represented.id.nil? }

No further processing happens with this property, should the option evaluate to true.

## Parse Filter

Use `:parse_filter` to process the parsing result.

    property :id,
      parse_filter: ->(fragment, options) { fragment.strip }

Just before setting the fragment to the object via the setter, the `:parse_filter` is called.

Note that you can add multiple filters, the result from the last will be passed to the next.

## Render Filter

Use `:render_filter` to process the rendered fragment.

    property :id,
      render_filter: ->(input, options) { input.strip }

Just before rendering the fragment into the document, the `:render_filter` is invoked.

Note that you can add multiple filters, the result from the last will be passed to the next.