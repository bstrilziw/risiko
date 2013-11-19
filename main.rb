require 'sinatra'
require 'sinatra/reloader' if development?
require 'slim'

require_relative 'helpers'

configure do
	Slim::Engine.set_default_options pretty: true, sort_attrs: true
	set :views, :slim => 'templates'
	require_relative 'database'
end

get '/' do
  #bla bla
  slim :home
end  

get '/:name' do
  # einfach nur weil ich es kann.
  @name = :name
  "Hello #{:name}, how are you?"
end