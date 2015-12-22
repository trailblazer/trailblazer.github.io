---
layout: operation.md
title: "Trailblazer Loader"
---

# Trailblazer::Loader

Design

Load deeper structured files, first. representer, policy etc should not depend on each other



## First Step

If automatic loading doesn't work for you, as a first resolution, require files manually.

    require_relative "../comment/create"

Actually, Ruby is the only programming language that does help with loading, and has problems. Most other languages require you to load files manually.

Even Matz himself is [not so sure anymore](https://twitter.com/yukihiro_matz/status/676170870226706432) if allowing autoloading was a wise choice in Ruby.