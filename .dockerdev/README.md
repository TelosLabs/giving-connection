# Docker for Development 🐳 

Source: [Ruby on Whales: Dockerizing Ruby and Rails development](https://evilmartians.com/chronicles/ruby-on-whales-docker-for-ruby-rails-development).

## Installation

- Docker installed.

For MacOS just use the [official app](https://docs.docker.com/engine/installation/mac/).

- [`dip`](https://github.com/bibendi/dip) installed.

You can install `dip` as Ruby gem:

```sh
gem install dip
```

## Setup

1. Build image: `dip build`
2. Install yarn packages: `dip yarn install --ignore-engines`
3. Install gems: `dip bundle install`
4. Create databases: `dip rails db:create` and then `dip rails db:create RAILS_ENV=test`
5. Enable postgis extensions
`dip psql`
When prompted for a password, enter: `postgres`
Once inside the psql console, run
`CREATE EXTENSION postgis;`
`exit`
7. Run `dip rake db:gis:setup`
8. Run migrations: `dip rails db:migrate`
9. Seed db: `dip rails db:seed`
10. Finally, start the container with `dip up`

11. Wait until everything is up and then open a browser in port 3000 


## Developing with Dip

### Useful commands

```sh
# run rails console
dip rails c

# run rails server with debugging capabilities (i.e., `debugger` would work)
dip rails s

# or run the while web app (with all the dependencies)
dip up web

# run migrations
dip rails db:migrate

# pass env variables into application
dip VERSION=20100905201547 rails db:migrate:down

# simply launch bash within app directory (with dependencies up)
dip runner

# execute an arbitrary command via Bash
dip bash -c 'ls -al tmp/cache'

# Additional commands

# update gems or packages
dip bundle install
dip yarn install --ignore-engines

# run psql console
dip psql

# run Redis console
dip redis-cli

# run tests
# TIP: `dip rspec` is already auto prefixed with `RAILS_ENV=test`
dip rspec spec/path/to/single/test.rb:23

# shutdown all containers
dip down
```

### Development flow

Another way is to run `dip <smth>` for every interaction. If you prefer this way and use ZSH, you can reduce the typing
by integrating `dip` into your session:

```sh
$ dip console | source /dev/stdin
# no `dip` prefix is required anymore!
$ rails c
Loading development environment (Rails 7.0.1)
pry>
```
