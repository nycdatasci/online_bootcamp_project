SELECT
  users.id AS user_id,
  users.display_name AS user_display_name,
  users.reputation AS user_reputation,
  users.up_votes AS user_up_votes,
  users.down_votes AS user_down_votes,
  users.views AS user_views,
  users.profile_image_url AS user_profile_image_url,
  users.website_url AS user_website_url,
  COUNT(DISTINCT questions.id) AS questions_count,
  COUNT(DISTINCT answers.id) AS answers_count,
  COUNT(DISTINCT comments.id) AS comments_count,
  SUM(questions.score) AS questions_total_score,
  SUM(answers.score) AS answers_total_score,
  SUM(comments.score) AS comments_total_score,
  SUM(questions.view_count) AS questions_view_count,
  SUM(answers.comment_count) AS answers_comments_count
FROM
  `bigquery-public-data.stackoverflow.users` users
LEFT JOIN
  `bigquery-public-data.stackoverflow.posts_questions` questions
ON
  questions.owner_user_id = users.id
LEFT JOIN
  `bigquery-public-data.stackoverflow.posts_answers` answers
ON
  answers.owner_user_id = users.id
LEFT JOIN
  `bigquery-public-data.stackoverflow.comments` comments
ON
  comments.user_id = users.id
WHERE
  users.creation_date >= "2013-09-01 00:00:00 UTC"
  AND users.creation_date < "2013-10-01 00:00:00 UTC"
  AND questions.creation_date >= "2013-09-01 00:00:00 UTC"
  AND questions.creation_date < "2014-09-01 00:00:00 UTC"
  AND answers.creation_date >= "2013-09-01 00:00:00 UTC"
  AND answers.creation_date < "2014-09-01 00:00:00 UTC"
  AND comments.creation_date >= "2013-09-01 00:00:00 UTC"
  AND comments.creation_date < "2014-09-01 00:00:00 UTC"
GROUP BY
  users.id,
  users.display_name,
  users.reputation,
  users.up_votes,
  users.down_votes,
  users.views,
  users.profile_image_url,
  users.website_url
