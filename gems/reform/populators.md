---
layout: default
permalink: /gems/reform/populators.html
---

# Reform: Populators

[Populators are discussed in detail in the chapters _Nested Forms_ and _Mastering Forms_ of the Trailblazer book.]

In `#validate`, Reform per default will try to match nested hashes to nested forms. In other words, Reform thinks that the form object graph is already matching 1-to-1 to the incoming params hash.

Let's say you're setting up the following form.

{% highlight ruby %}
album.songs.size #=> 1
form = AlbumForm.new(album)
form.songs.size #=> 1
{% endhighlight %}

In `validate` you then pass in an additional `Song` hash.

{% highlight ruby %}
form.validate(songs: [{name: "The Tempest"}, {name: "Nevermore"}])
{% endhighlight %}

Intuitively, you will expect Reform to create an additional song with the name "Nevermore". However, this is not how it works. Without configuration, Reform has no idea how to assign the second `:songs` fragment to the form and will raise an exception.

## Populate_if_empty

To let the form create a new model wrapped by a nested form for you use `:populate_if_empty`.

{% highlight ruby %}
class AlbumForm < Reform::Form
  property :songs, populate_if_empty: Song do
    property :name
  end
end
{% endhighlight %}

When traversing the incoming `songs:` collection, fragments without a counterpart nested form will be created for you with a new `Song` object.

You can also create the object yourself and leverage data from the traversed fragment, for instance, to try to find a `Song` object by name, first, before creating a new one.

{% highlight ruby %}
class AlbumForm < Reform::Form
  property :songs, populate_if_empty: ->(fragment, options) {
    Song.where(name: fragment["name"]) or User.new } do
{% endhighlight %}

The result from this block will be automatically added to the form graph.

You can also provide an instance method on the respective form.

{% highlight ruby %}
class AlbumForm < Reform::Form
  property :songs, populate_if_empty: :populate_songs! do
    property :name
  end

  def populate_songs!(fragment, options)
    Song.where(name: fragment["name"]) or User.new
  end
{% endhighlight %}


### Signature

The result of the block will automatically assigned to the property or collection for you. Note that you can't use the twin API in here. If you want to do fancy stuff, use `:populator`.

## Populating by ID

[This is described in chapter _Authentication_ in the Trailblazer book.]

Reform matches incoming hash fragments and nested forms by their order. It doesn't know anything about IDs or other persistence mechanics.

You can use `:populator` to write your own matching for IDs. This is a feature that might be included into Reform since this is a frequently implemented requirement when working with persisted models.

{% highlight ruby %}
property :songs,
  populator: ->(fragment, collection, index, options) {
    # find out if incoming song is already added.
    item = songs.find { |song| song.id.to_s == fragment["id"].to_s }
    item ? item : songs.insert(index, Song.new)
  }
{% endhighlight %}

Note that a `:populator` requires you to add/replace/update/delete the model yourself. You have access to the form API here since the block is executed in form instance context.

The `:populator` block has to return the corresponding nested form.

This naturally works for single properties, too.

{% highlight ruby %}
property :artist,
  populator: ->(fragment, options) {
    artist ? artist : self.artist = Artist.where(id: fragment["id"])
  }
{% endhighlight %}

It is important to check whether the respective collection item or single property already exists in the form, otherwise your graph will get out-of-sync.


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


