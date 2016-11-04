The operation's goal is simple: Remove all business logic from the controller and model and instead provide a separate object for it. While doing so, this logic is streamlined into the following steps.



The generic logic can be found in the trailblazer-operation gem. Higher-level abstractions, such as form object or policy integration is implemented in the trailblazer gem.



## Result

result.contract [.errors, .success?, failure?]
result.policy [, .success?, failure?]
