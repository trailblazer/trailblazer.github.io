---
layout: default
permalink: /gems/reform/populators.html
---

# Reform: Populators

...

## :populate_if_empty

{% highlight ruby %}
populate_if_empty: ->(params, *) { User.find_by_email(params["email"]) or User.new },
{% endhighlight %}

### Signature

The result of the block will automatically assigned to the property or collection for you. Note that you can't use the twin API in here. If you want to do fancy stuff, use `:populator`.

You do NOT have access to the entire Collection api (NO WE DO HAVE, VERIFY! )

## Uninitialized Collections

A problem with populators can be an uninitialized `collection` property.

{% highlight ruby %}
class AlbumForm < Reform::Form
  collection :songs, populate_if_empty: Song do
    property :title
  end
end

album = Album.new
form  = AlbumForm.new(album)

album.songs #=> nil
form.songs  #=> nil

form.validate(songs: [{title: "Friday"}])
#=> NoMethodError: undefined method `original' for nil:NilClass
{% endhighlight %}

What happens is as follows.

1. In `validate`, the form can't find a corresponding nested songs form and calls the `populate_if_empty` code.
2. The populator will create a `Song` model and assign it to the parent form via `form.songs << Song.new`.
3. This crashes, as `form.songs` is `nil`.

The solution is to initialize your object correctly. This is per design. It is your job to do that as Reform/Disposable is likely to do it wrong.

{% highlight ruby %}
album = Album.new(songs: [])
form  = AlbumForm.new(album)
{% endhighlight %}

With ORMs, the setup happens automatically, this only appears when using `Struct` or other POROs as models.

## Internals

`:populator` options are called via the `:instance` hook in the deserializer. They disable `:setter`, hence you have to set newly created twins yourself.

(how models automatically become twinned when assigning)


