## What is TRB

blabla OPs => run in controller, rake tasks, tests, factories


## What are the big changes?

In fact, not too much has changed with this milestone. Internals have been restructured and gems replaced, but the real _change_ is actually a massive extension.

To cut it short, operations can now be wired and nested in bigger compounds and can model anything from simple state machines or business rules to real application-wide workflows.

In order to achieve this, we simplified and decoupled a huge number of parts in 2.1.

DSL vs. runtime

Wrap with
```
step( Wrap( ->(options, *args, &block) {
        begin
          block.call
        rescue => exception
          options["result.model.find"] = "argh! because #{exception.class}"
          [ Railway.fail_fast!, options, *args ]
        end }) {
        step ->(options, **) { options["x"] = true }
        step Model( Song, :find )
        step Contract::Build( constant: MyContract )
      }.merge(fast_track: true))
```

## Planned

### Type checking at compile-time.

Let's say you'd add the `Tyrant::SignOut` operation to your activity which declares a requirent `:current_user`. In case you forgot to provide this object via the context, an error will be generated at compile time since we can track dependencies and whether or not they will be around at runtime.


# Immutability

in 19 out of 20 cases, it sucks to mutate a hash, for example
tracing still uses it




# Making of: DSL

* We want a circuit hash
we have a linear DSL, and to make it even more complicated, subclasses or composers can alter existing schemas.
How to get from a linear definition to a graph?
  insert_before: problem was: very complex, time-intensive, and you couldn't point to not-yet-existing nodes
  human draws graph approach

1. problem:
  getting to a sorted list that will be transformed to graph
2. problem:
  how to list ==> circuit hash

we can't just make a graph from list, because we need to
  1. be able to merge at run-time (task wrap), merging graphs, huh?
  2. be able to "merge" other schemas, e.g. when inheriting and altering

That means, we need to keep a linear data structure with annotations (what is a railway edge?) and the ability to track the order (insert :before) that we can easily modify, insert tasks, reconnect, delete, replace, etc.


  => Sequence (not a graph, for easy manipulation/merging with linearity)
    in the end, we want one list for the drawer
      instead of graph alteration instructions, we have now drawing instructions

  => transform Sequence into graph/circuit



# More Service Objects, Already

even though overseen by some
