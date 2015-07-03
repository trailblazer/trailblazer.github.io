---
layout: default
permalink: /gems/operation/
---

# Trailblazer::Operation

## Design Goals

Operations decouple the business logic from the actual framework and from the persistence layer. This makes is really easy to swap ORMs or the entire framework. For instance, operations written in a Rails environment can be run in Sinatra or Lotus as the only coupling happens when querying or writing to the database.

Abstraction via Twin (for view, BL, representers)

Pages: [API](api.html)
Pages: [Collection](collection.html)
Pages: [Callback](callback.html)
Pages: [Controller](controller.html)
Pages: [representer](representer.html)
>>>>>>> f12f2b80976c6fff4edec26455b861b20ce86d54
