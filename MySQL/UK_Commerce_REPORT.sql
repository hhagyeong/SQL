# UK Commenrce 데이터를 이용한 리포트 작성
/* InvoiceNo: 주문 번호
   StockCode: 상품 번호
   Description: 상품명
   Quantity: 구매 상품 수
   UnitPrice: 개당 판매 가격
   CustomerID: 고객 번호
   Country: 판매 국가
   InvoiceDate: 판매 일자 */

# 1. 국가별, 상품별 구매자 수 및 매출액
# COUNTRY, STOCKCODE로 테이블을 그루핑하고, 고객 번호(CUSTOMERID)를 카운트, 구매 상품수(QUANTITY)*개당 가격(UNITPRICE)의 곱 합하기
# 고객 번호가 중복이 없는 지 확인해줘야 함
SELECT COUNTRY,
       STOCKCODE,
       COUNT(DISTINCT CUSTOMERID) BU,
       ROUND(SUM(QUANTITY*UNITPRICE),2) SALES
  FROM MYDATA.DATASET3
 GROUP BY 1, 2
 ORDER BY 3 DESC, 4 DESC;

# 2. 특정 상품 구매자가 많이 구매한 상품은?

#  1) 가장 많이 판매된 2개 상품 조회(판매 상품 수 기준)
# 상품별로 판매된 개수 구하기
SELECT STOCKCODE,
       SUM(QUANTITY) QTY
  FROM MYDATA.DATASET3
 GROUP BY 1;
 
# 판매된 상품 수(QTY)를 기준으로 랭크 생성하기
# 가장 많이 판매된 2개의 상품을 조회하는 것이 목적이므로 내림차순으로 순위매김
SELECT *,
       ROW_NUMBER() OVER(ORDER BY QTY DESC) RNK
  FROM (SELECT STOCKCODE,
	       SUM(QUANTITY) QTY
	  FROM MYDATA.DATASET3
	 GROUP BY 1) A;

# 랭크(RNK)가 1, 2인 데이터 조회하기(위의 쿼리를 서브쿼리로 활용하는 법)
SELECT STOCKCODE
  FROM (SELECT *,
	       ROW_NUMBER() OVER(ORDER BY QTY DESC) RNK
	  FROM (SELECT STOCKCODE,
		       SUM(QUANTITY) QTY
		  FROM MYDATA.DATASET3
		 GROUP BY 1) A
	) A
 WHERE RNK BETWEEN 1 AND 2;
# 가장 많이 판매된 상품 코드는 84077, 85123A로 확인됨
 
#  2) 가장 많이 판매된 2개 상품을 모두 구매한 구매자가 구매한 상품
# 고객별로 각각의 상품을 구매했다면 1, 그렇지 않으면 0이 출력되도록 하고, 각 상품을 모두 구매한 경우만 출력되도록 HAVING을 통해 조건 생성
SELECT CUSTOMERID
  FROM MYDATA.DATASET3
 GROUP BY 1
HAVING MAX(CASE WHEN STOCKCODE='84077' THEN 1 ELSE 0 END) =1
   AND MAX(CASE WHEN STOCKCODE='85123A' THEN 1 ELSE 0 END) =1;
   
# 위의 쿼리 결과를 테이블(BU_LIST)로 생성
CREATE TABLE MYDATA.BU_LIST AS
SELECT CUSTOMERID
  FROM MYDATA.DATASET3
 GROUP BY 1
HAVING MAX(CASE WHEN STOCKCODE='84077' THEN 1 ELSE 0 END) =1
   AND MAX(CASE WHEN STOCKCODE='85123A' THEN 1 ELSE 0 END) =1;

# 테이블 생성 확인
SELECT *
  FROM MYDATA.BU_LIST;
   
# 해당 고객들이 구매한 상품 출력
SELECT DISTINCT STOCKCODE
  FROM MYDATA.DATASET3
 WHERE CUSTOMERID IN (SELECT CUSTOMERID FROM MYDATA.BU_LIST)
   AND STOCKCODE NOT IN ('84077','85123A'); 
   
