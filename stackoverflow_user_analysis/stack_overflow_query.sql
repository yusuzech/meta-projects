#query5
#(1)-------------------------------------------------------------
	                PK	                               FK			
Users 	            id				
posts_questions 	id	accepted_answer_id	owner_user_id	post_type_id	
comments 	        id	post_id	user_id		
posts_answers	    id	last_editor_user_id	owner_user_id	parent_id	  post_type_id


#(2)-------------------------------------------------------
SELECT *, SUM(monthly_new_users) OVER (ORDER BY year_month) AS total_users
FROM
	(
	SELECT *
	FROM
		(
		SELECT  DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month,
		  COUNT(*) AS monthly_new_users
		FROM `bigquery-public-data.stackoverflow.users` 
		GROUP BY  DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY)
		)
	ORDER BY  year_month
	)

#(3)---------------------------------------------------------------------------------
SELECT *, 
	LAG(monthly_new_users,12) OVER (ORDER BY year_month) AS last_year_montly_new_users,
	LAG(total_users,12) OVER (ORDER BY year_month) AS last_year_total_new_users
FROM
	(
	SELECT *, SUM(monthly_new_users) OVER (ORDER BY year_month) AS total_users
	FROM
		(
		SELECT *
		FROM
			(
			SELECT  DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month,
			  COUNT(*) AS monthly_new_users
			FROM `bigquery-public-data.stackoverflow.users` 
			GROUP BY  DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY)
			)
		ORDER BY  year_month
		)
	)
	
#(4)-------------------------------------------------------------------------------------
#This calculate total active users
SELECT DISTINCT year_month,COUNT(*) AS active_users
FROM
	(
	SELECT *
	FROM
		(
		SELECT DISTINCT user_id,year_month
		FROM
			(
			SELECT owner_user_id AS user_id,
				DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
			FROM `bigquery-public-data.stackoverflow.posts_answers` 
			UNION ALL
			SELECT last_editor_user_id AS user_id,
				DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
			FROM `bigquery-public-data.stackoverflow.posts_answers` 
			)
		GROUP BY user_id,year_month 
		)
	WHERE user_id IS NOT NULL
	AND year_month IS NOT NULL

	UNION DISTINCT

	SELECT *
	FROM
		(
		SELECT DISTINCT user_id,year_month
		FROM
			(
			SELECT owner_user_id AS user_id,
				DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
			FROM `bigquery-public-data.stackoverflow.posts_questions` 
			UNION ALL
			SELECT last_editor_user_id AS user_id,
				DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
			FROM `bigquery-public-data.stackoverflow.posts_questions` 
			)
		GROUP BY user_id,year_month
		)
	WHERE user_id IS NOT NULL
	AND year_month IS NOT NULL

	UNION DISTINCT

	SELECT *
	FROM
		(
		SELECT DISTINCT user_id,year_month
		FROM
			(
			SELECT user_id AS user_id,
				DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
			FROM `bigquery-public-data.stackoverflow.comments`  
			)
		GROUP BY user_id,year_month 
		)
	WHERE user_id IS NOT NULL
	AND year_month IS NOT NULL
	)
GROUP BY year_month
ORDER BY year_month

