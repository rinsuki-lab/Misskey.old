require! {
	jade
	'./parse-text'
	'../../config'
}

module.exports = (messages, me) ->
	console.log 'yyyyyyyyyyyyyyyyy'
	resolve, reject <- new Promise!
	console.log 'xxxxxxxxxxxxxxxxx'
	if !empty messages and !messages?
		console.log '############=======#########'
		message-compiler = jade.compile-file "#__dirname/../views/templates/user-talk/message.jade" {pretty: '  '}
		resolve (messages |> map (message) ->
			message-compiler do
				message: message
				me: me
				text-parser: parse-text
				config: config.public-config)
	else
		console.log '#####################'
		resolve null