---
layout: disposable
permalink: /gems/disposable/twin/
title: "Disposable Twin"
gems:
  - ["disposable", "apotonick/disposable", "0.4"]
---

# Twin


	class Song::Twin < Disposable::Twin
	  property :title
	end


A twin decorates objects. It doesn't matter whether this is an ActiveRecord instance, a ROM model or a PORO.


	song = OpenStruct.new(title: "Solitaire")
	song.title #=> "Solitaire"


## API

Initialization always requires an object to twin.


	twin = Song::Twin.new(song)


The twin will have configured accessors.


	twin.title #=> "Solitaire"


Writers on the twin do not write to the model.


	twin.title = "Razorblade"
	song.title #=> "Solitaire"


You may pass options into the initializer. These options will override the actual values from the model. As always, this does not write to the model.


	twin = Song::Twin.new(song, title: "Razorblade")
	twin.title #=> "Razorblade"
	song.title #=> "Solitaire"


## Twin::Option

Allows to specify external options.


	class Song < Disposable::Twin
	  property :title
	  option :good?
	end


Options are _not read_ from the model, they have to be passed in the constructor. When omitted, they default to `nil`.


	song = Song.new(model, good?: true)


As always, option properties are readable on the twin.


	song.good? #=> true


When syncing, the option property is treated as not writeable and thus not written to the model.
