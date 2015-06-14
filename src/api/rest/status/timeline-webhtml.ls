require! {
	'../../auth': authorize
	'../../../utils/get-express-params'
	'../../../models/status': Status
	'../../../models/utils/status-get-timeline'
	'../../../web/utils/generate-timeline-status-html'
}

module.exports = (req, res) -> authorize req, res, (user, app) ->
	[since-cursor, max-cursor] = get-express-params req, <[ since-cursor, max-cursor ]>
	status-get-timeline do
		user.id
		30statuses
		if !empty since-cursor then since-cursor else null
		if !empty max-cursor then max-cursor else null
	.then (statuses) ->
		Promise.all (statuses |> map (status) ->
			resolve, reject <- new Promise!
			generate-timeline-status-html status, user .then (html) ->
				resolve html)
		.then (timeline-html) ->
			res.api-render timeline-html.join ''
