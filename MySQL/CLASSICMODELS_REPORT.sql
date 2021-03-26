# 자동차 매출 데이터(CLASSICMODELS)를 이용한 리포트 작성

# 1. 구매 지표 추출

#  1) 매출액(익자별, 월별, 연도별)

#   A) 일별 매출액 조회
# CLASSICMODELS.ORDERS 테이블의 주문 정보에 ORDERDETAILS의 주문 상품 가격 결합 후, ORDERDATE와 PRICEEACH * QUANTITYORDERED(매출액)를 조회
SELECT A.ORDERDATE,
	   PRICEEACH * QUANTITYORDERED
  FROM CLASSICMODELS.ORDERS A
  LEFT
  JOIN CLASSICMODELS.ORDERDETAILS B
    ON A.ORDERNUMBER = B.ORDERNUMBER;
    
# ORDERDATE로 그룹핑한 뒤, PRICEEACH * QUANTITYORDERED(매출액)의 합을 집계
SELECT A.ORDERDATE,
	   SUM(PRICEEACH * QUANTITYORDERED) AS SALES
  FROM CLASSICMODELS.ORDERS A
  LEFT
  JOIN CLASSICMODELS.ORDERDETAILS B
    ON A.ORDERNUMBER = B.ORDERNUMBER
 GROUP BY 1
 ORDER BY 1;
 
 #   B) 월별 매출액 조회
 # 위와 동일한 방법을 취하되, SUBSTR()을 이용하여 'YYYY-MM'까지의 정보만 가져와서 조회
SELECT SUBSTR(A.ORDERDATE,1,7) MM,
	   SUM(PRICEEACH * QUANTITYORDERED) AS SALES
  FROM CLASSICMODELS.ORDERS A
  LEFT
  JOIN CLASSICMODELS.ORDERDETAILS B
    ON A.ORDERNUMBER = B.ORDERNUMBER
 GROUP BY 1
 ORDER BY 1;
 
#   C) 연도별 매출액 조회
# 위와 동일한 방법을 취하되, SUBSTR()을 이용하여 'YYYY'정보만 가져와서 조회
SELECT SUBSTR(A.ORDERDATE,1,4) YYYY,
	   SUM(PRICEEACH * QUANTITYORDERED) AS SALES
  FROM CLASSICMODELS.ORDERS A
  LEFT
  JOIN CLASSICMODELS.ORDERDETAILS B
    ON A.ORDERNUMBER = B.ORDERNUMBER
 GROUP BY 1
 ORDER BY 1;
 
#  2) 구매자 수, 구매 건수(일자별, 월별, 연도별)
# ORDERDATE로 그루핑한 후 고객 번호를 COUNT (구매자 수, 구매 건수를 산출할 때는 보통 UNIQUE하게 필드를 COUNT해줘야 함)
# 일자별
SELECT ORDERDATE,
	   COUNT(DISTINCT CUSTOMERNUMBER) N_PURCHASER,
       COUNT(ORDERNUMBER) N_ORDERS
  FROM CLASSICMODELS.ORDERS
 GROUP BY 1
 ORDER BY 1;
 
# 월별
SELECT SUBSTR(ORDERDATE,1,7) MM,
	   COUNT(DISTINCT CUSTOMERNUMBER) N_PURCHASER,
	   COUNT(ORDERNUMBER) N_ORDERS
  FROM CLASSICMODELS.ORDERS
 GROUP BY 1
 ORDER BY 1;
 
#연도별
SELECT SUBSTR(ORDERDATE,1,4) YYYY,
	   COUNT(DISTINCT CUSTOMERNUMBER) N_PURCHASER,
	   COUNT(ORDERNUMBER) N_ORDERS
  FROM CLASSICMODELS.ORDERS
 GROUP BY 1
 ORDER BY 1;
 
