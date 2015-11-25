---
layout: roar
title: "JSON API"
---

# JSON API

Roar supports rendering and parsing documents using the [JSON API 1.0](http://jsonapi.org/format/) specification.

By including `Roar::JSON::JSONAPI` into your representer a handful of additional DSL methods get imported.


## Overview

Here's a full example of a JSON API representer.

    class ArticleDecorator < Roar::Decorator
      include Roar::JSON::JSONAPI
      type :articles

      # top-level link.
      link :self, toplevel: true do
        "//articles"
      end

      # attributes: {}
      property :id
      property :title


      # resource object links
      link(:self) { "http://#{represented.class}/#{represented.id}" }

      # relationships
      has_one :author, class: Author, populator: ::Representable::FindOrInstantiate do # populator is for parsing, only.
        type :authors

        property :id
        property :email
        link(:self) { "http://authors/#{represented.id}" }
      end

      has_many :comments, class: Comment, populator: ::Representable::FindOrInstantiate do
        type :comments

        property :id
        property :body
        link(:self) { "http://comments/#{represented.id}" }
      end
    end

## Relationships



## Top-Level Links

## Parsing Collections

## Compound Document

You can suppress rendering of the compound document using the `:included` option.

    decorator.to_json(included: false)

## Sparse Fieldsets

As per specification, JSON API allows to suppress rendering of arbitrary fields. This is called [sparse fieldsets](http://jsonapi.org/format/#fetching-sparse-fieldsets).

With Roar, you can do that with all kinds of resource objects: Filtering attributes works for the top "primary data" and for relationships.

For the primary data, you simply provide what to include via the `:include` option.

    decorator.to_hash(
      include: [:id, :title]
    )

This will only render `:id` and `:title`.

    "data": {
      "type": "articles",
      "id": "1",
      "attributes": {"title"=>"My Article"}
    }

To include particular attributes, only, in the compound document, use `:fields`.

    decorator.to_hash(
      include: [:id, :title, :author],
      fields:  {author: [:email]}
    )

You can control what types should be included in the compound document by adding them to `:include`.

The `:fields` option allows to specify what attributes for what type to include.

    "data": {
      "type": "articles",
      "id": "1",
      "attributes": {"title"=>"My Article"}
    },
    "included": [
      {
        "type": "author",
        "id":   "a:1",
        "attributes": {
          "email": "celsito@trb.to"
        }
      }
    ]

Note that the `author` fragment only contains the `email` in its attributes.

The `to_json` API is designed to be able to process `params` directly, where JSON API parameters like `fields` from the request URL are parsed into hashes and arrays.