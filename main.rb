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
  #bla bla
	@logged_in = true
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

post '/login' do # TODO: zur Übersichtlichkeit an verschiedene URLs posten? z.B.: '/login'
	# Session-basiertes Login-System
	if !session.key?(:account_id) # bereits eingeloggt?
		if !params[:login_name].nil? && !params[:login_pass].nil?
			# TODO: Daten auf vollständigkeit prüfen: länge?
			
			account = Account.get( :login_name => params[:login_name] ) # geht das hier überhaupt? Will "get" nicht ID´s? EDIT: Funktioniert auf jeden Fall
			
			if account.nil? || account.password != params[:login_pass]
				# Benutzername oder Passwort ungültig
				@login_info = "Benutzername, oder Passwort ung&uuml;ltig"
				
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
	end	
end

get '/login' do
  # Login-Formular
  slim :login	
end
get '/logout' do	# bin ich einfach nur doof, oder werden überschriften (h1, h2, ..) immer in caps dargestellt?
	@logout = "Successfully logged out!"
	slim :logout
end
get '/testpage' do
	@hello = "Hello"
	slim :home
end	
