# Giving Connection

Connecting nonprofits with communities in Nashville and Atlantic City (for now!).

### Stack
- Ruby on Rails 6.1.x
- Ruby 3.1.x
- Postgres and Postgis
- Hotwire
- Tailwind CSS
- jsbundling and cssbundling

### Installation

1. Requirements
- Bundler (`gem install bundler`)
- Redis
- cmake

2. Clone the repository: `git clone xxxx`
3. Run `bin/setup`

### Setup
1. Create database: `rails db:create`
2. Associate postgres database with postgis:
  - Run postgres: `psql -d giving_connection_development`
  - Inside of postgres command line, run 
  ```
  CREATE EXTENSION IF NOT EXISTS postgis;
  exit
  ```
  - Run `rake db:gis:setup`
3. Start redis with `redis-server`
4. Run `rails db:migrate` and `rails db:seed`
5. Copy the content of `.env.template` to a new file `.env`
6. Run `bin/dev` to start the server
7. Visit `localhost:3000` in your browser

For running the app with Docker, check out the [Docker README](.dockerdev/README.md)

### Contributing

1. Fork the repository
2. Create a new branch
3. Make your changes
4. Push your changes to your fork
5. Create a pull request

#### Linting and Formatting

We use Standard Ruby for linting and formatting.

Run `bundle exec rubocop` to check all ruby files
Run `bundle exec rubocop -a` to auto-correct offenses

### Testing 
Run tests with `bundle exec rspec`

#### System specs

- Headless is the default config. If you want to see the browser you can run the following command: `HEADLESS=false bundle exec rspec`
- If you want to pause the execution you can use `pause` inside an `it` statement.
- If you want to see the logs you can use `:log`, e.g. `it "xxx", :log do`