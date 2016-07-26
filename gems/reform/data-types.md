## Composition

Reform allows to map multiple models to one form. The [complete documentation](https://github.com/apotonick/disposable#composition) is here, however, this is how it works.

    class AlbumTwin < Reform::Form
      include Composition

      property :id,    on: :album
      property :title, on: :album
      property :songs, on: :cd
      property :cd_id, on: :cd, from: :id
    end

When initializing a composition, you have to pass a hash that contains the composees.

    AlbumForm.new(album: album, cd: CD.find(1))


If the form wraps multiple models, via [composition](#compositions), you can access them like this:

    @form.save do |nested|
      song = @form.model[:song]
      label = @form.model[:label]
    end

Note that you can call `#sync` and _then_ call `#save { |hsh| }` to save models yourself.



## Compositions

Sometimes you might want to embrace two (or more) unrelated objects with a single form. While you could write a simple delegating composition yourself, reform comes with it built-in.

Say we were to edit a song and the label data the record was released from. Internally, this would imply working on the `songs` table and the `labels` table.

    class SongWithLabelForm < Reform::Form
      include Composition

      property :title, on: :song
      property :city,  on: :label

      model :song # only needed in ActiveModel context.

      validates :title, :city, presence: true
    end

Note that reform needs to know about the owner objects of properties. You can do so by using the `on:` option.

Also, the form needs to have a main object configured. This is where ActiveModel-methods like `#persisted?` or '#id' are delegated to. Use `::model` to define the main object.


### Composition: Setup

The constructor slightly differs.

    @form = SongWithLabelForm.new(song: Song.new, label: Label.new)

### Composition: Rendering

After you configured your composition in the form, reform hides the fact that you're actually showing two different objects.

    = form_for @form do |f|
      Song:     = f.input :title
      Label in: = f.input :city

### Composition: Processing

When using `#save' without a block reform will use writer methods on the different objects to push validated data to the properties.

Here's what the block parameters look like.

    @form.save do |nested|

      nested #=> {
             #   song:  {title: "Rio"}
             #   label: {city: "London"}
             #   }
    end


As with the built-in coercion, this setter is only called in `#validate`.


## Hash Fields

Reform can also handle deeply nested hash fields from serialized hash columns. This is [documented here](https://github.com/apotonick/disposable#struct).
