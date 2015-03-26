#
# Resources router
#

require! {
	fs
	path
	express
	gm
	compression
	less
	'../../models/user': User
	'../../models/webtheme': Webtheme
	'../../config'
}

module.exports = (app) ->
	function compile-less (less-css, style-user, callback)
		color = if style-user? && style-user.color.match /#[a-fA-F0-9]{6}/
			then style-user.color
			else config.theme-color
		less.render do
			pre-compile less-css, style-user, color
			{ +compress }
			(, output) ->
				callback output.css
		
		# Analyze variable
		function pre-compile(less-css, style-user, color)
			less-css
				.replace do
					/<%themeColor%>/g
					color
				.replace do
					/<%wallpaperUrl%>/g
					if style-user?
						then "\"#{config.public-config.url}/img/wallpaper/#{style-user.screen-name}\""
						else ''
				.replace do
					/<%headerImageUrl%>/g
					if style-user?
						then "\"#{config.public-config.url}/img/header/#{style-user.screen-name}\""
						else ''
				.replace do
					/<%headerBlurImageUrl%>/g
					if style-user?
						then "\"#{config.public-config.url}/img/header/#{style-user.screen-name}?blur={radius: 64, sigma: 20}\""
						else ''
	
	function read-file-send-less(req, res, path, style-user)
		fs.read-file path, \utf8, (, less-css) ->
			compile-less less-css, style-user, (css) ->
				res
					..header 'Content-type' 'text/css'
					..send css
	
	# Theme
	app.get /^\/resources\/styles\/theme\/([a-zA-Z0-9_-]+).*/ (req, res, next) ->
		style-name = req.params.0
		theme-id = user.web-theme-id
		function send-theme-style(user)
			switch
			| theme-id == null => res.send!
			| _ => Webtheme.find-by-id theme-id, (, theme) ->
				| theme == null => res.send!
				| _ =>
					try
						theme-obj = JSON.parse theme.style
						if theme-obj[styleName]
							compile-less theme-obj[styleName], user, (css) ->
								res
									..header 'Content-type' 'text/css'
									..send css
						else
							res.send!
					catch e
						res
							..status 500
							..send 'Theme parse failed.'
		
		if req.query.user?
			User.find-one { screem-name: req.query.user } (, theme-user) ->
				if theme-user?
					send-theme-style theme-user
				else
					res
						..status 404
						..send 'User not found.'
		else
			app.init-session req, res, ->
				if req.login
					send-theme-style req.me
				else
					res.send!
	
	# General
	app.get /^\/resources\/.*/ (req, res, next) ->
		| (req.path.index-of '..') > -1 =>
			res
				..status 400
				..send 'invalid path'
		| _ =>
			| req.path.match /\.css$/ =>
				resource-path = path.resolve __dirname + '/..' + req.path.replace /\.css$/ '.less'
				if fs.exists-sync resource-path
					app.init-session req, res, ->
						| req.query.user? =>
							User.find-one { screen-name: req.query.user } (, style-user) ->
								read-file-send-less do
									req
									res
									resource-path
									if style-user? then styleUser else null
						| _ =>
							read-file-send-less do
								req
								res
								resource-path
								if req.login then req.me else null
			| req.url.index-of '.less' == -1 =>
				resource-path = path.resolve __dirname + '/..' + req.path
				res.send-file resource-path
			| _ => next!