#  3) 인당 매출액(연도별)
# 연도별 매출액과 구매자 수 구하기
SELECT SUBSTR(A.ORDERDATE,1,4) YYYY,
	   COUNT(DISTINCT A.CUSTOMERNUMBER) N_PURCHASER,
       SUM(PRICEEACH * QUANTITYORDERED) AS SALES
  FROM CLASSICMODELS.ORDERS A
  LEFT
  JOIN CLASSICMODELS.ORDERDETAILS B
    ON A.ORDERNUMBER = B.ORDERNUMBER
 GROUP BY 1
 ORDER BY 1;
 
 # 매출액을 구매자 수로 나누기
 SELECT SUBSTR(A.ORDERDATE,1,4) YYYY,
	    COUNT(DISTINCT A.CUSTOMERNUMBER) N_PURCHASER,
        SUM(PRICEEACH * QUANTITYORDERED) AS SALES,
        SUM(PRICEEACH * QUANTITYORDERED) / COUNT(DISTINCT A.CUSTOMERNUMBER) AMV
  FROM CLASSICMODELS.ORDERS A
  LEFT
  JOIN CLASSICMODELS.ORDERDETAILS B
    ON A.ORDERNUMBER = B.ORDERNUMBER
 GROUP BY 1
 ORDER BY 1;
 
#  4) 건당 구매 금액(ATV, Average Transaction Value)(연도별)
# 인당 구매 금액을 구하는 방법과 유사하지만, 매출을 구매자 수가 아닌 '구매 건수'로 나눔
SELECT SUBSTR(A.ORDERDATE,1,4) YYYY,
	   COUNT(DISTINCT A.ORDERNUMBER) N_PURCHASER,
       SUM(PRICEEACH * QUANTITYORDERED) AS SALES,
       SUM(PRICEEACH * QUANTITYORDERED) / COUNT(DISTINCT A.ORDERNUMBER) ATV
  FROM CLASSICMODELS.ORDERS A
  LEFT
  JOIN CLASSICMODELS.ORDERDETAILS B
    ON A.ORDERNUMBER = B.ORDERNUMBER
 GROUP BY 1
 ORDER BY 1;
 
# 2. 그룹별 구매 지표 구하기
#  1) 국가별, 도시별 매출액
# 해당 주문 건이 발생한 국가, 도시를 파악하기 위해 CUSTOMERS 테이블의 COUNTRY 이용
SELECT *
  FROM CLASSICMODELS.ORDERS A
  LEFT
  JOIN CLASSICMODELS.ORDERDETAILS B
    ON A.ORDERNUMBER = B.ORDERNUMBER
  LEFT
  JOIN CLASSICMODELS.CUSTOMERS C
    ON A.CUSTOMERNUMBER = C.CUSTOMERNUMBER;
    
# COUNTRY, CITY로 그루핑 한 뒤 PRICEEACH * QUANTITYORDERED를 합하여 국가별, 도시별 매출액 계산
SELECT C.COUNTRY, C.CITY,
	   SUM(PRICEEACH * QUANTITYORDERED) SALES
  FROM CLASSICMODELS.ORDERS A
  LEFT
  JOIN CLASSICMODELS.ORDERDETAILS B
    ON A.ORDERNUMBER = B.ORDERNUMBER
  LEFT
  JOIN CLASSICMODELS.CUSTOMERS C
    ON A.CUSTOMERNUMBER = C.CUSTOMERNUMBER
 GROUP BY 1,2;
 
# 마지막으로 COUNTRY, CITY로 데이터를 정렬하여 데이터를 가독성 있게 구조화
SELECT C.COUNTRY, C.CITY,
	    SUM(PRICEEACH * QUANTITYORDERED) SALES
  FROM CLASSICMODELS.ORDERS A
  LEFT
  JOIN CLASSICMODELS.ORDERDETAILS B
    ON A.ORDERNUMBER = B.ORDERNUMBER
  LEFT
  JOIN CLASSICMODELS.CUSTOMERS C
    ON A.CUSTOMERNUMBER = C.CUSTOMERNUMBER
 GROUP BY 1,2
 ORDER BY 1,2;
 
