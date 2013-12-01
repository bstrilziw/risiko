require 'sinatra'
require 'sinatra/reloader' if development?
require 'slim'

require_relative 'helpers'

configure do
	Slim::Engine.set_default_options pretty: true, sort_attrs: true
	set :views, :slim => 'templates', :scss => 'styles'
  set :public_folder, 'assets'
	require_relative 'database'
	enable :sessions
end

get('/styles/styles.css') { scss :styles }

get '/' do
	@logged_in = true # UNUSED
  slim :home
end

get '/game' do
  # TODO: prüfen, ob Spieler eingeloggt ist
	session[:player_id] = 1
  laender = Country.all(game: Account.get(session[:player_id]).game)
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

get '/login' do
	if session.key?(:account_id) # bereits eingeloggt
		redirect '/'
	end
  # Login-Formular
  slim :login	
end

post '/login' do
	# Session-basiertes Login-System
	if !session.key?(:account_id) # bereits eingeloggt?
		if !params[:login_name].nil? && !params[:login_pass].nil?
			# TODO: Daten auf vollständigkeit prüfen: länge?
			
			account = Account.first( :login_name => params[:login_name] )
			
			if account.nil? || account.password != params[:login_pass]
				# Benutzername oder Passwort ungueltig
				@login_info = "Benutzername, oder Passwort ung&uuml;ltig" # UNUSED
				
				redirect '/'
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
	else
		slim "p#fehler Sie sind bereits eingelogt."
	end	
end

get '/logout' do
	session.clear
	@logout = "Successfully logged out!" # UNUSED
	slim :logout
end

get '/testpage' do
	@hello = "Hello" # UNUSED
	slim :home
end	

get '/account/new' do #Neue Accounts
	@account = Account.new # UNUSED
	slim :new_account
end

post '/account/new' do
	if params[:login_name] != nil && params[:login_pass] != nil && params[:name] != nil
		account = Account.create(login_name: params[:login_name], password: params[:login_pass], name: params[:name], game: Game.first)
	end
	if account.saved?
		redirect to('/')
	else
		slim "p#fehler Account konnte nicht erstellt werden."
	end	
end