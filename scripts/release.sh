#!/bin/sh

# destroy old docs and gems
rm -rf ./doc
rm -f mailfactory-*.gem

# build the gem
ruby ./scripts/mailfactory.gemspec

