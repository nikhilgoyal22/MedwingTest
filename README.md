# README

* System dependencies
   * redis

* Configuration
  * `bundle install`
  * change `database.yml` for your credentials

* Database creation & initialization
  * `rails db:create db:migrate db:seed`

* Deployment instructions
  * `redis-server`
  * `bundle exec sidekiq`
  * `rails s`

* How to run the test suite
  * `rspec`
