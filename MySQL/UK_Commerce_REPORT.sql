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
