/// <reference path="../../../typings/bundle.d.ts" />

import db = require('./db');
export = Post;

class Post {
	appId: number;
	createdAt: string;
	id: number;
	inReplyToPostId: number;
	image: string;
	isImageAttached: boolean;
	text: string;
	userId: number;
	
	public constructor(post: any) {
		this.appId = post.app_id;
		this.createdAt = post.created_at;
		this.id = post.id;
		this.inReplyToPostId = post.in_reply_to_post_id;
		this.image = post.image;
		this.isImageAttached = Boolean(post.is_image_attached);
		this.text = post.text;
		this.userId = post.user_id;
	}

	public static create(appId: number, inReplyToPostId: number, image: string, isImageAttached: Boolean, text: string, userId: number, callback: (post: Post) => void): void {
		db.query('insert into posts (app_id, in_reply_to_post_id, image, is_image_attached, text, user_id) values (?, ?, ?, ?, ?, ?)',
			[appId, inReplyToPostId, image, isImageAttached, text, userId],
			(err, posts) => callback(new Post(posts[0])));
	}

	public static find(id: number, callback: (post: Post) => void): void {
		db.query("select * from posts where id = ?",
			[id],
			(err, posts) => callback(new Post(posts[0])));
	}

	public static findByUserId(userId: number, limit: number, sinceId: number, maxId: number, callback: (posts: Post[]) => void): void {
		var q, p;
		if ((sinceId === null) && (maxId === null)) {
			q = "select * from posts where user_id = ? order by id desc limit ?";
			p = [userId, limit];
		} else if (sinceId !== null) {
			q = "select * from posts where user_id = ? and id > ? order by id desc limit ?";
			p = [userId, sinceId, limit];
		} else if (maxId !== null) {
			q = "select * from posts where user_id = ? and id < ? order by id desc limit ?";
			p = [userId, maxId, limit];
		}
		db.query(q, p, (err, posts: any[]) => callback(posts.map((post) => new Post(post))));
	}

	public static getTimeline(userId: number, limit: number, sinceId: number, maxId: number, callback: (posts: Post[]) => void): void {
		UserFollowing.findByFollowerId(userId, (userFollowings: UserFollowing[]) => {
			var followingsStr = null;
			if (userFollowings.length !== 0) {
				followingsStr = userFollowings.join(',');
			}
			var q, p;
			if ((sinceId === null) && (maxId === null)) {
				q = "select * from posts where " + (followingsStr !== null ? "user_id in (" + followingsStr + ") or " : "") + "user_id = ? order by id desc limit ?";
				p = [userId, limit];
			} else if (sinceId !== null) {
				q = "select * from posts where (" + (followingsStr !== null ? "user_id in (" + followingsStr + ") or " : "") + "user_id = ?) and id > ? order by id desc limit ?";
				p = [userId, sinceId, limit];
			} else if (maxId !== null) {
				q = "select * from posts where (" + (followingsStr !== null ? "user_id in (" + followingsStr + ") or " : "") + "user_id = ?) and id < ? order by id desc limit ?";
				p = [userId, maxId, limit];
			}
			db.query(q, p, (err, posts: any[]) => callback(posts.map((post) => new Post(post))));
		});
	}

	public static getCircleTimeline(circleId: number, limit: number, sinceId: number, maxId: number, callback: (posts: Post[]) => void): void {
		CircleMember.findByCircleId(circleId, (circleMembers: CircleMember[]) => {
			var circleMembersStr = circleMembers.join(',');
			var q, p;
			if ((sinceId === null) && (maxId === null)) {
				q = "select * from posts where user_id in (" + circleMembersStr + ") order by id desc limit ?";
				p = [limit];
			} else if (sinceId !== null) {
				q = "select * from posts where user_id in (" + circleMembersStr + ") and id > ? order by id desc limit ?";
				p = [sinceId, limit];
			} else if (maxId !== null) {
				q = "select * from posts where user_id in (" + circleMembersStr + ") and id < ? order by id desc limit ?";
				p = [maxId, limit];
			}
			db.query(q, p, (err, posts: any[]) => callback(posts.map((post) => new Post(post))));
		});
    }

    public update(callback?: () => void): void {
        db.query("UPDATE posts SET user_id=?, app_id=?, in_reply_to_post_id=?, text=? WHERE id=?",
            [this.userId, this.appId, this.inReplyToPostId, this.text, this.id],
            callback);
    }
}
