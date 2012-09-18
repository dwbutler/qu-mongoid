# Qu-Mongoid
[![Build Status](https://secure.travis-ci.org/dwbutler/qu-mongoid.png)](http://travis-ci.org/dwbutler/qu-mongoid)

This gem provides a Mongoid 3 / Moped backend for the queueing library [Qu](http://github.com/bkeepers/qu). See the documentation for Qu for more information.

## Installation

Add this line to your application's Gemfile:

    gem 'qu'
    gem 'qu-mongoid'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qu-mongoid

## Why not just use the Mongo backend?

Starting with version 3, Mongoid uses its own mongoDB driver (Moped) instead of the official 10gen ruby driver (mongo). To avoid loading both drivers, I ported the Mongo backend to Mongoid/Moped.

Mongoid version 2 and below uses the mongo driver, so use qu-mongo if you are on Mongoid 2.

## Configuration

Qu-Mongoid will automatically connect to the default session configured in mongoid.yml. If a default session is not configured, it will attempt to read from ENV['MONGOHQ_URL'] and ENV['MONGOLAB_URI'], so it should work on Heroku. If you need to use a different Mongoid connection, you can do the following:

``` ruby
Qu.configure do |c|
  c.connection = Mongoid.sessions[:qu]
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
