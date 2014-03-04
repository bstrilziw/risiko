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
	property :is_over, Boolean, default: false
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
Account.create(login_name: "benjamin", password: "da39a3ee5e6b4b0d3255bfef95601890afd80709", mail: "user@internerz.de", name: "BENNI")
Account.create(login_name: "bjoern", password: "da39a3ee5e6b4b0d3255bfef95601890afd80709", mail: "bjoern@internerz.de", name: "BJOERN")
Account.create(login_name: "hendrik", password: "da39a3ee5e6b4b0d3255bfef95601890afd80709", mail: "hendrik@internerz.de", name: "HENDRIK")
Account.create(login_name: "timo", password: "da39a3ee5e6b4b0d3255bfef95601890afd80709", mail: "timo@internerz.de", name: "TIMO")
Account.create(login_name: "tobias", password: "da39a3ee5e6b4b0d3255bfef95601890afd80709", mail: "tobias@internerz.de", name: "TOBI")
Account.create(login_name: "user", password: "da39a3ee5e6b4b0d3255bfef95601890afd80709", mail: "user@internerz.de", name: "USER")

# DataMapper unabhaengige Methoden
class Game
	# pruefen, ob dem aktiven Spieler eine Reihe von Laendern gehoert
	def has_countries? country_names
		country_names.each do |name|
			country = self.countries.first(name: name)
			if country.account != active_player
				return false
			end
		end
		return true
	end
	
	# pruefen, ob der aktive Spieler die gesamte map eingenommen hat
	def has_all_countries?
		return active_player.countries.length == 42
	end
	
	# prueft, ob das Spiel vorbei ist
	def check_if_over
		if has_all_countries? || players.length < 2
			self.is_over = true
			self.save
		end
	end
	
	# verfuegbare Einheiten berechnen
	def calculate_units
		self.placeable_units = self.active_player.countries.length / 3
		self.placeable_units = 3 if self.placeable_units < 3
		# Kontinent-Boni		
		# Nord-Amerika
		if has_countries? ["alaska","alberta","weststaaten","mittel-amerika",
				"nordwest-territorium","ontario","oststaaten","quebec", "groenland"]
			self.placeable_units += 5
		end
		# Sued-Amerika
		if has_countries? ["venezuela", "peru", "brasilien", "argentinien"]
			self.placeable_units += 2
		end
		# Afrika
		if has_countries? ["nordwest-afrika","aegypten","ost-afrika","kongo","sued-afrika","madagaskar"]
			self.placeable_units += 3
		end
		# Europa
		if has_countries? ["island", "skandinavien", "ukraine", "gross-britannien",
				"mittel-europa", "west-europa", "sued-europa"]
			self.placeable_units += 5
		end
		# Asien
		if has_countries? ["mittlerer-osten", "afghanistan", "ural", "sibirien", "jakutien",
				"kamtschatka", "irkutsk", "mongolei", "japan", "china", "indien", "siam"]
			self.placeable_units += 7
		end
		# Ozeanien
		if has_countries? ["indonesien", "neu-guinea", "ost-australien", "west-australien"]
			self.placeable_units += 2
		end
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