# 3. 국가별 재구매율 계산
SELECT A.COUNTRY,
       SUBSTR(A.INVOICEDATE, 1, 4) YY,
       COUNT(DISTINCT B.CUSTOMERID)/COUNT(DISTINCT A.CUSTOMERID) RETENTION_RATE
  FROM (SELECT DISTINCT COUNTRY,
	       INVOICEDATE,
               CUSTOMERID
	  FROM MYDATA.DATASET3) A
  LEFT
  JOIN (SELECT DISTINCT COUNTRY,
	       INVOICEDATE,
		       CUSTOMERID
	  FROM MYDATA.DATASET3) B
    ON SUBSTR(A.INVOICEDATE, 1, 4) = SUBSTR(B.INVOICEDATE, 1, 4) -1
   AND A.COUNTRY = B.COUNTRY
   AND A.CUSTOMERID = B.CUSTOMERID
 GROUP BY 1, 2
 ORDER BY 1, 2;  
 
 # 4. 코호트 분석 
# 코호트분석: 주로 시간의 흐름에 따라 사용자의 리텐션, 구매 패턴, 행동 패턴을 파악하는 데 사용되는 분석

# 고객별 첫 구매일 구하기
SELECT CUSTOMERID,
       MIN(INVOICEDATE) MNDT
  FROM MYDATA.DATASET3
 GROUP BY 1;
 
# 각 고객의 주문 일자, 구매액 조회하기
SELECT CUSTOMERID,
       INVOICEDATE,
       ROUND(UNITPRICE*QUANTITY, 2) SALES
  FROM MYDATA.DATASET3;

# 첫 번째로 구매했던 고객별 첫 구매일 테이블에 고객의 구매 내역 JOIN하기
SELECT *
  FROM (SELECT CUSTOMERID,
	       MIN(INVOICEDATE) MNDT
	  FROM MYDATA.DATASET3
	 GROUP BY 1) A
  LEFT
  JOIN (SELECT CUSTOMERID,
	       INVOICEDATE,
               ROUND(UNITPRICE*QUANTITY,2) SALES
	  FROM MYDATA.DATASET3) B
    ON A.CUSTOMERID = B.CUSTOMERID;

# SUBSTR() 함수를 이용해 '연도-월'까지 데이터 가져오기
# 이후 최초 구매일과 각 구매일 사이의 간격은 TIMESTAMPDIFF() 함수를 이용해 계산함
# 최초 구매일로부터 각 구매일의 간격을 월로 표현할 것이므로 TIMESTAMPDIFF(MONTH, MNDT, INVOICEDATE)를 사용해 간격을 구해줌
# 이후 최초 구매월, 구매 간격으로 그루핑해 구매자 수를 카운트하고, 매출을 합계해 각 코호트의 리텐션과 매출액 구함
SELECT SUBSTR(MNDT, 1, 7) MM,
       TIMESTAMPDIFF(MONTH, MNDT, INVOICEDATE) DATEDIFF,
       COUNT(DISTINCT A.CUSTOMERID) BU,
       ROUND(SUM(SALES),2) SALES
  FROM (SELECT CUSTOMERID,
	       REPLACE(MIN(INVOICEDATE),' ','') MNDT
	  FROM MYDATA.DATASET3_2
	 GROUP BY 1) A
  LEFT
  JOIN (SELECT CUSTOMERID,
	       INVOICEDATE,
               UNITPRICE*QUANTITY SALES
	  FROM MYDATA.DATASET3_2) B
    ON A.CUSTOMERID = B.CUSTOMERID
 GROUP BY 1, 2;
 
 # 5.고객 세그먼트
#  1)RFM
#    A)RFM: 구매 가능성이 높은 고객을 선정하기 위한 데이터 분석 방법으로서, 분석 과정을 통해 데이터는 의미 있는 정보로 전환된다
/* Recency - 제일 최근에 구입한 시기가 언제인가?
   Frequency - 어느 정도로 자주 구입했나?
   Monetary - 구입한 총 금액은 얼마인가? */
   
# 고객의 마지막 구매일 구하기
SELECT CUSTOMERID,
       MAX(INVOICEDATE) MXDT
  FROM MYDATA.DATASET3_2
 GROUP BY 1;

# '2011-12-02'로부터의 TIMER INTERVAL 계산하기
SELECT *
  FROM (SELECT CUSTOMERID,
               DATEDIFF('2011-12-02', MXDT) RECENCY
	  FROM (SELECT CUSTOMERID,
		       MAX(INVOICEDATE) MXDT
		  FROM MYDATA.DATASET3_2
		 GROUP BY 1) A
		) A
 WHERE RECENCY IS NOT NULL ;
 
