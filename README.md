# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

This application is a curation_concerns application, using dlibhydra models and behaviours.

The following work has been done


add dlibhydra and curation_concerns to Gemfile

gem 'dlibhydra', path: "~/Dropbox/code/rails/dlibhydra" #git: 'https://github.com/digital-york/dlibhydra.git'
gem 'curation_concerns'

run generators:
rails generate curation_concerns:install
rails generate qa:install
rails generate dlibhydra:auths -f
rails generate curation_concerns:work Thesis

To use the app, do
bundle install
rake db:migrate

edit the following with your local config:
config/fedora.yml
config/solr.yml
config/blacklight.yml

To do

investigate workflows:
https://github.com/projecthydra/curation_concerns/wiki/Defining-a-Workflow
investigate admin dashboard: 
https://github.com/projecthydra/curation_concerns/wiki/Admin-Menu-for-apps-based-on-Curation-Concerns


