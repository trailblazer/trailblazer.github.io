# Macros

Macros let you compute options for a task, such as a :name.
add any kind of task or nested activity configured by user input passed to that macro
allows to rewire the task, e.g. to add connections to other end events (used in Nested, for example)

If you don't need any of this, please just use a simple callable object instead.




return

the return hashes are *not wrapped* automatically. You need to apply `Variables::Merge` etc. where necessary.
