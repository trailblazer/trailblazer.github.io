---
layout: operation
title: Testing Operations
---

# Testing Operations

## FactoryGirl

In Trailblazer, you should never use factories for setting up a test environment. At some point, this will result in a diverging test and application state. Where production code might have set a tiny flag, your factory will skip this - diverge
