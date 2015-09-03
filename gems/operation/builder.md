---
layout: default
---

# Builder

## Resolver

A resolver allows you to use both the operation model and the policy in the builder.

{% highlight ruby %}
class Thing::Create < Trailblazer::Operation
  include Resolver

  policy Thing::Policy, :create?
  model Thing, :create

  builds -> (model, policy, params)
    return Admin if policy.admin?
    return SignedIn if params[:current_user]
  end
{% endhighlight %}

Please note that the `builds` block is run in class context, no operation instance is available, yet. It is important to understand that `Resolver` also changes the way the operation's model is created/found. This, too, happens on the class layer, now.

You have to configure the CRUD module using `::model` so the operation can instantiate the correct model for the builder.

If you want to change the way the model is created, you have to do so on the class level.

{% highlight ruby %}
class Thing::Create < Trailblazer::Operation
  include Resolver
  # ..

  def self.model!(params)
    Thing.find_by(slug: params[:slug])
  end
{% endhighlight %}