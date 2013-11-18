require 'sinatra'
require 'sinatra/reloader' if development?

get '/' do
  #bla bla
  slim :home
end  
