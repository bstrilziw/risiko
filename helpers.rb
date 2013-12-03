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
end