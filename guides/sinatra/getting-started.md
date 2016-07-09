---
layout: guide
title: "Getting Started with Sinatra and Trailblazer"
---

# Getting Started with Sinatra and Trailblazer

A common misunderstanding is that Trailblazer only works with Rails. This would defeat its philosophy: by decoupling the business logic from the framework, you make it run just anywhere.

This simple example will show you how to write a CRUD interface to create a blog post in a Sinatra environment. We use Sequel as ORM, Trailblazer, and dry-validations for the contract.

The sample application can be found [on Github](https://github.com/apotonick/gemgem-sinatra).

Note that this blog post currently only discusses the very simple CRUD aspects of Trailblazer. We will add more chapters as necessary.

## Namespaces

Trailblazer makes extensive use of Ruby's namespaces - a learning from Rails verbose naming madness.

For example, a creating operation for a `Post` model could be called `Post::Create`. Likewise, a cell to render the post's `show` page could be `Post::Cell::Show`, an updating contract `Post::Contract::Update`, and so on.

## File Structure

Many frameworks use a file structure by technology: views, models, and so on, are structured in what they do. In Trailblazer, files are grouped by what they are, what concept they represent.

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

Files that implement the same group of functions sit in the same directory. This file structure is well-accepted and appreciateed as being more intuitive.

## Support

Let's jump into some very brief code samples now. You will have many questions, most of them we might be able to answer on our [Gitter channel](http://gitter.im/trailblazer/chat). However, you might also consider buying the [Trailblazer book](/books/trailblazer.html). Even though it is written with a Rails example, the generic concepts are well-explained and might help you even better.

## Creating Post: Form View

In order to allow users to create a new blog post, we need a form.

I use a cell and a slim view, instead of Sinatra's built-in rendering stack. Cells is a very popular view model gem from the Rails eco-system, but it is completely decoupled from Rails. It allows ERB, haml and slim templates.

Here's the view in `concepts/post/view/new.slim`.

    h1 New Post!

    form action="#{url}" method="post"
      .row
        input type="text" name="title" placeholder="Title"
      .row
        input type="text" name="url_slug" placeholder="URL slug"
      .row
        textarea name="content" placeholder="And your story..."
      .row
        input type="submit"

A very straight-forward form in [my favourite template language](http://slim-lang.com/). Note that this doesn't use a form builder, yet, and also does not reference any model.

However, we do use a method `url` in this template that comes from the cell (line 3).

## Creating Post: Form Controller

To render this template, we need to invoke the cell in a Sinatra endpoint in `app.rb`.

    get "/posts/new" do
      Post::Cell::New.(nil, url: "/posts").()
    end

I invoke a cell called `Post::Cell::New` and pass in a `:url` key.

The cell is implemented in a class and resides in `concepts/post/cell/new.rb`.

    module Post::Cell
      class New < Trailblazer::Cell
        def url
          options[:url] || raise("no action URL!")
        end
      end
    end

Here, I implement the `url` method that is used in the view and this is how the actual form's `action` URL finds its way into the rendered view.

Cells in Trailblazer sit in the concept's `Cell` namespace, which is why this particular cells name is `Post::Cell::New`.

You can now browse to [http://localhost:4567/posts/new](http://localhost:4567/posts/new) and you will see the rendered form. Cells are lightning fast and will perform much faster than you might be used from Rails or even from Sinatra.

## Creating Post: Processing Controller

When submitting, this form will be POSTed to `/posts`. We need to add a route for this in `app.rb`.

    post "/posts" do
      op = Post::Create.run(params) do |op|
        redirect "/posts/#{op.model.id}"
      end

      Post::Cell::New.(op, url: "/posts").()
    end

First, I invoke the `Post::Create` operation that processes the incoming form data. Note how I call `run` and pass in the `params` hash. The block is only invoked when the operation was successful and will redirect to the newly created post's show page.

If not, the remaining block is executed and will re-render the form cell. Note that I pass in the operation instance into the cell.

## Creating Post: Operation

The processing operation is implemented in `concepts/post/operation/create.rb`.

    class Post::Create < Trailblazer::Operation
      contract do
        property :title
        property :url_slug
        property :content
      end

      def model!(*)
        Post.new
      end

      def process(params)
        validate(params) do
          contract.save
        end
      end
    end

An operation always has a contract, which is a `Reform::Form` object. We could easily extract this contract to a separate file `concepts/post/contract/create.rb`, but for now, it is perfectly fine inline in the operation.

A contract defines fields and validations. We'll learn about validations soon enough.

The operation can create or find arbitrary models in its `model!` method. As you can see, this is absolutely not limited to ActiveRecord but can be anything you want.

In the `process` method, the incoming `params` then get validated by the form, values get assigned to the contract object, and then, you can do with that whatever you want.

When validating, no data is written to the model. This is all working on the intermediate form twin. Only when you call `contract.save` will data be pushed to the model and saved.

## Creating Post: Validation

Let's add some validations to the contract now. Again, please be aware that in Trailblazer, validations are considered business logic and do not go into the model.

Here's how the model looks like, in `models/post.rb`.

    class Post < Sequel::Model
    end

Validations go into the contract in `concepts/post/operation/create.rb`.

    class Post::Create < Trailblazer::Operation
      contract do
        property :title
        property :url_slug
        property :content

        validation do
          key(:title, &:filled?)
          key(:url_slug) { |slug| slug.format?(/^[\w-]+$/) && slug.unique? }

          def unique?(value)
            Post[url_slug: value].nil?
          end
        end
      end

Contracts in Trailblazer are Reform objects. Reform allows various validation backends, including the awesome [dry-validation](https://github.com/dryrb/dry-validation), which we use in this application.

I check if the `title` field is filled out, and if the `url_slug` has a URL-valid format. Also, I add a simple uniqueness validation. Note how I use Sequel's API to perform real SQL queries in a validator.

## Creating Post: Workflow

When submitting an empty form, we can see the erroring form. It contains the invalid data, but we can't see errors. Let's quickly add that to the cell view in `concepts/post/view/new.slim`.

    h1 New Post!

    = model.contract.errors.messages.inspect
    form action="#{url}" method="post"
      # ..

Since we pass the operation instance to the cell in the `POST /posts/` endpoint, we can access this object using the cell's generic `model` reader. The operation keeps the contract instance, and so on, enough to display an error message telling the user what went wrong.

Once the form is correctly filled out and submitted, we get redirected to `/posts/1`.

## Viewing Post: Controller

This needs a new endpoint in `app.rb`.

    get "/posts/:id" do
      op = Post::Update.present(params)

      Post::Cell::Show.(op.model, url: "/posts").()
    end
