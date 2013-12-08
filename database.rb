require 'data_mapper'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/database.db")

class Account
	include DataMapper::Resource
	property :id, Serial
	property :login_name, String
	property :password, String
	property :name, String
	has n, :countries, 'Country'
	belongs_to :game, :required => false # -> game.players
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
	property :name, String
	property :placeable_units, Integer, default: 0 # in Phase 0 verfuegbare Einheiten (berechnet in /update/phase)
	property :phase, Integer, default: 0 # 0: Verteilen; 1: Angreifen; 2: Verschieben;
	property :running, Boolean, default: false
	property :private, Boolean, default: false
  belongs_to :active_player, 'Account', required: false
	has n, :players, 'Account'
  has n, :countries, 'Country'
end

DataMapper.finalize
DataMapper.auto_migrate!

# Testdatensaetze
Account.create(login_name: "admin", password: "1234", name: "ADM1N")