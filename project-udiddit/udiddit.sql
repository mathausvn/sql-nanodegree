/*
	Student name: Mathaus Vila Nova
	LinkedIn: https://www.linkedin.com/in/mathausvilanova/
	Course: Udacity SQL Nanodegree Program
	
	Udiddit Project - New Table Schema
*/

CREATE TABLE users (
	id SERIAL PRIMARY KEY,
	username VARCHAR(25) NOT NULL UNIQUE CHECK(LENGTH(TRIM("username")) > 0),
	register_date DATE NOT NULL DEFAULT CURRENT_DATE,
	last_login_date DATE DEFAULT NULL
);

CREATE TABLE topics (
	id SERIAL PRIMARY KEY,
	topic_name VARCHAR(30) NOT NULL UNIQUE CHECK(LENGTH(TRIM("topic_name")) > 0),
	topic_desc VARCHAR(500) DEFAULT NULL,
	created_by INTEGER,
	CONSTRAINT "user_id_fk"
		FOREIGN KEY ("created_by")
			REFERENCES users("id") ON DELETE SET NULL
);

CREATE TABLE posts (
	id SERIAL PRIMARY KEY,
	title VARCHAR(100) NOT NULL CHECK(LENGTH(TRIM("title")) > 0),
	url VARCHAR(4000) DEFAULT NULL,
	content TEXT DEFAULT NULL,
	topic_id INTEGER,
	created_by INTEGER,
	CONSTRAINT "post_url_or_content"
		CHECK (
			(NULLIF (TRIM("url"), '') IS NULL OR NULLIF (TRIM("content"), '') IS NULL)
			AND 
			NOT (NULLIF (TRIM("url"), '') IS NULL AND NULLIF (TRIM("content"), '') IS NULL) 
		),
	CONSTRAINT "topic_id_fk"
		FOREIGN KEY ("topic_id")
			REFERENCES topics("id") ON DELETE CASCADE,
	CONSTRAINT "user_id_fk"
		FOREIGN KEY ("created_by")
			REFERENCES users("id") ON DELETE SET NULL
);

CREATE TABLE post_comments (
	id SERIAL PRIMARY KEY,
	comment TEXT NOT NULL CHECK(LENGTH(TRIM("comment")) > 0),
	post_id INTEGER,
	parent_comment_id INTEGER DEFAULT NULL,
	created_by INTEGER,
	CONSTRAINT "post_id_fk"
		FOREIGN KEY ("post_id")
			REFERENCES posts("id") ON DELETE CASCADE,
	CONSTRAINT "post_comment_id_fk"
		FOREIGN KEY ("parent_comment_id")
			REFERENCES post_comments("id") ON DELETE CASCADE,
	CONSTRAINT "user_id_fk"
		FOREIGN KEY ("created_by")
			REFERENCES users("id") ON DELETE SET NULL
);

CREATE TABLE post_votes (
	id SERIAL PRIMARY KEY,
	vote BOOLEAN,
	post_id INTEGER,
	created_by INTEGER,
	UNIQUE (post_id,created_by),
	CONSTRAINT "post_id_fk"
		FOREIGN KEY ("post_id")
			REFERENCES posts("id") ON DELETE CASCADE,
	CONSTRAINT "user_id_fk"
		FOREIGN KEY ("created_by")
			REFERENCES users("id") ON DELETE SET NULL
);

/* Indexes */

CREATE INDEX "post_url_idx" ON posts("url");

/***************************************************************************/

/*
	Student name: Mathaus Vila Nova
	LinkedIn: https://www.linkedin.com/in/mathausvilanova/
	Course: Udacity SQL Nanodegree Program
	
	Udiddit Project - Data Migration
*/

/* 1. Populating users table */
INSERT INTO users (username) (
	(SELECT DISTINCT username FROM bad_posts WHERE username IS NOT NULL)
	UNION
	(SELECT DISTINCT username FROM bad_comments WHERE username IS NOT NULL)
	UNION
	(SELECT DISTINCT regexp_split_to_table(downvotes, ',') AS username FROM bad_posts)
	UNION
	(SELECT DISTINCT regexp_split_to_table(upvotes, ',') AS username FROM bad_posts)
	ORDER BY username
);

/* 2. Populating topics table */
INSERT INTO topics (topic_name) (
	SELECT DISTINCT INITCAP(bp.topic) AS topic_name
	FROM bad_posts bp
	ORDER BY 1
);

/* 3. Populating posts table */
INSERT INTO posts (title, url, content, topic_id, created_by) (
	SELECT
		CONCAT(LEFT(bp.title, 97), '...') AS title,
		bp.url AS url,
		bp.text_content AS content,
		tp.id AS topic_id,
		u.id AS created_by
	FROM
		bad_posts bp
		LEFT JOIN topics tp ON tp.topic_name = INITCAP(bp.topic)
		LEFT JOIN users u ON u.username = bp.username
);

/* 4. Populating post_comments table */
INSERT INTO post_comments (comment, post_id, created_by) (
	SELECT
		bc.text_content AS comment,
		bc.post_id AS post_id,
		u.id AS created_by
	FROM
		bad_comments bc
		INNER JOIN users u ON u.username = bc.username
		INNER JOIN posts p ON p.id = bc.post_id
);

/* 5. Populating post_votes table */
INSERT INTO post_votes (vote, post_id, created_by) (
	/* SELECT statement considering 'dislikes' votes */
	(SELECT
		t1.vote AS vote,
		t1.post_id AS post_id,
		u.id AS created_by
	FROM (
		SELECT
			p.id AS post_id,
			regexp_split_to_table(bp.downvotes, ',') AS username,
			false AS vote
		FROM
			bad_posts bp
			LEFT JOIN posts p ON p.title = CONCAT(LEFT(bp.title, 97), '...')
	) AS t1
	LEFT JOIN users u ON t1.username = u.username)
	
	UNION
	
	/* SELECT statement considering 'likes' votes */
	(SELECT
		t1.vote AS vote,
		t1.post_id AS post_id,
		u.id AS created_by
	FROM (
		SELECT
			p.id AS post_id,
			regexp_split_to_table(bp.upvotes, ',') AS username,
			true AS vote
		FROM
			bad_posts bp
			LEFT JOIN posts p ON p.title = CONCAT(LEFT(bp.title, 97), '...')
	) AS t1
	LEFT JOIN users u ON t1.username = u.username)
);
