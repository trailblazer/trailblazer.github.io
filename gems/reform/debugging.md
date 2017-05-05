---
layout: reform
gems:
  - ["reform", "trailblazer/reform"]
---

# Debugging Reform

# Override the entry point

* `#validate`: most things will go wrong here.
* `#deserialize!`, which is called from `#validate`. # TODO: make it easier to debug here.
* `#sync`
* `#save`
