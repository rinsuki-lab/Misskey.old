require! {
	async
	'../../models/utils/get-followings-count'
	'../../models/utils/get-followers-count'
	'../../models/utils/get-statuses-count'
	'../../models/utils/status-get-timeline'
	'../../models/utils/status-get-mentions'
	'../../models/utils/get-new-users'
	'../../models/utils/user-following-check'
	'../utils/timeline-generate-html'
}

status-gets =
	home: status-get-timeline
	mention: status-get-mentions

module.exports = (req, res, content = \home) ->
	me = req.me
	async.series [
		(next) -> get-statuses-count me.id .then (count) -> next null, count
		(next) -> get-followings-count me.id .then (count) -> next null, count
		(next) -> get-followers-count me.id .then (count) -> next null, count
		(next) -> status-gets[content] me.id, 30statuses, null, null, (statuses) ->
			timeline-generate-html statuses, me, (timeline-html) -> next null, timeline-html
		(next) -> get-new-users 5 .then (users) ->
			Promise.all users |> map (user) ->
				new Promise (on-fulfilled, on-rejected) ->
					user .= to-object!
					user-following-check me.id, user.id .then (is-following) ->
						user.is-following = is-following
						on-fulfilled user
				.then (res) ->
					next null, res
	], (, results) -> res.display req, res, 'home' do
		statuses-count: results.0
		followings-count: results.1
		followers-count: results.2
		timeline-html: results.3
		recommendation-users: results.4
