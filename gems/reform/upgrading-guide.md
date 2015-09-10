---
layout: default
---

# Upgrading Guide

We try to make upgrading as smooth as possible. Here's the generic documentation, but don't hesitate to ask for help on IRC.

## 2.0 to 2.1

* In a Rails environment with ActiveModel/ActiveRecord, you have to include the [reform-rails](https://github.com/trailblazer/reform-rails) gem.

{% highlight ruby %}
gem "reform"
gem "reform-rails"
{% endhighlight %}


## 1.2 to 2.0

### Validations

Validations like `validates_acceptance_of` doesn't work anymore, you have to use `validates acceptance: true`.

### Validation Backend

This only is necessary when _not_ using `reform/rails`.

In an initializer, e.g. `config/initializers/reform.rb`.

```ruby
require "reform/form/active_model/validations"
Reform::Form.class_eval do
  include Reform::Form::ActiveModel::Validations
end
```
