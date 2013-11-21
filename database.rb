require 'data_mapper'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/database.db")

class Account #ermöglicht einloggen
	include DataMapper::Resource
	property :id, Serial
	property :login_name, String
	property :password, String
	has 1, :player
end

class Player
	include DataMapper::Resource
	property :id, Serial
	property :name, String
	has n, :fields
  belongs_to :account
	belongs_to :game, :required => false
end

class Field
	include DataMapper::Resource
	property :id, Serial
	property :name, String
	property :unit_count, Integer
	belongs_to :game
	belongs_to :player, :required => false
end

class Game
	include DataMapper::Resource
	property :id, Serial
	has n, :players, :required => false
	has n, :fields, :required => true
end

DataMapper.finalize
DataMapper.auto_upgrade!