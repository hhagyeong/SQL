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
