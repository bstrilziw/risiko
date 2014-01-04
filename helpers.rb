helpers do
	# wird benötigt, sobald ein template/view Ordner manuell gesetzt wird ( set :views )
  def find_template(views, name, engine, &block)
    _, folder = views.detect { |k,v| engine == Tilt[k] }
    folder ||= views[:default]
    super(folder, name, engine, &block)
  end
	
	def logged_in?
		session.key? :account_id
	end
	
	def validate_account_form
		errors = Array.new

		edit = false
		edit = true if params[:edit] == "1"

		account = get_account if edit

		# pruefe, ob alle Werte gesetzt sind
		if params[:login_name] == ""
			errors << "Bitte gib einen Benutzernamen ein."
		end
		if params[:mail] == "" || !/\A([\w\.\-\+]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i.match(params[:mail])
			errors << "Bitte gib eine gueltige E-Mail-Adresse ein."
		end
		if params[:login_pass] == "" && !edit
			errors << "Bitte gib ein Passwort ein."
		end
		if params[:login_pass] != "" && params[:login_pass_repeat] == "" && !edit
			errors << "Bitte wiederhole das Passwort."
		end
		if params[:name] == ""
			errors << "Bitte gib einen Anzeigenamen ein."
		end

		# pruefen, ob Benutzername bereits vergeben ist
		if !Account.first(login_name: params[:login_name]).nil? && !edit || edit && params[:login_name] != account.login_name && !Account.first(login_name: params[:login_name]).nil?
			errors << "Der Benutzername #{params[:login_name]} ist bereits vergeben."
		end

		# pruefen, ob E-Mail-Adresse bereits vergeben ist
		if !Account.first(mail: params[:mail]).nil? && !edit || edit && params[:mail] != account.mail && !Account.first(mail: params[:mail]).nil?
			errors << "Die E-Mailadresse #{params[:mail]} ist bereits einem anderen Benutzer zugeordnet."
		end

		# pruefen, ob Anzeigenamne bereits vergeben ist
		if !Account.first(name: params[:name]).nil? && !edit || edit && params[:name] != account.name && !Account.first(name: params[:name]).nil?
			errors << "Der Anzeigenamne #{params[:name]} ist bereits vergeben."
		end

		# pruefen, ob Passwörter übereinstimmen
		if params[:login_pass] != params[:login_pass_repeat]
			errors << "Die Passwoerter stimmen nicht ueberein."
		end

		# pruefen, ob Werte zu lang
		if params[:login_name].length > 15
			errors  << "Der Benutzername darf nur 15 Zeichen lang sein."
		end
		if params[:mail].length > 255
			errors << "Deine E-Mail-Adresse ist zu lang, bitte waehle eine, das max. 255 Zeichen hat."
		end
		if params[:login_pass].length > 255
			errors << "Das Passwort ist zu lang, bitte waehle eins, das max. 255 Zeichen hat."
		end
		if params[:name].length > 15
			errors << "Der Anzeigename darf nur 15 Zeichen lang sein."
		end

		errors
	end
end