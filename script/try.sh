#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

check_preconditions() {
  if [ -z "$(command -v ruby)" ]; then
    echo "Ruby not found. Please install it: https://www.ruby-lang.org/en/documentation/installation/"
    exit 1
  fi

  if [ -z "$(command -v bundler)" ]; then
    echo "Bundler not found. Please install it: gem install bundler"
    exit 1
  fi

  if [ -z "$(command -v git)" ]; then
    echo "Git not found. Please install it: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git"
    exit 1
  fi

  if [ -z "$(command -v heroku)" ]; then
    echo "Heroku CLI not found. Please install it: https://devcenter.heroku.com/articles/heroku-cli"
    exit 1
  fi
}

install_hanami() {
  gem install hanami
}

generate_project() {
  hanami new bookshelf --database=postgresql
  cd bookshelf && bundle
  git add . && git commit -m "Initial commit"
}

deploy() {
  heroku apps:create
  heroku config:add SERVE_STATIC_ASSETS=true

  git push heroku master

  heroku run bundle exec hanami db migrate

  heroku open
}

main() {
  check_preconditions &&
    install_hanami &&
    generate_project &&
    deploy
}

main



