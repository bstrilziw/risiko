get '/list' do
	redirect '/' unless logged_in?
	@games = Game.all(running: false, private: false) # hier pruefen ob das Spiel bereits laeuft
	slim :game_list
end

get '/lobby' do
	redirect '/login' unless logged_in?
	account = get_account
	redirect '/list' if account.game.nil?
	redirect '/game' if account.game.running
	
	@players = account.game.players(order: [:number.asc])
	@is_host = account.player == @players.first
	slim :lobby
end

get '/updatePlayerList' do
	halt 500, "no access" unless logged_in?
	game = get_game
	
	players = Array.new
	game.players(order: [:number.asc]).each do |player|
		players << player.name
	end
	{game_started: game.running, players: players}.to_json
end

get '/game' do
	redirect '/login' unless logged_in?
	account = get_account
	redirect '/list' if account.game.nil?
	redirect '/lobby' unless account.game.running
	
	laender = account.game.countries
	# TODO DRY?!
	alaska = laender.first(name: "alaska")
	@alaska = alaska.unit_count if !alaska.nil?
	alberta = laender.first(name: "alberta")
	@alberta = alberta.unit_count if !alberta.nil?
	ontario = laender.first(name: "ontario")
	@ontario = ontario.unit_count if !ontario.nil?
	weststaaten = laender.first(name: "weststaaten")
	@weststaaten = weststaaten.unit_count if !weststaaten.nil?
	mittel_amerika = laender.first(name: "mittel_amerika")
	@mittel_amerika = mittel_amerika.unit_count if !mittel_amerika.nil?
	oststaaten = laender.first(name: "oststaaten")
	@oststaaten = oststaaten.unit_count if !oststaaten.nil?
	groenland = laender.first(name: "groenland")
	@groenland = groenland.unit_count if !groenland.nil?
	nordwest_territorium = laender.first(name: "nordwest_territorium")
	@nordwest_territorium = nordwest_territorium.unit_count if !nordwest_territorium.nil?
	quebec = laender.first(name: "quebec")
	@quebec = quebec.unit_count if !quebec.nil?
	
	@posts = Post.all().last(20)
	
	@players = account.game.players(order: [:number.asc])
	slim :game
end

get '/game/create' do
	redirect '/login' unless logged_in?
	# TODO: Spieleinstellungen vornehmen lassen? (game_create.slim)
	account = get_account
	unless account.game.nil?
		redirect '/lobby' unless account.game.running
		redirect '/game'
	end
	
	slim :game_create
end

post '/game/create' do
	redirect '/login' unless logged_in?
	account = get_account
	unless account.game.nil?
		redirect '/lobby' unless account.game.running
		redirect '/game'
	end
	
	@errors = Array.new
	params[:game_name].strip!
	
	# pruefe, ob Spielname ausgefüllt
	if params[:game_name].nil? || params[:game_name].empty? || params[:game_name] == ""
		@errors << "Der Spielname fehlt."
	end
	
	if !Game.first(name: params[:game_name]).nil?
		@errors << "Ein Spiel mit dem Namen \"#{params[:game_name]}\" gibt es bereits."
	end
	
	if @errors.empty?
		account.update(player: Player.create(game: Game.create(name: params[:game_name]), number: 1))
		redirect '/lobby'
	end
	
	slim :game_create
end

get '/game/join/:game_name' do	
	redirect '/login' unless logged_in?
	redirect '/list' if params[:game_name].nil?
	game = Game.first(name: params[:game_name])
	halt 500, "Dises Spiel existiert nicht." if game.nil?
	account = get_account
	redirect '/lobby' if account.game == game
	redirect '/list' if game.players.count == game.maximum_players
	halt 500, "Sie sind bereits in einem Spiel." unless account.game.nil?
	halt 500, "Spiel laeuft bereits." if game.running
	account.update(player: Player.create(game: game, number: game.players.length+1))
	
	redirect '/lobby'
end

