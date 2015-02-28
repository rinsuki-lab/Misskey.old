/// <reference path="../../../typings/bundle.d.ts" />

import config = require('../../config');
import session = require('express-session');
import redis = require('redis');
import cookie = require('cookie');
import fs = require('fs');

export = sarver;

var sarver = (io: any, sessionStore: any): void => {
	io.of('/streaming/talk').on('connection',(socket: any) => {
		var cookies: any = cookie.parse(socket.handshake.headers.cookie);
		var sid = cookies[config.sessionKey];

		// Get session
		var sidkey = sid.match(/s:(.+?)\./)[1];
		sessionStore.get(sidkey,(err: any, session: any) => {
			if (err) {
				console.log(err.message);
			} else {
				if (session == null) {
					console.log('undefined: ' + sidkey);
					return;
				}
				var uid = socket.userId = session.userId;
				var publisher = redis.createClient();

				socket.emit('connected');

				socket.on('init',(req: any) => {
					var otherpartyId = String(req.otherparty_id);
					socket.otherpartyId = otherpartyId;

					var subscriber = redis.createClient();
					subscriber.subscribe('misskey:talkStream:' + uid + '-' + socket.otherpartyId);
					publisher.publish('misskey:talkStream:' + socket.otherpartyId + '-' + uid, 'otherpartyEnterTheTalk');

					socket.emit('inited');

					subscriber.on('message',(channel: any, content: any) => {
						try {
							content = JSON.parse(content);
							if (content.type != null && content.value != null) {
								socket.emit(content.type, content.value);
							} else {
								socket.emit(content);
							}
						} catch (e) {
							socket.emit(content);
						}
					});
				});

				socket.on('alive',(req: any) => {
					publisher.publish('misskey:talkStream:' + socket.otherpartyId + '-' + uid, 'alive');
				});

				socket.on('type',(req: any) => {
					publisher.publish('misskey:talkStream:' + socket.otherpartyId + '-' + uid, JSON.stringify({
						type: 'type',
						value: {
							text: req.text,
							userId: uid
						}
					}));
				});

				socket.on('disconnect',() => {
					publisher.publish('misskey:talkStream:' + socket.otherpartyId + '-' + uid, 'otherpartyLeftTheTalk');
				});
			}
		});
	});
};
