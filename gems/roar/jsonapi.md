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

## Sparse Fieldsets