get '/game/start' do
	redirect '/login' unless logged_in?
	game = get_game
	redirect '/game' if game.running
	# auf Berechtigung zum Starten ueberpruefen
	redirect '/lobby' if get_account.player != game.players(order: [:number.asc]).first
	redirect '/lobby' if game.players.count < 2
	game.update(running: true, active_player: game.players(order: [:number.asc]).first)
	
	# Laender erstellen
	# Landname => {country => Objekt des Landes aus der DB,
	#						neighbors => Namen der Nachbarn}
	laender_beziehungen = {
		# Nord-Amerika
		"alaska" => {country: nil, neighbors: ["alberta", "nordwest-territorium", "kamtschatka"]},
		"alberta" => {country: nil, neighbors: ["alaska", "nordwest-territorium", "weststaaten", "ontario"]},
		"weststaaten" => {country: nil, neighbors: ["alberta", "mittel-amerika", "ontario", "oststaaten"]},
		"mittel-amerika" => {country: nil, neighbors: ["weststaaten", "oststaaten", "venezuela"]},
		"nordwest-territorium" => {country: nil, neighbors: ["alaska", "alberta", "groenland", "ontario"]},
		"ontario" => {country: nil, neighbors: ["nordwest-territorium", "alberta", "weststaaten",
				"oststaaten", "quebec", "groenland"]},
		"oststaaten" => {country: nil, neighbors: ["weststaaten", "mittel-amerika", "ontario", "quebec"]},
		"quebec" => {country: nil, neighbors: ["ontario", "oststaaten", "groenland"]},
		"groenland" => {country: nil, neighbors: ["nordwest-territorium", "ontario", "quebec", "island"]},
			
		# Süd-Amerika
		"venezuela" => {country: nil, neighbors: ["mittel-amerika", "peru", "brasilien"]},
		"peru" => {country: nil, neighbors: ["venezuela", "brasilien", "argentinien"]},
		"brasilien" => {country: nil, neighbors: ["venezuela", "peru", "argentinien", "nordwest-afrika"]},
		"argentinien" => {country: nil, neighbors: ["peru", "brasilien"]},
			
		# Afrika
		"nordwest-afrika" => {country: nil, neighbors: ["brasilien", "aegypten", "ost-afrika", "kongo", "west-europa", "sued-europa"]},
		"aegypten" => {country: nil, neighbors: ["nordwest-afrika", "ost-afrika", "mittlerer-osten", "sued-europa"]},
		"ost-afrika" => {country: nil, neighbors: ["nordwest-afrika", "aegypten", "kongo", "sued-afrika", "mittlerer-osten", "madagaskar"]},
		"kongo" => {country: nil, neighbors: ["nordwest-afrika", "ost-afrika", "sued-afrika"]},
		"sued-afrika" => {country: nil, neighbors: ["ost-afrika", "kongo", "madagaskar"]},
		"madagaskar" => {country: nil, neighbors: ["ost-afrika", "sued-afrika"]},
			
		# Europa
		"island" => {country: nil, neighbors: ["groenland", "skandinavien", "gross-britannien"]},
		"skandinavien" => {country: nil, neighbors: ["island", "ukraine", "gross-britannien", "mittel-europa"]},
		"ukraine" => {country: nil, neighbors: ["skandinavien", "mittel-europa", "mittlerer-osten", "afghanistan", "ural", "sued-europa"]},
		"gross-britannien" => {country: nil, neighbors: ["island", "skandinavien", "mittel-europa", "west-europa"]},
		"mittel-europa" => {country: nil, neighbors: ["skandinavien", "ukraine", "gross-britannien", "west-europa", "sued-europa"]},
		"west-europa" => {country: nil, neighbors: ["nordwest-afrika", "gross-britannien", "mittel-europa", "sued-europa"]},
		"sued-europa" => {country: nil, neighbors: ["nordwest-afrika", "aegypten", "ukraine", "mittel-europa", "west-europa", "mittlerer-osten"]},
			
		# Asien
		"mittlerer-osten" => {country: nil, neighbors: ["aegypten", "ost-afrika", "ukraine", "afghanistan", "indien", "sued-europa"]},
		"afghanistan" => {country: nil, neighbors: ["ukraine", "mittlerer-osten", "ural", "china", "indien"]},
		"ural" => {country: nil, neighbors: ["ukraine", "afghanistan", "sibirien", "china"]},
		"sibirien" => {country: nil, neighbors: ["ural", "jakutien", "irkutsk", "mongolei", "china"]},
		"jakutien" => {country: nil, neighbors: ["sibirien", "irkutsk", "kamtschatka"]},
		"kamtschatka" => {country: nil, neighbors: ["alaska", "jakutien", "irkutsk", "mongolei", "japan"]},
		"irkutsk" => {country: nil, neighbors: ["sibirien", "jakutien", "mongolei","kamtschatka"]},
		"mongolei" => {country: nil, neighbors: ["sibirien", "irkutsk", "japan", "china", "kamtschatka"]},
		"japan" => {country: nil, neighbors: ["mongolei", "china", "kamtschatka"]},
		"china" => {country: nil, neighbors: ["afghanistan", "ural", "sibirien", "mongolei", "japan", "indien", "siam"]},
		"indien" => {country: nil, neighbors: ["mittlerer-osten", "afghanistan", "china", "siam"]},
		"siam" => {country: nil, neighbors: ["china", "indien", "indonesien"]},
			
		# Ozeanien
		"indonesien" => {country: nil, neighbors: ["siam", "neu-guinea", "west-australien"]},
		"neu-guinea" => {country: nil, neighbors: ["indonesien", "ost-australien"]},
		"ost-australien" => {country: nil, neighbors: ["neu-guinea", "west-australien"]},
		"west-australien" => {country: nil, neighbors: ["indonesien", "ost-australien"]}
	}
	
	# Spieler auflisten und verbleibende Anzahl der Laender pro Spieler speichern
	players = Array.new
	game.players.each do |player|
		players << {account: player, laender_anzahl: 42 / game.players.length}
	end
	
	# restliche Laender verteilen
	anzahl_laender = 42 % players.length
	anzahl_spieler = players.length
	players.each do |player|
		if rand(anzahl_spieler) < anzahl_laender
			anzahl_laender -= 1
			player[:laender_anzahl] += 1
		end
		anzahl_spieler -= 1
	end
	
	# Länder zufällig verteilen
	# und Country Objekte in der Datenbank erzeugen
	remaining = 42
	laender_beziehungen.each do |name, data|
		# Zugehoerigkeit ermitteln
		random = rand(remaining) + 1
		remaining -= 1;
		laender_anzahl = 0
		owner = nil
		players.each do |player|
			laender_anzahl += player[:laender_anzahl]
			if random <= laender_anzahl
				owner = player[:account]
				player[:laender_anzahl] -= 1
				break
			end
		end
		data[:country] = Country.create(name: name, unit_count: 1, game: game, player: owner)
	end

	# Nachbarschaftsbeziehungen speichern
	laender_beziehungen.each do |name, data|
		data[:neighbors].each do |neighbor|
			CountryCountry.create(country_id: data[:country].id, neighbor_id: laender_beziehungen[neighbor][:country].id)
		end
	end

	# verfuegbare Einheiten berechnen
	game.calculate_units
	game.save
	halt 500, "Fehler beim Speichern." unless game.saved?
	redirect '/game'
