---
layout: disposable
title: "Disposable Default"
gems:
  - ["disposable", "apotonick/disposable"]
---

# Twin: Default

Twins allow default values to be set on the twin. This is provided by the `Default` module.


Default values can be set via `:default`.


    class AlbumTwin < Disposable::Twin
      feature Default

      property :title, default: "The Greatest Songs Ever Written"
      property :composer, default: Composer.new do
        property :name
      end
    end


The default value is applied when the model's getter returns `nil` in `Setup`.

Note that this also works for nested properties.

## Struct Defaults

Defaults also work for `Struct`.


    class AlbumTwin < Disposable::Twin
      feature Default

      property :settings, default: Hash.new do
        include Struct

        property :enabled, default: "yes"
        property :roles, default: Hash.new do
          include Struct
          property :admin, default: "maybe"
        end
      end
    end


You can now access nested hashes even if they were not present initially.


    album = Album.new
    album.settings #=> nil

    twin = AlbumTwin.new(album)
    twin.settings.enabled #=> "yes"
    twin.settings.roles.admin #=> "maybe"


Naturally, this will then write a valid hash back in `sync`.


    twin.sync
    album.settings #=> {"enabled"=>"yes", "roles"=>{"admin"=>"maybe"}}
