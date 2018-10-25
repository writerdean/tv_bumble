class User < ActiveRecord::Base
has_secure_password
has_many :shows
has_many :watches


end

