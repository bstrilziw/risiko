require 'sinatra'
require 'sinatra/reloader' if development?
require 'slim'
require 'json'

require_relative 'helpers'
require_relative 'db_helpers'

configure do
	Slim::Engine.set_default_options pretty: true, sort_attrs: true
	set :views, :slim => 'templates', :scss => 'styles'
  set :public_folder, 'assets'
	require_relative 'database'
	enable :sessions
end

get('/styles/styles.css') { scss :styles }

get '/' do
  slim :home
end

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
	
	@players = Account.all(game: account.game)
	slim :lobby
end

get '/game' do
  redirect '/login' unless logged_in?
	account = get_account
	redirect '/list' if account.game.nil?
	redirect '/lobby' unless account.game.running
	
	laender = Country.all(game: account.game)
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
	
	@players = account.game.players
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
	redirect '/game/create' if params[:game_name].nil? || params[:game_name].empty?
	
	account.update(game: Game.create(name: params[:game_name]))
	redirect '/lobby'
end

get '/game/join/:game_name' do	
	redirect '/list' if params[:game_name].nil?
	game = Game.first(name: params[:game_name])
	halt 500, "Dises Spiel existiert nicht." if game.nil?
	account = get_account
	redirect '/lobby' if account.game == game
	halt 500, "Sie sind bereits in einem Spiel." unless account.game.nil?
	account.update(game: game)
	
	redirect '/lobby'
end