# FREQUENCY(구매 건수)와 MONETARY(구매 금액) 계산하기
SELECT CUSTOMERID,
       COUNT(DISTINCT INVOICENO) FREQUENCY,
       ROUND(SUM(QUANTITY*UNITPRICE), 2) MONETARY
  FROM MYDATA.DATASET3
 GROUP BY 1;

# 위에서 구한 RECENCY, FREQUENCY, MONETARY를 하나의 쿼리로 구하기
SELECT CUSTOMERID,
       DATEDIFF('2011-12-02', MXDT) RECENCY,
       FREQUENCY,
       MONETARY
  FROM (SELECT CUSTOMERID,
               MAX(INVOICEDATE) MXDT,
               COUNT(DISTINCT INVOICENO) FREQUENCY,
               SUM(QUANTITY*UNITPRICE) MONETARY
	  FROM MYDATA.DATASET3
	 GROUP BY 1) A;

#    B)K Means Algorithm: 비슷한 특성을 가진 데이터를 그룹핑하는 Clustering 기법 중 하나

#  2)재구매 Segment
# 고객별, 상품별 구매 연도를 Unique하게 카운트
SELECT CUSTOMERID,
       STOCKCODE,
       COUNT(DISTINCT SUBSTR(INVOICEDATE, 1, 4)) UNIQUE_YY
  FROM MYDATA.DATASET3
 GROUP BY 1, 2;
 
# UNIQUE_YY가 2이상인 고객과 그렇지 않은 고객을 구분하면, Segment구할 수 있음
# 고객별로 UNIQUE_YY의 최대값을 계산헀을 때, 그 값이 2이상인 고객은 특정 상품을 2개 연도에 걸쳐 구매한 것으로 볼 수 있음
SELECT CUSTOMERID,
       MAX(UNIQUE_YY) MX_UNIQUE_YY
  FROM (SELECT CUSTOMERID,
               STOCKCODE,
               COUNT(DISTINCT SUBSTR(INVOICEDATE, 1, 4)) UNIQUE_YY
	  FROM MYDATA.DATASET3
	 GROUP BY 1, 2) A
 GROUP BY 1;
 
# MX_UNIQUE_YY가 2이상인 경우는 1, 그렇지 않은 경우는 0으로 설정해 REPURCHASE_SEGMENT생성
SELECT CUSTOMERID,
       CASE WHEN MX_UNIQUE_YY >= 2 THEN 1 ELSE 0 END REPURCHASE_SEGMENT
  FROM (SELECT CUSTOMERID,
               MAX(UNIQUE_YY) MX_UNIQUE_YY
	  FROM (SELECT CUSTOMERID,
                       STOCKCODE,
                       COUNT(DISTINCT SUBSTR(INVOICEDATE, 1, 4)) UNIQUE_YY
		  FROM MYDATA.DATASET3
		 GROUP BY 1, 2) A
	GROUP BY 1) A
 GROUP BY 1;

# 6.일자별 첫 구매자 수
#  1)고객별 첫 구매일
SELECT CUSTOMERID,
       MIN(INVOICEDATE) MNDT
  FROM MYDATA.DATASET3
 GROUP BY CUSTOMERID;
 
#  2)일자별 첫 구매 고객 수
SELECT MNDT,
       COUNT(DISTINCT CUSTOMERID) BU
  FROM (SELECT CUSTOMERID,
               MIN(INVOICEDATE) MNDT
	  FROM MYDATA.DATASET3
	 GROUP BY CUSTOMERID) A
 GROUP BY MNDT;

# 7.상품별 첫 구매 고객 수
#  1)고객별, 상품별 첫 구매 일자
SELECT CUSTOMERID,
       STOCKCODE,
       MIN(INVOICEDATE) MNDT
  FROM MYDATA.DATASET3
 GROUP BY 1,2;
 
#  2)고객별 구매와 기준 순위 생성(랭크)
SELECT *,
       ROW_NUMBER() OVER(PARTITION BY CUSTOMERID ORDER BY MNDT) RNK
  FROM (SELECT CUSTOMERID,
               STOCKCODE,
               MIN(INVOICEDATE) MNDT
	  FROM MYDATA.DATASET3
	 GROUP BY 1,2) A;
         
