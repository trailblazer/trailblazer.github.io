# Font Awesome

Currently, the `bower_components/font-awesome/fonts` is copied over to `/`.


bundle exec jekyll serve -I

# Push to master

Always work on the `f6` branch.

```
rm -rf _site
mkdir _site && cd _site
git init && git remote add origin https://github.com/trailblazer/trailblazer.github.io.git
git pull origin master
```

This will make the `_site` directory reference the `master` branch. Everything you commit in this directory and push will be pushed to master and published instantaneously.
