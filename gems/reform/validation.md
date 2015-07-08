---
layout: default
---

# Validation

Since Reform 2.0, you can pick your validation backend. This can either be `ActiveModel::Validations` or `Lotus::Validations`.

Reform will at some point drop ActiveModel-support in favor of a clean, fast, maintainable, and simple validations implementation as found in [lotus-validations](https://github.com/lotus/lotus-validations).


## ActiveModel

In Rails environments, the AM support will be automatically loaded.

You need to include `Reform::Form::ActiveModel::Validations` either into a particular form class, or simply into `Reform::Form` and make it available for all subclasses.

{% highlight ruby %}
require "reform/form/active_model/validations"

Reform::Form.class_eval do
  include Reform::Form::ActiveModel::Validations
end
{% endhighlight %}


## Lotus

To use Lotus validations (recommended).

{% highlight ruby %}
require "reform/form/lotus"

Reform::Form.class_eval do
  include Reform::Form::Lotus
end
{% endhighlight %}

Put this into an initializer or on top of your script.

If you forget doing so, the following exception will remind you.

<pre>
`validates': [Reform] Please include either Reform::Form::ActiveModel::Validations or Reform::Form::Lotus in your form class. (RuntimeError)
</pre>

## Uniqueness Validation

Both ActiveRecord and Mongoid modules will support "native" uniqueness support where the validation is basically delegated to the "real" model class. This happens when you use `validates_uniqueness_of` and will respect options like `:scope`, etc.

{% highlight ruby %}
class SongForm < Reform::Form
  include Reform::Form::ActiveRecord
  model :song

  property :title
  validates_uniqueness_of :title, scope: [:album_id, :artist_id]
{% endhighlight %}

Be warned, though, that those validators write to the model instance. Even though this _usually_ is not persisted, this will mess up your application state, as in case of an invalid validation your model will have unexpected values.

This is not Reform's fault but a design flaw in ActiveModel's validators.

You're encouraged to use Reform's non-writing `unique: true` validation, though.

{% highlight ruby %}
require "reform/form/validation/unique_validator.rb"

class SongForm < Reform::Form
  property :title
  validates :title, unique: true
end
{% endhighlight %}

This will only validate the uniqueness of `title`. Other options are not supported, yet. Feel free to [help us here](https://github.com/apotonick/reform/blob/master/lib/reform/form/validation/unique_validator.rb)!