#!/bin/sh

touch source/stylesheets/tailwind.css

bundle install
bundle exec middleman build
