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

class Post
	include DataMapper::Resource
	
	property :id, Serial
	property :text, String
	property :time, DateTime
	
	belongs_to :writer, 'Account'
end

class Country
	include DataMapper::Resource
	property :id, Serial
	property :name, String
	property :unit_count, Integer
	belongs_to :game
	belongs_to :account, :required => false
	has n, :neighbors, 'Country', :through => Resource
end

class Game
	include DataMapper::Resource
	property :id, Serial
	property :name, String
	property :placeable_units, Integer, default: 0 # in Phase 0 verfuegbare Einheiten
	property :phase, Integer, default: 0 # 0: Verteilen; 1: Angreifen; 2: Verschieben
	property :running, Boolean, default: false
	property :private, Boolean, default: false
  belongs_to :active_player, 'Account', required: false
	has n, :players, 'Account'
  has n, :countries, 'Country'
end

DataMapper.finalize
DataMapper.auto_migrate!

# Testdatensaetze
Account.create(login_name: "admin", password: "", name: "ADM1N")
Account.create(login_name: "user", password: "", name: "USER")

# DataMapper unabhaengige Methoden
class Game
	# verfuegbare Einheiten berechnen
	def calculate_units
		self.placeable_units = self.active_player.countries.length / 3
		self.placeable_units = 3 if self.placeable_units < 3
	end
	
	# naechsten Spieler aktiv setzen
	def set_next_player_active
		if self.active_player == self.players.last
			self.active_player = self.players.first
		else
			index = self.players.index(self.active_player)
			self.active_player = self.players[index+1]
		end
	end
end