require 'active_record'

options = {
  adapter: 'postgresql',
  database: 'tv_bumble'
};

ActiveRecord::Base.establish_connection( ENV['DATABASE_URL'] || options)
