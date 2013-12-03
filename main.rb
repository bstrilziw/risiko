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
	@games = Game.all(running: false) # hier pruefen ob das Spiel bereits laeuft
	slim :game_list
end

get '/lobby' do
	redirect '/login' unless logged_in?
	@players = Account.all(game: get_game)
	slim :lobby
end

get '/game' do
  redirect '/login' unless logged_in?
	
	laender = Country.all(game: get_game)
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
  slim :game
end

get '/game/create' do
	redirect '/login' unless logged_in?
	# TODO: Spieleinstellungen vornehmen lassen? (game_create.slim)
	redirect '/list' unless get_account.game.nil?
	get_account.update(game: Game.create())
	redirect '/lobby'
end

get '/game/start' do
	redirect '/login' unless logged_in?
	get_game.update(running: true)
	redirect 'game'
end

get '/game/leave' do
	redirect '/login' unless logged_in?
	redirect '/list'
end

get '/update' do # Spieldaten abfragen
	halt 500 unless logged_in?
	halt 500 if !request.xhr? # kein AJAX Aufruf?
	
	# Allgemeine Spielinformationen
	game = get_game
	active_player = Account.get(game.active_player)
	active_player = active_player.name if !active_player.nil?
	
	# Laenderinformationen
	countries = Country.all(game: game)
	laender = []
	countries.each do |land|
		# zu testzwecken wird hier immer eine Einheit hinzugefuegt
		#land.unit_count += 1;
		land.save;
		owner = Account.get(land.account)
		owner = owner.name if !owner.nil?
		laender << {owner: owner, name: land.name, unit_count: land.unit_count}
	end
	
	halt 200, {active_player: active_player, mapdata: laender}.to_json
end

post '/update/new_unit' do
	# fuegt einigen Laendern Einheiten hinzu
	# Zu viele Fehlerabfragen eingebaut ?
	halt 500, "Fehler: ungueltige Daten." if params[:data].nil?
	halt 500, "Fehler: Sie sind nicht eingeloggt." unless logged_in?
	laender = Country.all(game: get_game)
	halt 500, "Fehler: Es gibt keine Laender in diesem Spiel." if laender.empty?
	parsed_data = JSON.parse(params[:data])
	halt 500, "Fehler: keine gueltigen Informationen." if parsed_data.class.to_s != "Array"
	parsed_data.each do |data|
		data = parsed_data[0]
		halt 500 if !data.key?("land_name")
		land = laender.first(name: data["land_name"]) 
		halt 500, "Fehler: Es gibt dieses Land nicht: " + data["land_name"] if land.nil?
		land.unit_count += 1
		land.save
	end
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
	redirect '/' unless logged_in?
	@account = Account.new # UNUSED
	slim :new_account
end

post '/account/new' do
	if params[:login_name] != nil && params[:login_pass] != nil && params[:name] != nil
		# TODO pruefen, ob login_name bereits vergeben ist
		account = Account.create(login_name: params[:login_name], password: params[:login_pass], name: params[:name])
	end
	if account.saved?
		redirect to('/')
	else
		slim "p.fehler Account konnte nicht erstellt werden."
	end	
end