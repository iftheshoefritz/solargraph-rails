#!/bin/bash
set -e
RVM_PATH=/usr/local/rvm
ARGS=("$@")

if [[ ! -d $RVM_PATH ]]; then
  curl -sSL https://get.rvm.io | bash
fi

source /etc/profile.d/rvm.sh

rvm install ruby $ARGS
rvm use $ARGS
gem install bundler

(cd spec/rails5; bundle install; yard gems)
(cd spec/rails6; bundle install; yard gems)
(cd spec/rails7; bundle install; yard gems)

bundle install
bundle exec rspec
