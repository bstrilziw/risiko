helpers do
	def get_account
		account = Account.get(session[:account_id])
		halt 500, "Fehler: Diesen Account gibt es nicht." if account.nil?
		account
	end
	def get_game
		game = get_account.game
		halt 500, "Fehler: Keinem Spiel zugeordnet." if game.nil?
		game
	end
end