require 'sinatra'
require 'sinatra/reloader' if development?
require 'slim'

configure do
	require './database.rb'
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