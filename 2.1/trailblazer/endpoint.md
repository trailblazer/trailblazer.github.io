---
layout: operation-2-1
title: "Endpoint"
gems:
  - ["trailblazer-operation", "trailblazer/trailblazer-operation", "2.1"]
code: ../trailblazer-operation/test/docs,wiring_test.rb,master
---

## Matcher

Matchers maps a pattern to an action. The action can be an `Option` for dynamic execution or a callable (same).
When invoked, the matcher simply passes on all options to the patterns, then to the action.

def initialize(*)
      patterns = Pattern.new.to_h

      matcher_cfg = {
        patterns[:success_with_block?]  => Trailblazer::Option(:yield_block),
        patterns[:success_render?]      => Trailblazer::Option(:render_cell),
        patterns[:failure_render?]      => Trailblazer::Option(:render_cell),
      }

      @matcher = Trailblazer::Endpoint::Matcher.new(matcher_cfg)
    end

    def call(operation, options, cell, cell_options={}, &block)
      result = operation.( options ) # this should happen in the endpoint gem.

      @matcher.( { exec_context: Object.new.extend(Action) }, result, cell, cell_options, &block )
    end
