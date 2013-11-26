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
  slim :home
end

get '/game' do
  # TODO: prüfen, ob Spieler eingeloggt ist
  slim :game
end

post '/' do # TODO: zur Übersichtlichkeit an verschiedene URLs posten? z.B.: '/login'
	# Session-basiertes Login-System
	if !session.key?(:account_id) # bereits eingeloggt?
		if !params[:login_name].nil? && !params[:login_pass].nil?
			# TODO: Daten auf vollständigkeit prüfen: länge?
			
			account = Account.get( :login_name => params[:login_name] )
			
			if account.nil? || account.password != params[:login_pass]
				# Benutzername oder Passwort ungültig
				@login_info = "Benutzername, oder Passwort ung&uuml;ltig"
				
				redirect '/'
			else
				# Login-Informationen korrekt
				session[:account_id] = account.id
				# TODO: Account-Namen in der Session speichern, oder immer wieder neu aus der DB laden?
				
				# TODO: neue Seite anzeigen, nachdem man eingeloggt ist?
				# 		oder gleiche Seite umgestalten?
				redirect '/'
			end
		end
	end	
end

get '/:name' do
  # einfach nur weil ich es kann.
  @name = :name
  "Hello #{:name}, how are you?"
end