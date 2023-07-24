# GIVING CONNECTION

### Installation

To run this project firstly you will need to install the following,
considering you already have Ruby 3.0.2 and Homebrew installed:

Install postgres
> brew install postgres

Install postgis
> brew install postgis

Install cmake
> brew install cmake

Install hivemind
> brew install hivemind

Install redis
> brew install redis

Install gem bundle
> bundle install

Install webpack
> npm install webpack-dev-server -g

> yarn install

### Credentials

To have access to the credentials you must:
- Add master.key file inside config folder
- Add secret key to the file

### Set-up

To set the project you will need the following commands:

Bundle required gems
> bundle install

Create database
> rails db:create

Migrate database
> rails db:migrate

If your migration fails due to 'type "geography" does not exist' do the following:

Associate postgres database with postgis:

Run postgres:
> psql postgres

Inside of postgres command line:
> \c giving_connection_development;

> CREATE EXTENSION Postgis;

> exit

### Populate database

> rails db:seed

### Run server

> redis-server

> rails s or hivemind
