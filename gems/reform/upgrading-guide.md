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