#    A)고객별 첫 구매 내역 조회
SELECT *
  FROM (SELECT *,
               ROW_NUMBER() OVER(PARTITION BY CUSTOMERID ORDER BY MNDT) RNK
	  FROM (SELECT CUSTOMERID,
                       STOCKCODE,
                       MIN(INVOICEDATE) MNDT
		  FROM MYDATA.DATASET3
		 GROUP BY 1,2) A
	) A
 WHERE RNK=1;
 
#    B)상품별 첫 구매 고객 수 집계
SELECT STOCKCODE,
       COUNT(DISTINCT CUSTOMERID) FIRST_BU
  FROM (SELECT *
          FROM (SELECT *,
                       ROW_NUMBER() OVER(PARTITION BY CUSTOMERID ORDER BY MNDT) RNK
		  FROM (SELECT CUSTOMERID,
                               STOCKCODE,
                               MIN(INVOICEDATE) MNDT
			  FROM MYDATA.DATASET3
			 GROUP BY 1,2) A
		) A
	WHERE RNK=1) A
 GROUP BY STOCKCODE
 ORDER BY 2 DESC;
 
# 8.첫 구매 후 이탈하는 고객의 비중
# 고객별 구매 일자의 중복을 제거하고 카운트
SELECT CUSTOMERID,
       COUNT(DISTINCT INVOICEDATE) F_DATE
  FROM MYDATA.DATASET3
 GROUP BY 1;
 
# F_DATE의 값이 1인 고객 번호(CUSTOMERID): 첫 구매 후 이탈한 고객
# F_DATE가 1인 고객의 수를 카운트해 그 값을 전체 고객의 수로 나누면, 첫 구매 후 이탈한 고객 수 계산 가능
SELECT SUM(CASE WHEN F_DATE=1 THEN 1 ELSE 0 END)/SUM(1) BOUNC_RATE
  FROM (SELECT CUSTOMERID,
	       COUNT(DISTINCT INVOICEDATE) F_DATE
	  FROM MYDATA.DATASET3
	 GROUP BY 1) A;
         
# 국가별 첫 구매 후 이탈 고객의 비중 구하기
SELECT COUNTRY,
       SUM(CASE WHEN F_DATE=1 THEN 1 ELSE 0 END)/SUM(1) BOUNC_RATE
  FROM (SELECT CUSTOMERID,
               COUNTRY,
               COUNT(DISTINCT INVOICEDATE) F_DATE
	  FROM MYDATA.DATASET3
	 GROUP BY 1,2) A
 GROUP BY 10.0
 ORDER BY COUNTRY;
 
# 9.판매 수량이 20%이상 증가한 상품 리스트(YTD)
#  1)2011년도 상품별 판매 수량
SELECT STOCKCODE,
       SUM(QUANTITY) QTY
  FROM MYDATA.DATASET3
 WHERE SUBSTR(INVOICEDATE, 1, 4) = '2011'
 GROUP BY 1;
 
#  2)2010년도 상품별 판매 수량
SELECT STOCKCODE,
       SUM(QUANTITY) QTY
  FROM MYDATA.DATASET3
 WHERE SUBSTR(INVOICEDATE, 1, 4) = '2010'
 GROUP BY 1;
 
# 2011년도 상품별 판매 수량과 2010년도 상품별 판매 수량 합치기
SELECT *
  FROM (SELECT STOCKCODE,
               SUM(QUANTITY) QTY
	  FROM MYDATA.DATASET3
	 WHERE SUBSTR(INVOICEDATE, 1, 4) = '2011'
	 GROUP BY 1) A
  LEFT
  JOIN (SELECT STOCKCODE,
               SUM(QUANTITY) QTY
	  FROM MYDATA.DATASET3
	 WHERE SUBSTR(INVOICEDATE, 1, 4) = '2010'
         GROUP BY 1) B
    ON A.STOCKCODE = B.STOCKCODE;
    
# 상품 코드, 2011년 판매 수량, 2010년 판매 수량을 구하고, 2010년 대비 증가율 계산
SELECT A.STOCKCODE,
       A.QTY,
       B.QTY,
       A.QTY/B.QTY-1 QTY_INCREASE_RATE
  FROM (SELECT STOCKCODE,
               SUM(QUANTITY) QTY
	  FROM MYDATA.DATASET3
	 WHERE SUBSTR(INVOICEDATE, 1, 4) = '2011'
	 GROUP BY 1) A
  LEFT
  JOIN (SELECT STOCKCODE,
               SUM(QUANTITY) QTY
	  FROM MYDATA.DATASET3
	 WHERE SUBSTR(INVOICEDATE, 1, 4) = '2010'
         GROUP BY 1) B
    ON A.STOCKCODE = B.STOCKCODE;
    
