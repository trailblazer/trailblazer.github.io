---
layout: default
permalink: /gems/reform/populators.html
---

# Reform: Populators

...

## Internals

`:populator` options are called via the `:instance` hook in the deserializer. They disable `:setter`, hence you have to set newly created twins yourself.

(how models automatically become twinned when assigning)