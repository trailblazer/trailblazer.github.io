# Trailblazer Documentation

## Install

Make sure you have [bundle](http://bundler.io/) and [node](https://nodejs.org/en/) installed in your machine and:

```
mkdir trailblazer-docs
cd trailblazer-docs
git clone git@github.com:trailblazer/trailblazer.github.io.git
cd trailblazer.github.io/
git checkout f6
bundle
npm install
./setup.sh
rm -rf _site
mkdir _site && cd _site
git init && git remote add origin https://github.com/trailblazer/trailblazer.github.io.git
git pull origin master
cd ..
```

A folder will be created and several Trailblazer repos will be pulled. Their code is used to populate the documentation directly. Magic!


## Serve

After installation, run:

```
bundle exec jekyll serve -I
```

Go to `http://127.0.0.1:4000` and you should see the project running.

In the off chance you stumble upon an empty site, repeat these steps on the project root:

```
git checkout f6
rm -rf _site
mkdir _site && cd _site
git init && git remote add origin https://github.com/trailblazer/trailblazer.github.io.git
git pull origin master
cd ..
```

And try to run the [Jekyll](https://jekyllrb.com/) server again


## Contribute

In the previous steps outlining installation, replace `git@github.com:trailblazer/trailblazer.github.io.git` with the git address of your fork, so you can push your changes to your own fork so you can [pull request](https://help.github.com/articles/creating-a-pull-request/).

Always work on the `f6` branch.

```
rm -rf _site
mkdir _site && cd _site
git init && git remote add origin https://github.com/trailblazer/trailblazer.github.io.git
git pull origin master
```

This will make the `_site` directory reference the `master` branch. Everything you commit in this directory and push will be pushed to master and published instantaneously.
