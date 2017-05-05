---
layout: reform
gems:
  - ["reform", "trailblazer/reform", "2.2"]
---

# Debugging Reform

# Override the entry point

* `#validate`: most things will go wrong here.
* `#deserialize!`, which is called from `#validate`. # TODO: make it easier to debug here.
* `#sync`
* `#save`
