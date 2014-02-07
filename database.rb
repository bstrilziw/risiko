require 'data_mapper'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/database.db")

class Account
	include DataMapper::Resource
	property :id, Serial
	property :login_name, String
	property :password, String
	property :name, String
	property :mail, String
	property :number, Integer
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
	property :maximum_players, Integer, default: 6
  belongs_to :active_player, 'Account', required: false
	has n, :players, 'Account'
  has n, :countries, 'Country'
end

DataMapper.finalize
DataMapper.auto_migrate!

# Testdatensaetze
Account.create(login_name: "admin", password: "da39a3ee5e6b4b0d3255bfef95601890afd80709", mail: "admin@internerz.de", name: "ADM1N")
Account.create(login_name: "user", password: "da39a3ee5e6b4b0d3255bfef95601890afd80709", mail: "user@internerz.de", name: "USER")

# DataMapper unabhaengige Methoden
class Game
	# verfuegbare Einheiten berechnen
	def calculate_units
		self.placeable_units = self.active_player.countries.length / 3
		self.placeable_units = 3 if self.placeable_units < 3
		self.save
	end
	
	# naechsten Spieler aktiv setzen
	def set_next_player_active
		if self.active_player.number == self.players.length
			self.active_player = self.players(order: [:number.asc]).first
		else
			self.active_player = self.players(order: [:number.asc])[self.active_player.number]
		end
		self.save
	end
	
	# zur naechsten Phase wechseln
	def set_next_phase
			self.phase += 1
		if self.phase == 3
			self.phase = 0
			# naechsten Spieler waehlen
			self.set_next_player_active
		end
		if self.phase == 0
			# verfuegbare Einheiten berechnen
			self.calculate_units
		end
		self.save
	end
end