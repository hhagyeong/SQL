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
