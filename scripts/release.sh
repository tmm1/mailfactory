#!/bin/sh

# destroy old docs and gems
rm -rf ./doc
rm -f mailfactory-*.gem

# build the gem
ruby mailfactory.gemspec

# build the docs
rdoc ./lib/mailfactory.rb

# upload the docs

