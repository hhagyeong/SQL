# 1. 요인별 생존 여부 관계
#  1) 성별
# PassengerId를 카운트해서 승객 수 집계하기
# PassengerId에 중복이 존재하는지 확인
SELECT COUNT(PASSENGERID) N_PASSENGERS,
       COUNT(DISTINCT PASSENGERID) N_D_PASSENGERS
  FROM MYDATA.DATASET4;
# PassengerId에 중복 존재하지 않음
  
# 성별에 따른 승객 수와 생존자 수 구하기
# Survived(생존 여부)에서 1은 생존, 0은 사망을 의미하므로, Survived의 합을 구하면 생존자의 수를 계산할 수 있음
SELECT SEX,
       COUNT(PASSENGERID) N_PASSENGERS,
       SUM(SURVIVED) N_SURVIVED
  FROM MYDATA.DATASET4
 GROUP BY 1;

# 성별 탑승객 수와 생존자 수 비중 구하기
SELECT SEX,
       COUNT(PASSENGERID) N_PASSENGERS,
	   SUM(SURVIVED) N_SURVIVED,
       SUM(SURVIVED)/COUNT(PASSENGERID) SURVIVED_RATIO
  FROM MYDATA.DATASET4
 GROUP BY 1;
# 남성이 여성보다 더 많이 탑승했고, 생존율은 여성이 남성보다 약 55% 높았음

#  2) 연령, 성별
# 연령별로 탑승객 수와 생존자 수, 생존율 구하기
SELECT FLOOR(AGE/10)*10 AGEBAND,
       COUNT(PASSENGERID) N_PASSENGERS,
       SUM(SURVIVED) N_SURVIVED,
       SUM(SURVIVED)/COUNT(PASSENGERID) SURVIVED_RATE
  FROM MYDATA.DATASET4
 GROUP BY 1;
 
# 연령대로 오름차순 정렬하기
SELECT FLOOR(AGE/10)*10 AGEBAND,
       COUNT(PASSENGERID) N_PASSENGERS,
       SUM(SURVIVED) N_SURVIVED,
       SUM(SURVIVED)/COUNT(PASSENGERID) SURVIVED_RATE
  FROM MYDATA.DATASET4
 GROUP BY 1
 ORDER BY 1;
# 20대 탑승객이 가장 많고, 70대를 제외하면 60대의 생존율이 가장 낮음
# 생존율이 가장 높았던 그룹은 0~9세 아동으로 나타남

# 연령에 성별을 추가해서 생존율 파악하기
SELECT FLOOR(AGE/10)*10 AGEBAND,
       SEX,
       COUNT(PASSENGERID) N_PASSENGERS,
       SUM(SURVIVED) N_SURVIVED,
       SUM(SURVIVED)/COUNT(PASSENGERID) SURVIVED_RATE
  FROM MYDATA.DATASET4
 GROUP BY 1, 2
 ORDER BY 2, 1;
# 50대 여성의 생존율이 가장 높게 나타나고, 10대 남성의 생존율이 가장 낮게 나타남(70대 제외)

# 남성, 여성의 동일 연령대별 생존율 차이 비교하기
SELECT A.AGEBAND,
       A.SURVIVED_RATE MALE_SURVIVED_RATE,
       B.SURVIVED_RATE FEMALE_SURVIVED_RATE,
       B.SURVIVED_RATE-A.SURVIVED_RATE SURVIVED_RATE_DIFF
  FROM (SELECT FLOOR(AGE/10)*10 AGEBAND,
               SEX,
               COUNT(PASSENGERID) N_PASSENGERS,
               SUM(SURVIVED) N_SURVIVED,
               SUM(SURVIVED)/COUNT(PASSENGERID) SURVIVED_RATE
	  FROM MYDATA.DATASET4
	 GROUP BY 1, 2
	HAVING SEX='male') A
  LEFT
  JOIN (SELECT FLOOR(AGE/10)*10 AGEBAND,
               SEX,
               COUNT(PASSENGERID) N_PASSENGERS,
               SUM(SURVIVED) N_SURVIVED,
               SUM(SURVIVED)/COUNT(PASSENGERID) SURVIVED_RATE
	  FROM MYDATA.DATASET4
	 GROUP BY 1, 2
	HAVING SEX='female') B
    ON A.AGEBAND=B.AGEBAND
 ORDER BY A.AGEBAND;
# 전반적으로 여성의 경우 모든 연령대에서 60% 이상의 생존율을 보임
# 반대로 남성의 경우 10,20대의 생존율이 50,60대와 비슷하게 나타남
