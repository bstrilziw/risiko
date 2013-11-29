require 'data_mapper'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/database.db")

class Account #ermoeglicht einloggen
	include DataMapper::Resource
	property :id, Serial
	property :login_name, String
	property :password, String
	property :name, String
	has n, :countries, 'Country'
	belongs_to :game, :required => false
end

class Country
	include DataMapper::Resource
	property :id, Serial
	property :name, String
	property :unit_count, Integer
	belongs_to :game
	belongs_to :account, :required => false
end

class Game
	include DataMapper::Resource
	property :id, Serial
  has 1, :active_player, 'Account'
	has n, :players, 'Account'
  has n, :countries, 'Country'
end

DataMapper.finalize
DataMapper.auto_migrate!

# Testdatensaetze
game = Game.create()
Account.create(login_name: "admin", password: "1234", name: "ADM1N", game: Game.first)
Country.create(name: "alaska", unit_count: 1, game: game)
Country.create(name: "alberta", unit_count: 1, game: game)