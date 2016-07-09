---
layout: newsletter
description: "March 2016 newsletter talks about coercion in Reform using Dry-Types, the nilify feature, compositional aspects in operations and presentations in Europe in Feburary."

title: "Newsletter March 2016"
---

# March 2016

Greetings, fellow Trailblazers!

It's been nearly two months since the last newsletter! My apologies, but I was busy traveling in Europe, seeing family and many friends, and giving some Trailblazer presentations. I am back in Australia now and the Github repositories are smoking, again!

## Trailblazer on Facebook

Yes, even though I refuse to use higher technology, I love Facebook! Only just now I created a Facebook page for Trailblazer. We will post upcoming event notifications such as talks and workshops, funny photos, and more entertaining content. Please ["like" us](https://facebook.com/trbinc)!

## RCAU16

<div style="margin-bottom: 160px;">
<div style="float:left; width: 200px;">
<img src="https://scontent-syd1-1.xx.fbcdn.net/hphotos-xtf1/v/t1.0-9/12931127_1123064391061744_8244347931411963903_n.jpg?oh=27a00170285bf4cb008dd55e431aff7c&oe=57985FBE" width="160">

The main organizer - a man with a vision.
</div>

<p>
I've had a fantastic time giving a full-day Trailblazer workshop at RubyConf Australia 2016. In a room with 15 highly motivated Rubyists, we managed to implement a shopping cart application. As we all found the <a href="https://github.com/apotonick/trb-cart">cart example</a> a very understandable way to show all the goodies in TRB, I am considering using it for the upcoming Trailblazer Primer book.
</p>

  <p>
The conference itself was amazing and I think everybody really enjoyed the talks, the fantastic Aussie Weather™, the snacks, great food and the afterparties! Much love!
</p>

</div>

<div />

## Europe Talks

On my Europe trip in February, I got invited to a handful of Ruby meetups where I had the honour to present Trailblazer. Those talks went really well, and I was very happy about many people showing up. Meetups took place in Cologne, Brussels, Groningen (a beautiful small city in the north of the Netherlands) and Berlin.

A incredibly big *Thank You!* to the organizers of the meetups, I felt very welcome and always enjoyed the delicious beers afterwards!

<img src="https://fbcdn-sphotos-e-a.akamaihd.net/hphotos-ak-xaf1/t31.0-8/12891790_1120902187944631_1061140847022920590_o.jpg" width="600">


## Coercion in Reform with Dry-Types

With the deprecation of the Virtus gem, we now use the excellent [dry-types](https://github.com/dry-rb/dry-types) gem for coercion in Disposable and Reform. The API has changed slightly, as Dry-types has new type constants.

```ruby
class AlbumForm < Reform::Form
  feature Coercion

  property :id, type: Types::Form::Int
end
```

Simple, isn't it?


The `:type` option will instruct Reform to override the `#id=` setter and coerce the value to integer.

```ruby
form.id = "1"
form.id #=> 1
```

The coercion semantics are explained in the brand-new [Disposable API docs](http://trailblazer.to/gems/disposable/api.html).

Thanks to Ralf Schmitz Bongiolo and Piotr Solnica for their fantastic work on that.

## Nilify for Reform

A long-awaited feature is the "nilify" coercion. It finally is implemented in Disposable 0.3.0 using Dry-types.

The `:nilify` option will coerce blank strings into `nil`, saving you from annoying persistence layer errors when your ORM tries to save blank strings to associations, and so on.

```ruby
property :id, nilify: true
```

```ruby
form.id = ""
form.id #=> nil
```

The nilify feature also works in combination with other coercion types!

## Compositional Contracts in Trailblazer

With the upcoming Trailblazer 1.2, it is now easily possible to maintain contracts using the `Composition` feature, and to inject additional options. This either works by overriding `Operation#contract!` or by using `#contract` directly in the operation.

```ruby
class Create < Trailblazer::Operation
  model Song

  contract do
    include Reform::Form::Composition

    property :id,         on: :song
    property :album_name, on: :album
  end

  def process(params)
    contract(song: model, album: model.album)

    validate do
      # ..
    end
  end
```

The `contract` method now memoizes its return value (but only if desired) and provides an easy way for more complex contract setup. Note that you can also override `#contract!`. We're hoping this will help developers to leverage the compositional features of Disposable/Reform better.

## Separate Representers For Operation

So far, when using the `Representer` feature in an operation, the same representer was used for parsing input and rendering the response document.

This is now separated - you can either include `Representer` and get the old behavior, or only include either `Representer::Rendering` to use the representer for serialization, or include `Representer::Deserializer` to parse incoming data using the representer.

The details are documented in [our documentation](http://trailblazer.to/gems/operation/representer.html#input-and-output-representers).

Going further, in Trailblazer 1.2, you will be able to specify an arbitrary number of representers using aliases, the same way we already do it with callback objects.

```ruby
class Create < Trailblazer::Operation
  include Representer

  representer :parser do
    property :id
  end

  representer :renderer, Renderer::Create
```

As many users have asked for separation of input and output representers, we decided to ship it in Trailblazer 1.2

## Inheritance Fix in Reform/Disposable

An annoying problem that occured with Reform 2.1 was that when inheriting forms, custom accessors were reset and had to be redefined. This is fixed with Disposable 0.2.6. The problem was actually located in the [Declarative](https://github.com/apotonick/declarative) gem that provides DSL and inheritance mechanics to all TRB gems.

Another related bug was fixed in Reform. When using `Form::Module`, accessors were overridden, too. You now have to put custom accessors into the `InstanceMethods` module and everything will work as expected.

```ruby
module SongForm
  include Reform::Form::Module

  property :title

  module InstanceMethods
    def title=(v)
      super(v.trim)
    end
  end
end
```

The complete documentation can be found [here](http://trailblazer.to/gems/reform/api.html#forms-in-modules). If you're still experiencing problems (I'm pretty sure everything is fixed, though), let us know!

## See you soon!

That is it for March, I am looking forward to see you soon with exciting news about the growing Trailblazer ecosystem. Cheers!
