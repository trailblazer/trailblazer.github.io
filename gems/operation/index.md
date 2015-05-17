---
layout: default
permalink: /gems/operation/
---

# Trailblazer::Operation

## Design Goals

Operations decouple the business logic from the actual framework and from the persistence layer. This makes is really easy to swap ORMs or the entire framework. For instance, operations written in a Rails environment can be run in Sinatra or Lotus as the only coupling happens when querying or writing to the database.

Abstraction via Twin (for view, BL, representers)