WITH RECURSIVE cte AS (SELECT 0 AS HOUR
                        UNION ALL
                       SELECT HOUR + 1
                         FROM cte
                        WHERE HOUR < 23 )
SELECT cte.hour, COUNT(ani.ANIMAL_ID)
  FROM cte
  LEFT
  JOIN ANIMAL_OUTS AS ani
    ON cte.hour = HOUR(ani.DATETIME)
 GROUP BY cte.hour;
