get '/login' do
	redirect '/' if logged_in?
	# Login-Formular
	slim :login
end

post '/login' do
	# Session-basiertes Login-System
	@errors = Array.new
	halt 500, "Sie sind bereits eingeloggt." if logged_in?
	if !params[:login_name].nil? && !params[:login_pass].nil?

		account = Account.first( :login_name => params[:login_name] )

		if account.nil? || account.password != Digest::SHA1.hexdigest(params[:login_pass])
			# Benutzername oder Passwort ungueltig
			@errors << "Benutzername oder Passwort ungueltig"
			@username = params[:login_name]
				
			slim :login
		else
			# Login-Informationen korrekt
			session[:account_id] = account.id
			redirect '/account'
		end
	end
end

get '/logout' do
	redirect '/' unless logged_in?
	session.clear
	
	slim :logout
end

get '/account' do
	@account = get_account
	@values = Hash[:login_name, @account.login_name, :name, @account.name, :mail, @account.mail]
	@game = @account.game unless @account.game.nil?
	
	slim :account
end

get '/account/new' do #Neue Accounts
	@values = Hash[:login_name, "", :name, "", :mail, ""]
	slim :new_account
end

post '/account/new' do
	@values = params
	@errors = validate_account_form

	# keine Fehler? Dann sollten alle Daten stimmen, Account wird angelegt
	if @errors.empty?
		password = Digest::SHA1.hexdigest(params[:login_pass]) # see: http://ruby.about.com/od/advancedruby/ss/Cryptographic-Hashes-In-Ruby.htm
		account = Account.create(login_name: params[:login_name], password: password, mail: params[:mail], name: params[:name])
		
		if account != nil && account.saved?
			@errors << "Der Account #{params[:login_name]} wurde angelegt."
				
			# verschicke E-Mail
			body = "Hallo #{params[:name]},\n\nherzlich Willkommen bei Risiko. Du hast dich erfolgreich registriert und kannst dich jetzt mit deinem Benutzernamen <strong>#{params[:login_name]}</strong> und deinem Passwort <a href=\"http://localhost:4567/login\">hier anmelden</a>.\n\nViel Spass beim Spielen,\ndein Risiko-Team"
			Pony.mail(
				:to => params[:mail], 
				:from => 'risiko@internerz.de', 
				:subject => 'Registrierung bei Risiko', 
				:body => body, 
				:via => :smtp,
				:via_options => {
					:address        => 'mailtrap.io',
					:port           => '25',
					:user_name      => 'risiko-31a0f2d30dd35176',
					:password       => 'c6661a2e4b9b21ab',
					:authentication => :plain,
					:domain         => "localhost"
				}
			)
		else
			@errors << "Account konnte nicht erstellt werden."
		end
		
		@values.clear
	end

	slim :new_account
end

post '/account/edit' do
	@values = params
	@errors = validate_account_form
	
	# keine Fehler? Dann sollten alle Daten stimmen, Account wird geändert
	if @errors.empty?
		password = Digest::SHA1.hexdigest(params[:login_pass]) # see: http://ruby.about.com/od/advancedruby/ss/Cryptographic-Hashes-In-Ruby.htm
		account = get_account
		account.update(login_name: params[:login_name], password: password, mail: params[:mail], name: params[:name])
		
		@errors << "Der Account wurde geaendert."
	end
	
	slim :account_edit_form
end