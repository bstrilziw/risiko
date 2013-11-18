require 'sinatra'
require 'sinatra/reloader' if development?

get '/' do
  #bla bla
  slim :home
end  

get '/:name' do
  # einfach nur weil ich es kann.
  @name = :name
  "Hello #{:name}, how are you?"
end  
