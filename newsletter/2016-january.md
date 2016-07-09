---
layout: newsletter
description: "January 2016 newsletter talks about Formular (new form builder for Ruby), dry-validation in Reform, Sinatra/TRB, cool but unknown features in Reform and upcoming talks in Europe and Australia."

title: "Newsletter January 2016"
---

# January 2016

Dear Readers of this newsletter,
Hello, and Hi from the Trailblazer team!

Thank you for your interest in the Trailblazer project. We hope your new year 2016 started off great and you're already working on fantastic new software!

The Trailblazer newsletter is going to be a monthly buzz telling you what has changed in the Trailblazer gems, Cells, Reform, Roar and Representable, and Formular, what new features have been released and cool upcoming stuff to expect.

This is newsletter no. 1, the first ever, and I'm excited to tell you what has happened the last few months!

### Formular - A New Form Builder for Ruby

One of the coolest projects we've been working on the last weeks is the [Formular gem](https://github.com/apotonick/formular), a new form rendering gem like SimpleForm, but, as opposed to many other form builders out there, completely framework-agnostic.

Formular is built without using any outdated Rails helpers, making it insanely fast and usable in many frameworks, namely Rails, Hanami, or Sinatra. Its API is following the best practices established by existing form builders, without inheriting all the problems originating from strong coupling.

```ruby
= form(model.contract, url) do |f|
  = f.input :url_slug, placeholder: "URL slug"
  .form-group
    = f.checkbox :is_public, label: "Public?"
  .form-group
    = f.radio :owner, label: "Flori", value: 1
    = f.radio :owner, label: "Konsti", value: 2
```