get '/game/start' do
	redirect '/login' unless logged_in?
	game = get_game
	redirect '/game' if game.running
	# auf Berechtigung zum Starten ueberpruefen
	redirect '/lobby' if get_account != game.players.first
	game.update(running: true, active_player: game.players.first)
	
	# Laender erstellen
	# Landname => {country => Objekt des Landes aus der DB,
	#						neighbors => Namen der Nachbarn}
	laender_beziehungen = {
			# Nord-Amerika
			"alaska" => {country: nil, neighbors: ["alberta", "nordwest-territorium", "kamtschatka"]},
			"alberta" => {country: nil, neighbors: ["alaska", "nordwest-territorium", "weststaaten", "ontario"]},
			"weststaaten" => {country: nil, neighbors: ["alberta", "mittel-amerika", "ontario", "oststaaten"]},
			"mittel-amerika" => {country: nil, neighbors: ["weststaaten", "oststaaten", "venezuela"]},
			"nordwest-territorium" => {country: nil, neighbors: ["alaska", "alberta", "groenland"]},
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
			"indonesien" => {country: nil, neighbors: ["siam", "neu-guinea", "ost-australien", "west-australien"]},
			"neu-guinea" => {country: nil, neighbors: ["indonesien", "ost-australien"]},
			"ost-australien" => {country: nil, neighbors: ["indonesien", "neu-guinea", "west-australien"]},
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
		data[:country] = Country.create(name: name, unit_count: 1, game: game, account: owner)
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
	# bin ich an der Reihe?
	if game.active_player == account
		game.set_next_player_active
	end
	game.save
	halt 500, "Fehler beim Speichern." unless game.saved?
	account.update(game: nil)
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
	
	# Allgemeine Spielinformationen
	game = get_game
	active_player = game.active_player
	active_player = active_player.name if !active_player.nil?
	phase = game.phase
	phase = 3 if game.active_player != get_account
	placeable_units = game.placeable_units
	placeable_units = 0 if game.active_player != get_account
	
	# Laenderinformationen
	countries = Country.all(game: game)
	laender = []
	countries.each do |land|
		land.save;
		owner = land.account
		owner = owner.name if !owner.nil?
		laender << {owner: owner, name: land.name, unit_count: land.unit_count}
	end
		
	halt 200, {active_player: active_player, mapdata: laender, phase: phase,
					placeable_units: placeable_units}.to_json
end

post '/update/phase' do # Spieler hat am Ende einer Phase auf Bestaetigen geklickt
	account = get_account
	game = get_game
	halt 500, "Sie sind nicht an der Reihe." unless account == game.active_player
	game.phase += 1
	if game.phase == 3
		game.phase = 0
		# naechsten Spieler waehlen
		game.set_next_player_active
	end
	if game.phase == 0
		# verfuegbare Einheiten berechnen
		game.placeable_units = account.countries.length / 3
		game.placeable_units = 3 if game.placeable_units < 3
	end
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
	halt 500, "Sie sind nicht an der Reihe." unless account == game.active_player
	halt 500, "Es wurden bereits alle verfuegbaren Einheiten verteilt." if game.placeable_units <= 0
	laender = Country.all(game: game)
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
	halt 500, "Sie sind nicht an der Reihe." unless account == game.active_player
	halt 500, "Fehler: ungueltige Daten." if params[:source].nil? || params[:target].nil? || params[:units].nil?
	source = game.countries.first(name: params[:source])
	halt 500, "Es gibt dieses Land nicht: #{params[:source]}" if source.nil?
	halt 500, "Dieses Land gehoert ihnen nicht: #{params[:source]}" unless source.account == account
	target = game.countries.first(name: params[:target])
	halt 500, "Es gibt dieses Land nicht: #{params[:target]}" if target.nil?
	halt 500, "Sie koennen ihr eigenes Land nicht angreifen: #{params[:target]}" if target.account == account
	halt 500, "#{target.name} ist kein Nachbarland von #{source.name}" if source.neighbors.get(target.id).nil?
	halt 500, "Zu wenige Einheiten." if source.unit_count <= 1
	units = params[:units].to_i
	halt 500, "Ungueltige Einheitenzahl." unless units < source.unit_count && units > 0
	if units < target.unit_count
		target.update(unit_count: target.unit_count - units)
	elsif units == target.unit_count
		target.update(unit_count: 1)
	elsif units > target.unit_count
		target.update(unit_count: units - target.unit_count, account: source.account)
	end
	source.update(unit_count: source.unit_count - units)
	""
end

get '/login' do
	redirect '/' if logged_in?
  # Login-Formular
  slim :login	
end

post '/login' do
	# Session-basiertes Login-System
	halt 500, "Sie sind bereits eingeloggt." if logged_in?
	if !params[:login_name].nil? && !params[:login_pass].nil?

		account = Account.first( :login_name => params[:login_name] )

		if account.nil? || account.password != params[:login_pass]
			# Benutzername oder Passwort ungueltig
			@login_info = "Benutzername, oder Passwort ung&uuml;ltig" # UNUSED

			redirect '/login'
		else
			# Login-Informationen korrekt
			session[:account_id] = account.id
			session[:account_name] = account.name
			# TODO: Account-Namen in der Session speichern, oder immer wieder neu aus der DB laden?

			# TODO: neue Seite anzeigen, nachdem man eingeloggt ist?
			# 		oder gleiche Seite umgestalten? <<- gleiche Seite umgestalten, Feedback fürs Einloggen erhalten
			# 		z.b. "Willkommen Fafnir!"
			redirect '/'
		end
	end
end

get '/logout' do
	redirect '/' unless logged_in?
		session.clear
		slim :logout
end

get '/account/new' do #Neue Accounts
	slim :new_account
end

post '/account/new' do
	if params[:login_name] != nil && params[:login_pass] != nil && params[:name] != nil
		# pruefen, ob login_name bereits vergeben ist
		if Account.first(login_name: params[:login_name]).nil? && Account.first(name: params[:name]).nil?
			account = Account.create(login_name: params[:login_name], password: params[:login_pass], name: params[:name])
		else
			halt 500, "Name bereits vergeben!"
		end
	end
	if account.saved?
		redirect to('/')
	else
		slim "p.fehler Account konnte nicht erstellt werden."
	end	
end

post '/chat' do
	if !params[:message].empty?
	@post = Post.create(text: params[:message], writer: get_account, time: Time.new)
	end
end

get '/updateChat' do
	messages = Array.new
	Post.all().last(20).each do |post|
		messages << "[#{post.time.strftime('%H:%M') if post.time}] #{post.writer.name}: #{post.text}"
	end
	messages.to_json
end