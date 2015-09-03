---
layout: default
---

# Policy

Trailblazer supports "pundit-style" policy classes. They can be hooked into operations and prevent the operation from running its `#process` method by raising an exception if the policy rule returned `false`.

## Policy Classes

The format of a policy class is heavily inspired by the excellent [Pundit](https://github.com/elabs/pundit) gem. In fact, you can reuse your pundit policies without any code changes in Trailblazer.

A policy file per concept is recommendable.

{% highlight ruby %}
class Thing::Policy
  def initialize(user, thing)
    @user, @thing = user, thing
  end

  def create?
    admin?
  end

  def admin?
    @user.admin == true
  end
  # ..
end
{% endhighlight %}

This class would probably be best located at `app/concepts/thing/policy.rb`.

## Operation Policy

Use `::policy` to hook the policy class along with a query action into your operation.

{% highlight ruby %}
class Thing::Create < Trailblazer::Operation
  include Policy

  policy Thing::Policy, :create?
{% endhighlight %}


The policy is evaluated in `#setup!`, raises an exception if `false` and thus suppresses running `#process`. It is a great way to protect your operations from unauthorized users.

{% highlight ruby %}
Thing::Create.(current_user: User.find_normal_user, thing: {})
{% endhighlight %}

This will raise a `Trailblazer::NotAuthorizedError`.

## Policy Creation

To instantiate the `Thing::Policy` object internally, per default the `params[:current_user]` and the operation's `model` is passed into the constructor. You can override that via `Operation#evaluate_policy`.

## Queries

After `#setup!`, the policy instance is available at any point in your operation code.

{% highlight ruby %}
def process(params)
  notify_admin! if policy.admin?
{% endhighlight %}

This won't raise an exception.

## Guard

Instead of using policies, you can also use a simple guard. A guard is like an inline policy that doesn't require you to define a policy class. It is run in `#setup!`, too, like a real policy, but isn't accessable in the operation after that.

```ruby
class Thing::Create < Trailblazer::Operation
  include Policy::Guard

  policy-> (params) do
    return false if params[:current_user].nil?
  end
```

Note that you can't mix `Policy` and guards in one class.

## Resolver

You can use policies in your builders, too. Please refer to the [builder docs](builder.html#resolver) to learn about that.