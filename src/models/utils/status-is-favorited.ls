require! {
	'../status-favorite': StatusFavorite
}

module.exports = (status-id, user-id, callback) ->
	callback StatusFavorite.find {status-id, user-id} .limit 1 .count! > 0
