require 'data_mapper'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/database.db")

class Account
	include DataMapper::Resource
	property :id, Serial
	property :login_name, String
	property :password, String
	property :name, String
	property :mail, String
	has 1, :player
	has 1, :game, :through => :player
end

class Post
	include DataMapper::Resource
	property :id, Serial
	property :text, String
	property :time, DateTime
	belongs_to :writer, 'Account'
end

class Player
	include DataMapper::Resource
	property :id, Serial
	property :is_AI, Boolean, default: false
	has n, :countries, 'Country'
	property :number, Integer
	belongs_to :account, required: false
	belongs_to :game, required: false
	
	def name
		unless account.nil?
			account.name
		else
			"Computer-Gegner"
		end
	end
end

class Country
	include DataMapper::Resource
	property :id, Serial
	property :name, String
	property :unit_count, Integer
	belongs_to :game
	belongs_to :player, required: false
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
	belongs_to :active_player, 'Player', required: false
	has n, :players
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

# Klassen erweiternde Methoden
class Game
	# Konstanten
	NORTH_AMERICA_NAMES = ["alaska","alberta","weststaaten","mittel-amerika",
		"nordwest-territorium","ontario","oststaaten","quebec", "groenland"]
	SOUTH_AMERICA_NAMES = ["venezuela", "peru", "brasilien", "argentinien"]
	AFRICA_NAMES = ["nordwest-afrika","aegypten","ost-afrika","kongo","sued-afrika","madagaskar"]
	EUROPE_NAMES = ["island", "skandinavien", "ukraine", "gross-britannien",
		"mittel-europa", "west-europa", "sued-europa"]
	ASIA_NAMES = ["mittlerer-osten", "afghanistan", "ural", "sibirien", "jakutien",
		"kamtschatka", "irkutsk", "mongolei", "japan", "china", "indien", "siam"]
	OCEANIA_NAMES = ["indonesien", "neu-guinea", "ost-australien", "west-australien"]
	ALL_COUNTRY_NAMES = NORTH_AMERICA_NAMES + SOUTH_AMERICA_NAMES + AFRICA_NAMES +
		EUROPE_NAMES +  ASIA_NAMES+ OCEANIA_NAMES
	
	# pruefen, ob dem aktiven Spieler eine Reihe von Laendern gehoert
	def has_countries? country_names
		country_names.each do |name|
			country = countries.first(name: name)
			if country.player != active_player
				return false
			end
		end
		return true
	end
	
	# pruefen, ob der aktive Spieler alle Laender eingenommen hat
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
		if has_countries? NORTH_AMERICA_NAMES
			self.placeable_units += 5
		end
		# Sued-Amerika
		if has_countries? SOUTH_AMERICA_NAMES
			self.placeable_units += 2
		end
		# Afrika
		if has_countries? AFRICA_NAMES
			self.placeable_units += 3
		end
		# Europa
		if has_countries? EUROPE_NAMES
			self.placeable_units += 5
		end
		# Asien
		if has_countries? ASIA_NAMES
			self.placeable_units += 7
		end
		# Ozeanien
		if has_countries? OCEANIA_NAMES
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

class Player
	def is_active?
		return false if game.nil? || !game.running
		self == game.active_player
	end
	
	def place_units country_name, unit_count = 1
		return false unless is_active?
		return false unless game.placeable_units > 0 && game.placeable_units >= unit_count
		country = game.countries.first(name: country_name)
		return false if country.nil? || country.player != self
		country.update(unit_count: country.unit_count + unit_count)
		game.update(placeable_units: game.placeable_units - unit_count)
		game.set_next_phase if game.placeable_units == 0
		return true
	end
	
	def attack source_name, target_name, unit_count
		return false unless is_active?
		source = game.countries.first(name: source_name)
		return false if source.nil? || source.player != self
		target = game.countries.first(name: target_name)
		return false if target.nil? || target.player == self
		# Nachbarschaft pruefen
		return false if source.neighbors.get(target.id).nil?
		# Einheitenzahl pruefen
		return false unless source.unit_count > 1 && unit_count > 0 && unit_count < source.unit_count
		# Angriff simulieren
		source.update(unit_count: source.unit_count - unit_count)
		unit_count.times do
			if rand(6) > rand(6)
				target.update(unit_count: target.unit_count - 1)
			else
				unit_count -= 1
			end
			if target.unit_count == 0
				target.update(unit_count: unit_count, player: self)
				break
			end
		end
		# pruefen, ob das Spiel vorbei ist
		game.check_if_over
		return true
	end
	
	def transfer source_name, target_name, unit_count
		return false unless is_active?
		source = game.countries.first(name: source_name)
		return false if source.nil? || source.player != self
		target = game.countries.first(name: target_name)
		return false if target.nil? || target.player != self
		# Einheitenzahl pruefen
		return false unless source.unit_count > 1 && unit_count > 0 && unit_count < source.unit_count
		# Verbindung zwischen Source und Target pruefen
		land_verbunden = Hash.new
		# Alle Länder des Spielers ermitteln
		countries.each do |country|
			land_verbunden[country] = country == source
		end
		# Solange iterieren, bis sich nichts mehr veraendert
		change = true
		while change do
			change = false
			land_verbunden.each do |land, verbunden|
				if verbunden
					land.neighbors.each do |neighbor|
						if neighbor.player == self && land_verbunden[neighbor] == false
							change = true
							land_verbunden[neighbor] = true
							break if neighbor == target
						end
					end
				end
			end
		end
		return false unless land_verbunden[target]
		source.update(unit_count: source.unit_count - unit_count)
		return false unless source.saved?
		target.update(unit_count: target.unit_count + unit_count)
		return false unless target.saved?
		game.set_next_phase
		return true
	end
end