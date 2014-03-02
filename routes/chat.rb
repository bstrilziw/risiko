post '/chat' do
	if !params[:message].empty?
		@post = Post.create(text: params[:message], writer: get_account, time: Time.new)
	end
end

get '/updateChat' do
	messages = Array.new
	Post.all().last(20).each do |post|
		messages << "[#{post.time.strftime('%H:%M') if post.time}] #{post.writer.name}: #{post.text}"
	end
	messages.to_json
end