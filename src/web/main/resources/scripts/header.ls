window.music-center-open = no

function update-statuses
	$.ajax "#{config.api-url}/account/unreadalltalks-count" {
		type: \get
		data-type: \json
		xhr-fields: {+with-credentials}}
	.done (result) ->
		if $ '#misskey-main-header > .main .mainContentsContainer .left nav .mainNav ul .talk a .unreadCount' .0
			$ '#misskey-main-header > .main .mainContentsContainer .left nav .mainNav ul .talk a .unreadCount' .remove!
		if result != 0
			$ '#misskey-main-header > .main .mainContentsContainer .left nav .mainNav ul .talk a' .append do
				$ '<span class="unreadCount">' .text result
	.fail ->

$ ->
	update-statuses!
	set-interval update-statuses, 10000ms

	$ '#misskey-main-header > .main .mainContentsContainer .left nav .mainNav .misskey' .click ->
		if window.music-center-open
			$ '#misskey-main-header > .informationCenter' .css \height '0'
		else
			$ '#misskey-main-header > .informationCenter' .css \height '200px'
		window.music-center-open = !music-center-open
	
	$ '#misskey-main-header > .main .mainContentsContainer .left nav .mainNav ul .talk a' .click ->
		window-id = "misskey-window-talk-histories"
		$content = $ '<iframe>' .attr {src: '/i/talks', +seamless}
		window.open-window do
			window-id
			$content
			"<i class=\"fa fa-comments\"></i>トーク"
			500px
			560px
			yes
			'/i/talks'
		false
	
	$ \body .css \margin-top "#{$ 'body > #misskey-main-header' .outer-height!}px"

	$ '#misskey-main-header .search input' .bind \input ->
		$input = $ @
		$result = $ '#misskey-main-header .search .result'
		if $input .val! == ''
			$result.empty!
		else
			$.ajax "#{config.api-url}/search/user" {
				type: \get
				data: {'query': $input .val!}
				data-type: \json
				xhr-fields: {+with-credentials}}
			.done (result) ->
				$result.empty!
				if (result.length > 0) && ($input .val! != '')
					$result.append $ '<ol class="users">'
					result.for-each (user) ->
						$result.find \ol .append do
							$ \<li> .append do
								$ '<a class="ui-waves-effect">' .attr {
									'href': "#{config.url}/#{user.screen-name}"
									'title': user.comment}
								.append do
									$ '<img class="icon" alt="icon">' .attr \src user.icon-image-url
								.append do
									$ '<span class="name">' .text user.name
								.append do
									$ '<span class="screen-name">' .text "@#{user.screen-name}"
					window.init-waves-effects!
			.fail ->

$ window .load ->
	header-height = $ 'body > #misskey-main-header' .outer-height!
	$ \body .css \margin-top "#{header-height}px"
	$ \html .css \background-position "center #{header-height}px"
	$ '[data-ui-background-wallpaper-blur="true"]' .each ->
		$ @ .css \background-position "center #{header-height}px"
		
