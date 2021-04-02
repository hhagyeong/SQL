# 상품 리뷰 데이터(dateset2)를 이용한 리포트 작성

# 1. Division별 평점 분포 계산

#  1) Division별 평균 평점 계산

#   A) DivisionName별 평균 평점
SELECT DivisionName, AVG(RATING) AVG_RATE
  FROM MYDATA.DATASET2
 GROUP BY 1
 ORDER BY 2 DESC;
 
#   B) DepartmentName별 평균 평점
SELECT DepartmentName, AVG(RATING) AVG_RATE
  FROM MYDATA.DATASET2
 GROUP BY 1
 ORDER BY 2 DESC;
 
# Trend의 평점이 상위 5개 대비 낮게 나타나므로 살펴봐야 함
# Trend의 평점 3점 이하 리뷰
SELECT *
  FROM MYDATA.DATASET2
 WHERE DepartmentName = 'Trend'
   AND RATING<=3;
   
#  2) case when
# 10세 단위로 연령 그루핑하기
SELECT CASE WHEN AGE BETWEEN 0 AND 9 THEN '0009'
			WHEN AGE BETWEEN 10 AND 19 THEN '1019'
            WHEN AGE BETWEEN 20 AND 29 THEN '2029'
            WHEN AGE BETWEEN 30 AND 39 THEN '3039'
            WHEN AGE BETWEEN 40 AND 49 THEN '4049'
            WHEN AGE BETWEEN 50 AND 59 THEN '5059'
            WHEN AGE BETWEEN 60 AND 69 THEN '6069'
            WHEN AGE BETWEEN 70 AND 79 THEN '7079'
            WHEN AGE BETWEEN 80 AND 89 THEN '8089'
            WHEN AGE BETWEEN 90 AND 99 THEN '9099' END AGEBAND,
	   AGE
  FROM MYDATA.DATASET2
 WHERE DepartmentName = 'Trend'
   AND RATING<=3;

#  3) FLOOR
SELECT FLOOR(AGE/10) * 10 AGEBAND,
	   AGE
  FROM MYDATA.DATASET2
 WHERE DepartmentName = 'Trend'
   AND RATING<=3;

#   A) Trend의 평점 3점 이하 리뷰의 연령 분포
SELECT FLOOR(AGE/10) * 10 AGEBAND,
	   COUNT(*) CNT
  FROM MYDATA.DATASET2
 WHERE DepartmentName='Trend'
   AND RATING<=3
 GROUP BY 1
 ORDER BY 2 DESC;
 
#   B) DepartmentName별 연령별 리뷰 수
SELECT FLOOR(AGE/10) * 10 AGEBAND,
	   COUNT(*) CNT
  FROM MYDATA.DATASET2
 WHERE DepartmentName = 'Trend'
 GROUP BY 1
 ORDER BY 2 DESC;
 
#   C) 50대 3점 이하 Trend 리뷰
SELECT *
  FROM MYDATA.DATASET2
 WHERE DepartmentName = 'Trend'
   AND RATING<=3
   AND AGE BETWEEN 50 AND 59;
   
# 2. 평점이 낮은 상품의 주요 Complain

#  1) DepartmentName, ClothingID별 평균 평점 계산
SELECT DepartmentName, ClothingID,
	   AVG(RATING) AVG_RATE
  FROM MYDATA.DATASET2
 GROUP BY 1, 2;
 
#  2) Department별 순위 생성
SELECT *,
	   ROW_NUMBER() OVER(PARTITION BY DepartmentName ORDER BY AVG_RATE) RNK
  FROM (SELECT DepartmentName, ClothingID,
			   AVG(RATING) AVG_RATE
		  FROM MYDATA.DATASET2
		 GROUP BY 1, 2) A;
         
#  3) 1~10위 데이터 조회
SELECT *
  FROM (SELECT *,
			   ROW_NUMBER() OVER( PARTITION BY DepartmentName ORDER BY AVG_RATE) RNK
		  FROM (SELECT DepartmentName, ClothingID,
					   AVG(RATING) AVG_RATE
				  FROM MYDATA.DATASET2
				 GROUP BY 1, 2) A
		) A
 WHERE RNK<=10;
 
#   A) DepartmentName별 평균 평점이 낮은 10개 상품
# 데이터 조회 결과 MYDATA.STAT테이블로 생성
CREATE TEMPORARY TABLE MYDATA.STAT AS
SELECT *
  FROM (SELECT *,
			   ROW_NUMBER() OVER (PARTITION BY DepartmentName ORDER BY AVG_RATE) RNK
		  FROM (SELECT DepartmentName, ClothingID,
					   AVG(RATING) AVG_RATE
				  FROM MYDATA.DATASET2
				 GROUP BY 1, 2) A
		) A
 WHERE RNK<=10;
 
# Bottoms의 평점이 낮은 10개 상품의 ClothingID 조회
SELECT ClothingID
  FROM MYDATA.STAT
 WHERE DepartmentName = 'Bottoms';
 
# Bottoms의 평점이 낮은 10개 상품의 리뷰 조회
SELECT *
  FROM MYDATA.DATASET2
 WHERE ClothingID IN (SELECT ClothingID
					    FROM MYDATA.DATASET2
					   WHERE DepartmentName = 'Bottoms')
 ORDER BY ClothingID;