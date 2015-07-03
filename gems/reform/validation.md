---
layout: default
---

# Validation

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