It ships with extensions for Foundation 5 and Bootstrap 3. Again, the implementational approach here is different. Instead of configuring, Formular gets extended [with plain Ruby classes](https://github.com/apotonick/formular/blob/210461c543c63634ddeb69b2db9c326cd0c920da/lib/formular/frontend/bootstrap3.rb). It is incredibly simple to add new frontends or extend existing behavior.

Formular will be released soon after a beta-test phase. Please contact us on our [Gitter channel](http://gitter.im/trailblazer/chat) if you're interested in giving Formular a go!

### Dry-Validation and Reform

The [Reform gem](https://github.com/apotonick/reform) is gaining more and more popularity and is a essential building block in Trailblazer. Its basic validation implementation comes from `ActiveModel::Validations`. While this makes the transition from model validations to form ojects very straight-forward, it brings a lot of legacy problems into Reform.

To keep moving forward, we integrated the excellent [Dry-Validation](https://github.com/dryrb/dry-validation) gem into Reform, allowing to use this brand-new validation gem as a replacement for ActiveModel.

```ruby
class Post::Form < Reform::Form
  property :title
  property :url_slug

  include Reform::Form::Dry::Validations

  validation :default do
    key(:title, &:filled?)
    key(:url_slug) { |slug| slug.format?(/^[\w-]+$/) & slug.unique? }
    key(:content) { |content| content.max_size?(10000) }

    def unique?(value)
      form.model.class[url_slug: value].nil?
    end
  end
end
```

You can now use Dry-Validation's predicate logic to write your validation code, which is richer and makes it easier to write complex validations and dependent rules.

While there's still moving parts, several companies switched to this validation engine, already, and they're very happy with it. Another nicety is that you now can use Reform in other Ruby frameworks like Sinatra without any `Active*` Rails gem dependencies.

Wanna see that in action? Check out the [Gemgem-Sinatra example application](https://github.com/apotonick/gemgem-sinatra/blob/1cfc38533e3cbf7be380d7afacd6c5580cb18614/concepts/post/operation/create.rb#L11)!

### Sinatra and Trailblazer

A project that was a pleasure to work on is the new [Gemgem-Sinatra example ](https://github.com/apotonick/gemgem-sinatra) app - both because it shows how cool Trailblazer works with frameworks other than Rails, and also because it is *insanely fast*.

```ruby
├── app.rb
├── concepts
│   └── post
│       ├── cell
│       │   ├── new.rb
│       │   └── show.rb
│       ├── operation
│       │   ├── create.rb
│       │   └── update.rb
│       └── view
│           ├── new.slim
│           └── show.slim
├── config
│   ├── init.rb
│   └── migrations.rb
├── Gemfile
├── Gemfile.lock
├── models
│   └── post.rb
```

We basically rebuild the Gemgem project from the Trailblazer book, using Sequel as a replacement for ActiveRecord and Sinatra as the underlying infrastructure framework.

In the course of working on this project, I seriously started questioning myself why I'd ever use Rails again. Definitely check it out, Sinatra (or Padrino) with Trailblazer is extremely cool!

### Arbitrary Options for Reform

Did you know that you can inject arbitrary objects besides the model into a Reform form instance? This is super helpful when you need dependencies other than your model's attributes, e.g. the current user.

Simply pass the additional objects in a hash via the constructor.

```ruby
Form.new(post, current_user: current_user)
```

To make Reform understand that this is a dependency, you have to define a virtual property, too!

```ruby
class Post::Form < Reform::Form
  property :title                       # from model
  property :url_slug                    # from model
  property :current_user, virtual: true # via constructor
```

You can now access the current user in validations or other accessors.

```ruby
class Post::Form < Reform::Form
  validates do
    errors.add(:auth, "no current user") if current_user.nil?
  end
```

As most of Reform is implemented via Disposable's Twin, you can find the logic that gives you the described _options semantic_ [in the Disposable gem](https://github.com/apotonick/disposable/blob/3270bd16b0105cc48eb5c414f94b0003e04e78ac/lib/disposable/twin/setup.rb#L27).

### Accessing the Parent Form

Another addition to Disposable is the new `Parent` module, which allows accessing the parent form in a Reform instance. This is necessary when you have nested forms that need dependencies from an upper form, for instance a nested comment validation requiring the parent post's ID.

Simply require and include the `Parent` extension in your form.

```ruby
require "disposable/twin/parent"

class Post::Form < Reform::Form
  feature Disposable::Twin::Parent
```

You can then use the parent form in nested instances.

```ruby
  property :comment do
    property :body

    validates do
      if parent.model.id > 0 ...
      # ..
    end
  end
```

A very helpful new addition that many users have asked for. Well, here it is!

### Trailblazer Book and Trailblazer Primer

The [Trailblazer book](http://trailblazer.to/books/trailblazer) was published a few months ago, without any noteable marketing it has already attracted more than 600 readers. If you don't have it yet, [grab it now and get a $10 discount](http://leanpub.com/trailblazer/c/EPIgtwW2WG0z) until Feb 4!

It will teach you everything about engineering complex Rails applications with Trailblazer from authorization, validations, operations and persistence to hypermedia API parsing and rendering.

While this book focuses on a Rails scenario, it can easily be adapted to other frameworks.

Many future users have asked for a "quicker, more compressed" way to see Trailblazer in action. While they appreciate the details of discussion in the Trailblazer book, most users want to start programming and learn about it later, which is why I will soon start writing the [Trailblazer Primer](http://trailblazer.to/books/trailblazer-primer), a very brief HOWTO about adding Trailblazer to existing applications without in-depth explanations.

### Cells and Hamlit

[Hamlit](https://github.com/k0kubun/hamlit) is a super fast implementation of Haml written by Takashi Kokubun.

I [blogged about the Cells integration](http://nicksda.apotomo.de/2016/01/cells-hamlit-the-fastest-view-engine-around/) a few days ago and show how Cells and Hamlit speed up rendering dramatically and wins over Slim and Haml.

Many thanks go out to Takashi for all the support and help when integrating the two projects.

### Next Newsletter + Talks

The next newsletter will be out in late February or early March, where I hopefully have some good stories about TRB talks I'll be giving in Europe in February.

* Feb 17: [cologne.rb](http://www.colognerb.de/) Köln, Germany
* Feb 23: [BRUG](http://www.meetup.com/brug__/events/228240599/) Brussels, Belgium
* Feb 25: [groningen.rb](http://www.meetup.com/groningen-rb/) Groningen, Netherlands

Also, if you happen to come to [RubyConf Australia](http://rubyconf.org.au/2016) Febuary 10-13 - which you totally should!!! - there will be a [one-day TRB workshop](http://lanyrd.com/2016/rubyconf-au/sdxmxp/) with Nick Kirkwood and myself!

It would be great to see you in February! Cheers!