#(5)------------------------------------------------------------------
#This mark user status for questions, answers and comments (1 for active and 0 for inactive)
WITH
	tb1 AS 
		(
		SELECT DISTINCT year_month, user_id
		FROM
			(
			SELECT *
			FROM
				(
				SELECT DISTINCT user_id,year_month
				FROM
					(
					SELECT owner_user_id AS user_id,
						DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
					FROM `bigquery-public-data.stackoverflow.posts_questions` 
					UNION ALL
					SELECT last_editor_user_id AS user_id,
						DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
					FROM `bigquery-public-data.stackoverflow.posts_questions` 
					)
				GROUP BY user_id,year_month
				)
			WHERE user_id IS NOT NULL
			AND year_month IS NOT NULL
			)
		GROUP BY year_month,user_id
		)
	,
	tb2 AS
		(
		SELECT DISTINCT year_month, user_id
		FROM
			(
			SELECT *
			FROM
				(
				SELECT *
				FROM
					(
					SELECT DISTINCT user_id,year_month
					FROM
						(
						SELECT owner_user_id AS user_id,
							DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
						FROM `bigquery-public-data.stackoverflow.posts_questions` 
						UNION ALL
						SELECT last_editor_user_id AS user_id,
							DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
						FROM `bigquery-public-data.stackoverflow.posts_questions` 
						)
					GROUP BY user_id,year_month
					)
				WHERE user_id IS NOT NULL
				AND year_month IS NOT NULL
				)
		GROUP BY year_month,user_id
			)
		)
	,
	tb3 AS
		(
		SELECT DISTINCT year_month, user_id
		FROM
			(
			SELECT *
			FROM
				(
				SELECT DISTINCT user_id,year_month
				FROM
					(
					SELECT user_id AS user_id,
						DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
					FROM `bigquery-public-data.stackoverflow.comments`  
					)
				GROUP BY user_id,year_month 
				)
			WHERE user_id IS NOT NULL
			AND year_month IS NOT NULL
			)
		GROUP BY year_month,user_id
		)
	,
	tb4 AS 
		(
		SELECT tb00.user_id,tb00.year_month,tb000.year_month AS creation_date
		FROM
			(
			SELECT DISTINCT id AS user_id, tb0.year_month
			FROM `bigquery-public-data.stackoverflow.users` 
			CROSS JOIN
				(
				SELECT DISTINCT DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
				FROM `bigquery-public-data.stackoverflow.posts_answers`
				) tb0
			) tb00
		LEFT JOIN 
			(
			SELECT  DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month,
				id AS user_id
			FROM `bigquery-public-data.stackoverflow.users`
			) tb000
		ON tb00.user_id = tb000.user_id
		WHERE tb000.year_month <= tb00.year_month
		)
		
		
SELECT year_month,user_id,question_flag,answer_flag,comment_flag
FROM 
	(
	SELECT year_month,user_id,
		CASE WHEN question_flag IS NULL THEN 0 ELSE 1 END AS question_flag,
		CASE WHEN answer_flag IS NULL THEN 0 ELSE 1 END AS answer_flag,
		CASE WHEN comment_flag IS NULL THEN 0 ELSE 1 END AS comment_flag
	FROM 
		(
		SELECT tb6.year_month, tb6.user_id, tb6.question_flag, tb6.answer_flag,tb3.user_id AS comment_flag,tb6.creation_date
		FROM 
			(
			SELECT tb5.year_month, tb5.user_id, tb5.question_flag, tb2.user_id AS answer_flag,tb5.creation_date
			FROM
				(
				SELECT tb4.year_month, tb4.user_id,tb1.user_id AS question_flag,tb4.creation_date
				FROM tb4
				LEFT JOIN tb1
				ON tb4.year_month = tb1.year_month
				AND tb4.user_id = tb1.user_id
				) tb5
			LEFT JOIN tb2
			ON tb5.year_month = tb2.year_month
			AND tb5.user_id = tb2.user_id
			) tb6
		LEFT JOIN tb3
		ON tb6.year_month = tb3.year_month
		AND tb6.user_id = tb3.user_id
		) 	
	)