# 2010년 대비 2011년 증가율(QTY_INCREASE_RATE)이 0.2이상인 경우로 조건 생성
# 주의: QTY_INCREASE_RATE가 SELECT에 존재하므로 WHERE절에서 바로 사용할 수 없으므로 서브쿼리를 생성해야 함
SELECT *
  FROM (SELECT A.STOCKCODE,
               A.QTY QTY_2011,
               B.QTY QTY_2010,
               A.QTY/B.QTY-1 QTY_INCREASE_RATE
	  FROM (SELECT STOCKCODE,
                       SUM(QUANTITY) QTY
		  FROM MYDATA.DATASET3
		 WHERE SUBSTR(INVOICEDATE, 1, 4) = '2011'
                 GROUP BY 1) A
		  LEFT
          JOIN (SELECT STOCKCODE,
                       SUM(QUANTITY) QTY
		  FROM MYDATA.DATASET3
		 WHERE SUBSTR(INVOICEDATE, 1, 4) = '2010'
                 GROUP BY 1) B
		    ON A.STOCKCODE = B.STOCKCODE) BASE
 WHERE QTY_INCREASE_RATE >=0.2;
 
# 10.주차별 매출액
/* WEEKOFYEAR: 일자의 주차를 숫자로 반환
   예시: SELECT WEEKOFYEAR('2018-01-01') */

SELECT WEEKOFYEAR(INVOICEDATE) WK,
       SUM(QUANTITY*UNITPRICE) SALES
  FROM MYDATA.DATASET3
 WHERE SUBSTR(INVOICEDATE, 1, 4) = '2011'
 GROUP BY 1
 ORDER BY 1;
 
# 11.신규/기존 고객의 2011년 월별 매출액
# 고객별로 최초 구매 일자를 구한 후 최초 구매 연도가 2011년이면 신규 고객, 2010년이면 기존 고객으로 분류
SELECT CASE WHEN SUBSTR(MNDT, 1, 4) = '2011' THEN 'NEW' ELSE 'EXI' END NEW_EXI,
       CUSTOMERID
  FROM (SELECT CUSTOMERID,
               MIN(INVOICEDATE) MNDT
	  FROM MYDATA.DATASET3
	 GROUP BY 1) A;
         
# 해당 테이블(고객 신규/기존 구분)을 매출 테이블에 JOIN하기
SELECT A.CUSTOMERID,
       B.NEW_EXI,
       A.INVOICEDATE,
       A.UNITPRICE,
       A.QUANTITY
  FROM MYDATA.DATASET3 A
  LEFT
  JOIN (SELECT CASE WHEN SUBSTR(MNDT, 1, 4) = '2011' THEN 'NEW' ELSE 'EXI' END NEW_EXI,
               CUSTOMERID
	  FROM (SELECT CUSTOMERID,
                       MIN(INVOICEDATE) MNDT
		  FROM MYDATA.DATASET3
		 GROUP BY 1) A
	) B
    ON A.CUSTOMERID = B.CUSTOMERID
 WHERE SUBSTR(A.INVOICEDATE, 1, 4) = '2011';
 
# JOIN한 결과를 월, 신규/기존으로 구분해 매출 집계
SELECT B.NEW_EXI,
       SUBSTR(A.INVOICEDATE, 1, 7) MM,
       SUM(A.UNITPRICE*A.QUANTITY) SALES
  FROM MYDATA.DATASET3 A
  LEFT
  JOIN (SELECT CASE WHEN SUBSTR(MNDT, 1, 4) = '2011' THEN 'NEW' ELSE 'EXI' END NEW_EXI,
               CUSTOMERID
	  FROM (SELECT CUSTOMERID,
                       MIN(INVOICEDATE) MNDT
		  FROM MYDATA.DATASET3
		 GROUP BY 1) A
	) B
    ON A.CUSTOMERID = B.CUSTOMERID
 WHERE SUBSTR(A.INVOICEDATE, 1, 4) = '2011'
 GROUP BY 1, 2;