end

get '/game/leave' do
	redirect '/login' unless logged_in?
	# Spiel <-> Spieler Verbindung trennen
	account = get_account
	game = get_game
	game.players(:number.gt => account.player.number).each do |player|
		player.number -= 1
	end
	# bin ich an der Reihe?
	if game.active_player == account.player
		game.set_next_player_active
	end
	game.save
	halt 500, "Fehler beim Speichern." unless game.saved?
	player = account.player
	player.update(account: nil)
	player.update(game: nil)
	Player.get(player.id).destroy!
	game = Game.get(game.id)
	# Spiel loeschen, wenn leer
	redirect '/list' unless game.players.empty?
	game.countries.each do |country|
		country.country_countries.destroy
		country.destroy
	end
	game.reload
	game.destroy
	redirect '/list'
end

get '/update' do # Spieldaten abfragen
	halt 500, "Keine Informationen verfuegbar." unless logged_in?
	halt 404 if !request.xhr? # kein AJAX Aufruf?
	
	if params[:updateCount].nil?
		updateCount = 0 
	else 
		updateCount = params[:updateCount]
	end
	
	# Allgemeine Spielinformationen
	game = get_game
	active_player = game.active_player
	active_player = active_player.name if !active_player.nil?
	phase = game.phase
	# phase auf "warten" setzen, wenn nicht an der Reihen; es sei denn das Spiel ist vorbei
	phase = 3 if game.active_player != get_account.player && !game.is_over
	placeable_units = game.placeable_units
	placeable_units = 0 if game.active_player != get_account.player
	
	# Laenderinformationen
	laender = Array.new
	game.countries.each do |land|
		owner = land.player
		owner = owner.name if !owner.nil?
		laender << {owner: owner, name: land.name, unit_count: land.unit_count}
	end
		
	halt 200, {active_player: active_player, mapdata: laender, phase: phase,
		placeable_units: placeable_units, updateCount: updateCount, gameOver: game.is_over}.to_json
end

post '/update/phase' do # Spieler hat am Ende einer Phase auf Bestaetigen geklickt
	account = get_account
	game = get_game
	halt 500, "Sie sind nicht an der Reihe." unless account.player == game.active_player
	game.set_next_phase
	game.check_if_over
	game.save
	halt 500, "Fehler beim Speichern." unless game.saved?
	status 200
end

