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
