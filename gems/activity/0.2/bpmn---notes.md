BPMN - Limitations in TRB 2.1

BPMN is an evented system, where completely decoupled systems and processes can interrupt and message each other. While this provides a sophisticated tool for modelling processes, it also comes with a price: understanding and debugging of evented systems becomes harder.

Until we understand the use of events in BPMN better, we decided to go with a simpler event model that is still compatible to BPMN 2, but a subset of the available possibilities. These are sufficient for most common use cases, and we're planning to extend Trailblazer.

Trailblazer 2.1 only allows "sequential events", where a process enters one or multiple catching events and then waits for those to be triggered somewhere else. We make use of them everywhere in the example application.

What we do not provide, yet, is non-interrupting boundary events. While these are actually quite simple to implement, it would bloat the gems with a "real" event mechanism and increase complexity. Since this is only the beginning of us exploring the world of BPMN, we designed TRB 2.1 to be easily capable of handling those events (for instance, we do have the necessary encapsulation), but leave this open to >=2.2.

page 92 example.