#  2) 북미(USA,CANADA) VS 비북미 매출액 비교
# 북미와 비북미를 구분하는 CASE WHEN 구문
SELECT CASE WHEN COUNTRY IN ('USA', 'CANADA') THEN 'NORTH AMERICA' ELSE 'OTHERS' END COUNTRY_GRP
  FROM CLASSICMODELS.CUSTOMERS; 
  
# COUNTRY, CITY로 데이터를 그룹핑해 미출을 집계할 때 COUNTRY와 CITY를 CASE WHEN 구문으로 변경해서 북미, 비북미 매출 구분 조회
SELECT CASE WHEN COUNTRY IN ('USA', 'CANADA') THEN 'NORTH AMERICA' ELSE 'OTHERS' END COUNTRY_GRP,
	   SUM(PRICEEACH * QUANTITYORDERED) SALES
  FROM CLASSICMODELS.ORDERS A
  LEFT
  JOIN CLASSICMODELS.ORDERDETAILS B
    ON A.ORDERNUMBER = B.ORDERNUMBER
  LEFT
  JOIN CLASSICMODELS.CUSTOMERS C
    ON A.CUSTOMERNUMBER = C.CUSTOMERNUMBER
 GROUP BY 1
 ORDER BY 2 DESC;

#  3) 매출 Top5 국가 및 매출
# 쿼리의 실행 결과를 CLASSICMODELS.STAT 테이블을 생성하여 저장
CREATE TABLE CLASSICMODELS.STAT AS
SELECT C.COUNTRY,
	   SUM(PRICEEACH * QUANTITYORDERED) SALES
  FROM CLASSICMODELS.ORDERS A
  LEFT
  JOIN CLASSICMODELS.ORDERDETAILS B
    ON A.ORDERNUMBER = B.ORDERNUMBER
  LEFT
  JOIN CLASSICMODELS.CUSTOMERS C
    ON A.CUSTOMERNUMBER = C.CUSTOMERNUMBER
 GROUP BY 1
 ORDER BY 2 DESC;
 
# 테이블 생성 확인
SELECT *
  FROM CLASSICMODELS.STAT;
  
# 생성된 테이블에서 DENSE_RANK를 이용해 매출액 등수 매기기
SELECT COUNTRY, SALES,
	   DENSE_RANK() OVER(ORDER BY SALES DESC) RNK
  FROM CLASSICMODELS.STAT;
  
# 출력 결과를 테이블로 생성
CREATE TABLE CLASSICMODELS.STAT_RNK AS
SELECT COUNTRY, SALES,
	   DENSE_RANK() OVER(ORDER BY SALES DESC) RNK
  FROM CLASSICMODELS.STAT;
  
# 테이블 생성 확인
SELECT *
  FROM CLASSICMODELS.STAT_RNK;
  
# 상위 5개 국가 확인
SELECT *
  FROM CLASSICMODELS.STAT_RNK
 WHERE RNK BETWEEN 1 AND 5;
 
# 위의 과정을 SUBQUARY로 해보기
# RNK는 SELECT에서 생성한 칼럼이라 조건절에서 사용할 수 없으므로 다시 SUBQUARY를 걸어줘야 함
SELECT *
  FROM (SELECT COUNTRY, SALES, DENSE_RANK() OVER(ORDER BY SALES DESC) RNK
		  FROM (SELECT C.COUNTRY, SUM(PRICEEACH * QUANTITYORDERED) SALES
				  FROM CLASSICMODELS.ORDERS A
                  LEFT
                  JOIN CLASSICMODELS.ORDERDETAILS B
                    ON A.ORDERNUMBER = B.ORDERNUMBER
				  JOIN CLASSICMODELS.CUSTOMERS C
                    ON A.CUSTOMERNUMBER = C.CUSTOMERNUMBER
				 GROUP BY 1) A
		) A
 WHERE RNK <=5;
	