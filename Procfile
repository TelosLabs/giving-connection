web:    bundle exec puma -C config/puma.rb
assets: yarn build && yarn build:css
worker: bundle exec sidekiq
clock:  bundle exec clockwork config/clock.rb