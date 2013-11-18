require 'sinatra'
require 'sinatra/reloader' if development?
require 'slim'
require './database.rb'

configure do
	DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/database.db")
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