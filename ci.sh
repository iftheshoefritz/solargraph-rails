#!/bin/bash
set -e
# when running in github actions:
RVM_PATH=/home/runner/.rvm
# when running locally using act:
#RVM_PATH=/usr/local/rvm
MATRIX_RUBY_VERSION=$1
MATRIX_SOLARGRAPH_VERSION=$2

if [[ ! -d $RVM_PATH ]]; then
  # this fetches the develop version; using -s stable should fetch the latest stable, but has a gpg error:
  curl -sSL https://get.rvm.io | bash -s
fi

# when running in github actions:
source /home/runner/.rvm/scripts/rvm
# when running locally in Act container:
#source /usr/local/rvm/scripts/rvm


#rvm package install openssl # hack because ubuntu won't give us openSSL
rvm install ruby $MATRIX_RUBY_VERSION
rvm use $MATRIX_RUBY_VERSION
gem install bundler

echo "s/gem 'solargraph'/gem 'solargraph', '${MATRIX_SOLARGRAPH_VERSION}'/" > command.sed

(cd spec/rails5; sed -i -f ../../command.sed Gemfile; cat Gemfile; bundle install; yard gems)
(cd spec/rails6; sed -i -f ../../command.sed Gemfile; cat Gemfile; bundle install; yard gems)
(cd spec/rails7; sed -i -f ../../command.sed Gemfile; cat Gemfile; bundle install; yard gems)

bundle install

bundle exec rspec