WHERE question_flag = 1
OR answer_flag = 1 
OR comment_flag = 1			
#(6)----------------------------------------------------------------------------------------
WITH
	tb1 AS 
		(
		SELECT DISTINCT year_month, user_id
		FROM
			(
			SELECT *
			FROM
				(
				SELECT DISTINCT user_id,year_month
				FROM
					(
					SELECT owner_user_id AS user_id,
						DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
					FROM `bigquery-public-data.stackoverflow.posts_questions` 
					UNION ALL
					SELECT last_editor_user_id AS user_id,
						DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
					FROM `bigquery-public-data.stackoverflow.posts_questions` 
					)
				GROUP BY user_id,year_month
				)
			WHERE user_id IS NOT NULL
			AND year_month IS NOT NULL
			)
		GROUP BY year_month,user_id
		)
	,
	tb2 AS
		(
		SELECT DISTINCT year_month, user_id
		FROM
			(
			SELECT *
			FROM
				(
				SELECT *
				FROM
					(
					SELECT DISTINCT user_id,year_month
					FROM
						(
						SELECT owner_user_id AS user_id,
							DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
						FROM `bigquery-public-data.stackoverflow.posts_questions` 
						UNION ALL
						SELECT last_editor_user_id AS user_id,
							DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
						FROM `bigquery-public-data.stackoverflow.posts_questions` 
						)
					GROUP BY user_id,year_month
					)
				WHERE user_id IS NOT NULL
				AND year_month IS NOT NULL
				)
		GROUP BY year_month,user_id
			)
		)
	,
	tb3 AS
		(
		SELECT DISTINCT year_month, user_id
		FROM
			(
			SELECT *
			FROM
				(
				SELECT DISTINCT user_id,year_month
				FROM
					(
					SELECT user_id AS user_id,
						DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
					FROM `bigquery-public-data.stackoverflow.comments`  
					)
				GROUP BY user_id,year_month 
				)
			WHERE user_id IS NOT NULL
			AND year_month IS NOT NULL
			)
		GROUP BY year_month,user_id
		)
	,
	tb4 AS 
		(
		SELECT tb00.user_id,tb00.year_month,tb000.year_month AS creation_date
		FROM
			(
			SELECT DISTINCT id AS user_id, tb0.year_month
			FROM `bigquery-public-data.stackoverflow.users` 
			CROSS JOIN
				(
				SELECT DISTINCT DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month
				FROM `bigquery-public-data.stackoverflow.posts_answers`
				) tb0
			) tb00
		LEFT JOIN 
			(
			SELECT  DATE_SUB(DATE_TRUNC(DATE_ADD(EXTRACT(DATE FROM creation_date), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) AS year_month,
				id AS user_id
			FROM `bigquery-public-data.stackoverflow.users`
			) tb000
		ON tb00.user_id = tb000.user_id
		WHERE tb000.year_month <= tb00.year_month
		)
		
SELECT year_month,user_id,
	CASE WHEN creation_date = year_month THEN 'New' ELSE 'Ret' END AS new_or_returning,
	question_flag,answer_flag,comment_flag
FROM 
	(
	SELECT year_month,user_id,question_flag,answer_flag,comment_flag,creation_date
	FROM 
		(
		SELECT year_month,user_id,
			CASE WHEN question_flag IS NULL THEN 0 ELSE 1 END AS question_flag,
			CASE WHEN answer_flag IS NULL THEN 0 ELSE 1 END AS answer_flag,
			CASE WHEN comment_flag IS NULL THEN 0 ELSE 1 END AS comment_flag,
			creation_date
		FROM 
			(
			SELECT tb6.year_month, tb6.user_id, tb6.question_flag, tb6.answer_flag,tb3.user_id AS comment_flag,tb6.creation_date
			FROM 
				(
				SELECT tb5.year_month, tb5.user_id, tb5.question_flag, tb2.user_id AS answer_flag,tb5.creation_date
				FROM
					(
					SELECT tb4.year_month, tb4.user_id,tb1.user_id AS question_flag,tb4.creation_date
					FROM tb4
					LEFT JOIN tb1
					ON tb4.year_month = tb1.year_month
					AND tb4.user_id = tb1.user_id
					) tb5
				LEFT JOIN tb2
				ON tb5.year_month = tb2.year_month
				AND tb5.user_id = tb2.user_id
				) tb6
			LEFT JOIN tb3
			ON tb6.year_month = tb3.year_month
			AND tb6.user_id = tb3.user_id
			) 	
		)
	WHERE question_flag = 1
	OR answer_flag = 1 
	OR comment_flag = 1			
	)
ORDER BY year_month,user_id
		