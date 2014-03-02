require 'sinatra'
require 'sinatra/reloader' if development?
require 'slim'
require 'json'
require 'digest'
require 'pony'

require_relative 'helpers'
require_relative 'db_helpers'

configure do
	Slim::Engine.set_default_options pretty: true, sort_attrs: true
	set :views, :slim => 'templates', :scss => 'styles'
	set :public_folder, 'assets'
	require_relative 'database'
	set :bind, '0.0.0.0'
	enable :sessions
	set :bind, '0.0.0.0'
	set :port, 80
end

get('/styles/styles.css') { scss :styles }

get '/' do
	if logged_in?
		@account = get_account
		@values = Hash[:login_name, @account.login_name, :name, @account.name, :mail, @account.mail]

		if !@account.game_id.nil?
			@game = Game.get(@account.game_id)
		end
	end
	
  slim :home
end

require_relative 'routes/account'
require_relative 'routes/chat'
require_relative 'routes/game'