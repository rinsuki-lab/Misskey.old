#
# Misskey API server
#

require! {
	express
	cookie
	redis
	multer
	cors
	'body-parser'
	'cookie-parser'
	'express-session': session
	'connect-redis'
	'js-yaml': yaml
	'./router': router
	'../utils/publish-redis-streaming'
	'../utils/convert-string-to-color'
	'../config'
}

# Init session store
RedisStore = connect-redis session

# Create server
api-server = express!
	..disable 'x-powered-by'

session-store = new RedisStore do
	db: 1
	prefix: 'misskey-session:'

api-server
	..use cors do
		credentials: on
		origin:
			* config.public-config.url
			* config.public-config.dev-url
	..use body-parser.urlencoded {+extended}
	..use multer!
	..use cookie-parser config.cookie-pass
	..use session do
		key: config.session-key
		secret: config.session-secret
		resave: no
		save-uninitialized: yes
		cookie:
			path: '/'
			domain: ".#{config.public-config.domain}"
			http-only: no
			secure: no
			max-age: null
		store: session-store

api-server.set 'view engine' \jade
api-server.set 'views' "#__dirname/web/views/pages"

api-server.use (req, res, next) ->
	res.api-render = (data) ->
		switch req.format
		| \json => res.json data
		| \yaml =>
			res
				..header 'Content-Type' 'text/x-yaml'
				..send yaml.safe-dump data
		| \plain =>
			res
				..header 'Content-Type' 'text/plain'
				..send data
		| _ => res.json data
	res.api-error = (http-status-code, error) ->
		res.status http-status-code
		res.api-render {error}
	next!

# Log
api-server.all '*' (req, res, next) ->
	next!
	ua = if req.headers['user-agent']? then req.headers['user-agent'].to-lower-case! else null
	publish-redis-streaming \log to-json {
		type: \api
		value:
			date: Date.now!
			remote-addr: req.ip
			protocol: req.protocol
			method: req.method
			path: req.path
			ua: ua
			color: convert-string-to-color req.ip
			done: yes
	}

api-server.options '*' (req, res, next) ->
	res
		..set do
			'Access-Control-Allow-Headers': 'Origin, X-HTTP-Method-Override, X-Requested-With, Content-Type, Accept'
		..status 200
		..send!

router api-server

api-server.use (req, res, next) ->
	res.api-error 404 'API not found.'

exports.server = api-server
