---
layout: disposable
title: "Disposable API"
---

## Change Tracking

The `Changed` module will allow tracking of state changes in all properties, even nested structures.


	class AlbumTwin < Disposable::Twin
	  feature Changed


Now, consider the following operations.


	twin.name = "Skamobile"
	twin.songs << Song.new("Skate", 2) # this adds second song.


This results in the following tracking results.


	twin.changed?             #=> true
	twin.changed?(:name)      #=> true
	twin.changed?(:playable?) #=> false
	twin.songs.changed?       #=> true
	twin.songs[0].changed?    #=> false
	twin.songs[1].changed?    #=> true


Assignments from the constructor are _not_ tracked as changes.


twin = AlbumTwin.new(album)
twin.changed? #=> false


When used with `Coercion`, note that first coercion happens, then the assignment, then the tracking logic.

That will lead to the following assignment _not_ being marked as change.


	twin.released #=> true
	twin.released = 1
	twin.released #=> true
	twin.changed?(:released) #=> false
