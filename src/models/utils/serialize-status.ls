require! {
	'../application': Application
	'../user': User
	'../status': Status
	'./status-get-talk'
	'./status-get-replies'
	'../../config'
}

module.exports = (status, callback) ->
	function serialyze-repost(status, callback)
		switch
		| status.repost-from-status-id? =>
			Status.find-by-id status.repost-from-status-id, (, repost-from-status) ->
				| repost-from-status? =>
					_repost-from-status = repost-from-status.to-object!
						..is-repost-to-status = yes
						..source = status
					User.find-by-id status.user-id, (, reposted-by-user) ->
						reposted-by-user .= to-object!
						_repost-from-status.reposted-by-user = reposted-by-user
						callback _repost-from-status
				| _ =>
					status.is-repost-to-status = no
					callback status
		| _ =>
			status.is-repost-to-status = no
			callback status
	
	function get-app(status, callback)
		Application.find-by-id status.app-id, (, app) ->
			#delete app.consumer-key
			#delete app.callback-url
			status.app = app.to-object!
			callback status
	
	function get-user(status, callback)
		User.find-by-id status.user-id, (, user) ->
			status.user = user.to-object!
			callback status
	
	function get-reply-source(status, callback)
		switch
		| !status.is-reply => callback status
		| _ =>
			Status.find-by-id status.in-reply-to-status-id, (, reply-status) ->
				| !reply-status? =>
					status.is-reply = no
					callback status
				| _ =>
					reply-status .= to-object!
					reply-status.is-reply = reply-status.in-reply-to-status-id?
					status.reply-source = reply-status
					User.find-by-id reply-status.user-id, (, reply-user) ->
						reply-user .= to-object!
						status.reply-source.user = reply-user
						if reply-status.is-reply
							status-get-talk reply-status, (talk) ->
								status.more-talk = talk
								callback status
						else
							callback status
	
	function get-replies(status, callback)
		status-get-replies status .then (replies) ->
			| !replies? or empty replies => callback status
			| _ => 
				Promise.all (replies |> map (reply) ->
					new Promise (resolve, reject) ->
						if reply?
							User.find-by-id reply.user-id, (, reply-user) ->
								reply .= to-object!
								reply.is-reply = reply.in-reply-to-status-id?
								reply.user = reply-user.to-object!
								resolve reply
						else
							resolve null)
					.then (replies) ->
						status.replies = replies
						callback status
	
	console.log "- #{user.screen-name} #{new Date!}"
	status .= to-object!
	console.log "- #{user.screen-name} #{new Date!}"
	status <- serialyze-repost status
	console.log "- #{user.screen-name} #{new Date!}"
	status.is-reply = status.in-reply-to-status-id?
	console.log "- #{user.screen-name} #{new Date!}"
	status <- get-app status
	console.log "- #{user.screen-name} #{new Date!}"
	status <- get-user status
	console.log "- #{user.screen-name} #{new Date!}"
	status <- get-reply-source status
	console.log "- #{user.screen-name} #{new Date!}"
	status <- get-replies status
	console.log "- #{user.screen-name} #{new Date!}"
	callback status
	