post '/update/new_unit' do
	# fuegt einigen Laendern Einheiten hinzu
	# Zu viele Fehlerabfragen eingebaut ?
	halt 500, "Fehler: ungueltige Daten." if params[:data].nil?
	halt 500, "Fehler: Sie sind nicht eingeloggt." unless logged_in?
	# pruefen ob Spieler an der Reihe ist
	account = get_account
	game = get_game
	halt 500, "Sie sind nicht an der Reihe." unless account.player == game.active_player
	halt 500, "Es wurden bereits alle verfuegbaren Einheiten verteilt." if game.placeable_units <= 0
	laender = game.countries
	halt 500, "Fehler: Es gibt keine Laender in diesem Spiel." if laender.empty?
	parsed_data = JSON.parse(params[:data])
	halt 500, "Fehler: keine gueltigen Informationen." if parsed_data.class.to_s != "Array"
	parsed_data.each do |data|
		halt 500 if !data.key?("land_name")
		halt 500 if !data.key?("unit_count")
		halt 500, "Nicht genuegend Einheiten verfuegbar." if data["unit_count"] > game.placeable_units
		land = laender.first(name: data["land_name"]) 
		halt 500, "Fehler: Es gibt dieses Land nicht: " + data["land_name"] if land.nil?
		land.unit_count += data["unit_count"]
		land.save
		game.update(placeable_units: game.placeable_units - data["unit_count"])
	end
	"" # sinatra kann hier mit einem Hash nichts anfangen
end

post '/update/attack' do
	halt 500, "Fehler: Sie sind nicht eingeloggt." unless logged_in?
	account = get_account
	game = get_game
	halt 500, "Sie sind nicht an der Reihe." unless account.player == game.active_player
	halt 500, "Fehler: ungueltige Daten." if params[:source].nil? || params[:target].nil? || params[:units].nil?
	source = game.countries.first(name: params[:source])
	halt 500, "Es gibt dieses Land nicht: #{params[:source]}" if source.nil?
	halt 500, "Dieses Land gehoert ihnen nicht: #{params[:source]}" unless source.player == account.player
	target = game.countries.first(name: params[:target])
	halt 500, "Es gibt dieses Land nicht: #{params[:target]}" if target.nil?
	halt 500, "Sie koennen ihr eigenes Land nicht angreifen: #{params[:target]}" if target.player == account.player
	halt 500, "#{target.name} ist kein Nachbarland von #{source.name}" if source.neighbors.get(target.id).nil?
	halt 500, "Zu wenige Einheiten." if source.unit_count <= 1
	units = params[:units].to_i
	halt 500, "Ungueltige Einheitenzahl." unless units < source.unit_count && units > 0
	source.update(unit_count: source.unit_count - units)
	units.times do
		if rand(6) > rand(6)
			target.update(unit_count: target.unit_count - 1)
		else
			units -= 1
		end
		if target.unit_count == 0
			target.update(unit_count: units, player: source.player)
			break
		end
	end
	# pruefen, ob das Spiel vorbei ist
	game.check_if_over
	""
end

post '/update/transfer' do
	halt 500, "Fehler: Sie sind nicht eingeloggt." unless logged_in?
	account = get_account
	game = get_game
	halt 500, "Sie sind nicht an der Reihe." unless account.player == game.active_player
	halt 500, "Fehler: ungueltige Daten." if params[:source].nil? || params[:target].nil? || params[:units].nil?
	source = game.countries.first(name: params[:source])
	halt 500, "Es gibt dieses Land nicht: #{params[:source]}" if source.nil?
	halt 500, "Dieses Land gehoert ihnen nicht: #{params[:source]}" unless source.player == account.player
	target = game.countries.first(name: params[:target])
	halt 500, "Es gibt dieses Land nicht: #{params[:target]}" if target.nil?
	halt 500, "Dieses Land gehoert ihnen nicht: #{params[target]}" unless target.player == account.player
	halt 500, "Zu wenige Einheiten." if source.unit_count <= 1
	units = params[:units].to_i
	halt 500, "Ungueltige Einheitenzahl." unless units < source.unit_count && units > 0
	land_verbunden = Hash.new
	# Alle Länder des Spielers ermitteln
	game.countries(player: account.player).each do |land|
		if land == source
			land_verbunden[land] = true
		else
			land_verbunden[land] = false
		end
	end
	# Solange iterieren, bis sich nichts mehr veraendert
	change = true
	while change do
		change = false
		land_verbunden.each do |land, verbunden|
			if verbunden
				land.neighbors.each do |neighbor|
					if neighbor.player == account.player && land_verbunden[neighbor] == false
						change = true
						land_verbunden[neighbor] = true
						break if neighbor = target
					end
				end
			end
		end
	end
	halt 500, "Dieses Land ist nicht zu erreichen #{target.name}" if land_verbunden[target] == false
	source.update(unit_count: source.unit_count - units)
	target.update(unit_count: target.unit_count + units)
	game.set_next_phase
	""
end