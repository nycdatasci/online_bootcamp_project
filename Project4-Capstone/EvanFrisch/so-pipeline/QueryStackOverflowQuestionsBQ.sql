SELECT
  questions.creation_date AS question_creation_date,
  questions.id AS question_id,
  REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(questions.title,",",""),"\"",""),"\'",""),"`",""),"’","") AS question_title,
  LENGTH(questions.body) AS question_body_length,
  ARRAY_LENGTH(REGEXP_EXTRACT_ALL(questions.body, "<pre><code>")) AS question_codeblock_count,
  questions.answer_count,
  questions.accepted_answer_id,
  questions.comment_count AS question_comment_count,
  questions.score AS question_score,
  questions.favorite_count AS question_favorite_count,
  questions.view_count AS question_view_count,
  questions.tags AS question_tags,
  questioner.id AS questioner_id,
  questioner.location AS questioner_location,
  questioner.reputation AS questioner_reputation,
  questioner.creation_date AS questioner_account_creation_date,
  questioner.up_votes AS questioner_up_votes,
  questioner.down_votes AS questioner_down_votes,
  questioner.views AS questioner_views,
  questioner.age AS questioner_age,
  LENGTH(questioner.about_me) AS questioner_profile_length,
  COUNT(answers.id) AS answer_count_computed,
  MIN(answers.creation_date) AS min_answer_creation_date,
  MAX(answers.score) AS max_answer_score
FROM
  `bigquery-public-data.stackoverflow.posts_questions` questions
JOIN 
  `bigquery-public-data.stackoverflow.users` questioner 
ON questioner.id = questions.owner_user_id
LEFT JOIN
  `bigquery-public-data.stackoverflow.posts_answers` answers
ON
  answers.parent_id = questions.id
WHERE
  questions.creation_date >= @start_date
  AND questions.creation_date < @end_date
GROUP BY
  questions.creation_date,
  questions.id,
  questions.title,
  questions.body,
  questions.answer_count,
  questions.accepted_answer_id,
  questions.comment_count,
  questions.score,
  questions.favorite_count,
  questions.view_count,
  questions.tags,
  questioner.id,
  questioner.location,
  questioner.reputation,
  questioner.creation_date,
  questioner.up_votes,
  questioner.down_votes,
  questioner.views,
  questioner.age,
  questioner.about_me
