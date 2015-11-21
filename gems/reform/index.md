---
layout: reform
permalink: /gems/reform/
title: "Reform"
---

# Reform

## Associations

_"How do I map `has_many` associations to my form?"_


## Workflow

new
prepopulate!
Rendering: form.title
validate
  populate
  validate
sync
save





 the semantics are important: "this object is invalidation" conceptualization led to AM::Validations.
@realntl @_solnic_ Ah OK, I understand you now! Well, in Reform/TRB validation is a function that gets applied to an object graph. Better?