---
layout: default
---

# Trailblazer Installation

The obvious needs to be in your `Gemfile`.

```ruby
gem "trailblazer"
gem "cells"
```

Cells is _not_ required per default! Add it if you use it, which is highly recommended.

This is, in case you want to use `ViewModel`s.

# Rails Setup

1. The railtie needs to get loaded at the bottom of `config/application.rb`.

    ```ruby
    require "trailblazer/rails/railtie"
    ```

    Otherwise, autoloading for operations won't work properly.

2. Fix from here: https://github.com/apotonick/gemgem-trbrb/blob/88dabcdbe9b75d2408e934093d945ad1732cd2f1/config/initializers/trailblazer.rb#L27

3. Include Controller: https://github.com/apotonick/gemgem-trbrb/blob/master/app/controllers/application_controller.rb#L6