# 식품 배송 데이터(instacart)를 이용한 리포트 작성

/* dataset 정보
   aisles: 상품의 카테고리
   departments: 상품의 카테고리
   order_products__prior: 각 주문 번호의 상세 구매 내역
   orders: 주문 대표 번호
   products: 상품 정보 */
   
# 1. 지표 추출

#  1) 전체 주문 건수
SELECT COUNT(DISTINCT ORDER_ID) F
  FROM INSTACART.ORDERS;
  
#  2) 구매자 수
SELECT COUNT(DISTINCT USER_ID) BU
  FROM INSTACART.ORDERS;
  
#  3) 상품별 주문 건수
# 주문번호(ORDER_ID)는 ORDER_PRODUCTS_PRIOR 테이블, 상품명(PRODUCT_NAME)은 PRODUCT 테이블에 존재
# 두 테이블을 JOIN해야 함
SELECT *
  FROM INSTACART.ORDER_PRODUCTS__PRIOR A
  LEFT
  JOIN INSTACART.PRODUCTS B
    ON A.PRODUCT_ID = B.PRODUCT_ID;

# PRODUCT_NAME으로 테이블을 그루핑하고, ORDER_ID를 카운트
# ORDER_ID는 동일한 값이 존재하므로 중복 제거
SELECT B.PRODUCT_NAME,
	   COUNT(DISTINCT A.ORDER_ID) F
  FROM INSTACART.ORDER_PRODUCTS__PRIOR A
  LEFT
  JOIN INSTACART.PRODUCTS B
    ON A.PRODUCT_ID = B.PRODUCT_ID
 GROUP BY 1;
 
#  4) 장바구니에 가장 먼저 넣는 상품 10개
# ADD_TO_CART_ORDER: 상품이 몇 번째로 장바구니에 담겼는지를 의미하는 컬럼
# ORDER_PRODUCTS_PRIOR의 PRODUCT_ID별로 가장 먼저 담긴 경우에는 1을 출력하는 컬럼 생성(아닐 경우에는 0)
SELECT PRODUCT_ID,
	   CASE WHEN ADD_TO_CART_ORDER=1 THEN 1 ELSE 0 END F_1ST
  FROM INSTACART.ORDER_PRODUCTS__PRIOR;
  
# 상품별로 장바구니에 가장 먼저 담긴 건수 계산
# PRODUCT_ID로 테이블을 그루핑하고 F_1ST컬럼을 합하기
SELECT PRODUCT_ID,
	   SUM(CASE WHEN ADD_TO_CART_ORDER=1 THEN 1 ELSE 0 END) F_1ST
  FROM INSTACART.ORDER_PRODUCTS__PRIOR
 GROUP BY 1;
 
# F_1ST로 데이터에 순서매기기
SELECT *,
	   ROW_NUMBER() OVER(ORDER BY F_1ST DESC) RNK
  FROM (SELECT PRODUCT_ID,
			   SUM(CASE WHEN ADD_TO_CART_ORDER=1 THEN 1 ELSE 0 END) F_1ST
		  FROM INSTACART.ORDER_PRODUCTS__PRIOR
		 GROUP BY 1) A;

# RNK가 1~10위인 데이터만 출력
# RNK는 SELECT문에서 생성한 컬럼이므로 WHERE절에서 바로 사용 불가하므로 서브쿼리를 사용해 조건 생성
SELECT *
  FROM (SELECT *,
			   ROW_NUMBER() OVER(ORDER BY F_1ST DESC) RNK
		  FROM (SELECT PRODUCT_ID,
					   SUM(CASE WHEN ADD_TO_CART_ORDER=1 THEN 1 ELSE 0 END) F_1ST
				  FROM INSTACART.ORDER_PRODUCTS__PRIOR
				 GROUP BY 1) A 
		) BASE
 WHERE RNK BETWEEN 1 AND 10;

# RANK가 아닌 ORDER BY를 이용해 상위 10개의 데이터 출력
SELECT PRODUCT_ID,
	   SUM(CASE WHEN ADD_TO_CART_ORDER=1 THEN 1 ELSE 0 END) F_1ST
  FROM INSTACART.ORDER_PRODUCTS__PRIOR
 GROUP BY 1
 ORDER BY 2 DESC LIMIT 10;
 
#  5) 시간별 주문 건수
# ORDER_HOUR_OF_DAY로 그루핑하고 ORDER_ID를 카운트
# ORDER_ID는 중복이 있을 수 있으므로 중복 제거
SELECT ORDER_HOUR_OF_DAY,
	   COUNT(DISTINCT ORDER_ID) F
  FROM INSTACART.ORDERS
 GROUP BY 1
 ORDER BY 1;
 
#  6) 첫 구매 후 다음 구매까지 걸린 평균 일수
# DAYS_SINCE_PRIOR_ORDER: 이전 주문이 이루어진 지 며칠 뒤에 구매가 이루어졌는지 나타내는 컬럼
# 주문 번호의 ORDER_NUMBER가 2인(유저의 두번째 주문 건) DAYS_SINCE_PRIOR_ORDER는 첫 구매 후 다음 구매까지 걸린 기간
# 이 기간의 평균을 구하여 첫 구매 후 다음 구매까지 걸린 평균 일수 계산
SELECT AVG(DAYS_SINCE_PRIOR_ORDER) AVG_RECENCY
  FROM INSTACART.ORDERS
 WHERE ORDER_NUMBER=2;
 
#  7) 주문 건당 평균 구매 상품 수(UPT, Unit Per Transaction)
# PRODUCT_ID를 카운트해 상품 개수를 계산하고, 이를 주문 건수로 나누어 주문 1건에 평균적으로 몇 개의 상품을 구매하는지 계산
SELECT COUNT(PRODUCT_ID)/COUNT(DISTINCT ORDER_ID) UPT
  FROM INSTACART.ORDER_PRODUCTS__PRIOR;
 
#  8) 인당 평균 주문 수
# 전체 주문 건수를 구매자 수로 나누어 인당 평균 주문 건수 계산
SELECT COUNT(DISTINCT ORDER_ID)/COUNT(DISTINCT USER_ID) AVG_F
  FROM INSTACART.ORDERS;
  
#  9) 재구매율이 가장 높은 상품 10개
#   A) 상품별 재구매율 계산
# 상품 번호(PRODUCT_ID)로 그루핑하고, 재구매 수를 전체 구매수로 나누어 재구매율 계산
SELECT PRODUCT_ID,
	   SUM(CASE WHEN REORDERED=1 THEN 1 ELSE 0 END)/COUNT(*) RET_RATIO
  FROM INSTACART.ORDER_PRODUCTS__PRIOR
 GROUP BY 1;
 
#   B) 재구매율로 랭크(순위) 컬럼 생성하기
SELECT *,
	   ROW_NUMBER() OVER(ORDER BY RET_RATIO DESC) RNK
  FROM (SELECT PRODUCT_ID,
			   SUM(CASE WHEN REORDERED=1 THEN 1 ELSE 0 END)/COUNT(*) RET_RATIO
		  FROM INSTACART.ORDER_PRODUCTS__PRIOR
		 GROUP BY 1) A;
         
#   C) 재구매율 Top10 상품 추출
SELECT *
  FROM (SELECT *,
			   ROW_NUMBER() OVER(ORDER BY RET_RATIO DESC) RNK
		  FROM (SELECT PRODUCT_ID,
					   SUM(CASE WHEN REORDERED=1 THEN 1 ELSE 0 END)/COUNT(*) RET_RATIO
				  FROM INSTACART.ORDER_PRODUCTS__PRIOR
				 GROUP BY 1) A
		) A
 WHERE RNK BETWEEN 1 AND 10;
 
#  10) Department별 재구매율이 가장 높은 상품 10개
SELECT *
  FROM (SELECT *,
			   ROW_NUMBER() OVER(ORDER BY RET_RATIO DESC) RNK
		  FROM (SELECT A.DEPARTMENT,
					   B.PRODUCT_ID,
                       SUM(CASE WHEN REORDERED=1 THEN 1 ELSE 0 END)/COUNT(*) OVER(PARTITION BY DEPARTMENT) RET_RATIO
				  FROM INSTACART.DEPARTMENTS A
                  LEFT
                  JOIN INSTACART.PRODUCTS B
                    ON A.DEPARTMENT_ID = B.DEPARTMENT_ID
				  LEFT
                  JOIN INSTACART.ORDER_PRODUCTS__PRIOR C
                    ON B.PRODUCT_ID = C.PRODUCT_ID
				 GROUP BY 1, 2) A
		) A
 WHERE RNK BETWEEN 1 AND 10;
 
 # 2. 구매자 분석

#  1) 10분위 분석
# 10분위 분석: 전체를 10분위로 나누어 각 분위 수에 해당하는 집단의 성질을 나타내는 방법

# 고객들의 주문 건수를 기준으로 분위 수 나누기
SELECT *,
	   ROW_NUMBER() OVER(ORDER BY F DESC) RNK
  FROM (SELECT USER_ID,
			   COUNT(DISTINCT ORDER_ID) F
		  FROM INSTACART.ORDERS
		 GROUP BY 1) A;

# 전체 고객 수 계산하기
SELECT COUNT(DISTINCT USER_ID)
  FROM (SELECT USER_ID,
			   COUNT(DISTINCT ORDER_ID) F
		  FROM INSTACART.ORDERS
		 GROUP BY 1) A;
# 전체 고객 수는 3,159명임을 참고하여 등수별 분위 수 계산

# CASE WHEN 구문을 이용해 각 등수에 따른 분위 수 설정 (방법1)
SELECT *,
	   CASE WHEN RNK BETWEEN 1 AND 316 THEN 'Quantile_1'
       WHEN RNK BETWEEN 317 AND 632 THEN 'Quantile_2'
       WHEN RNK BETWEEN 633 AND 948 THEN 'Quantile_3'
       WHEN RNK BETWEEN 949 AND 1264 THEN 'Quantile_4'
       WHEN RNK BETWEEN 1265 AND 1580 THEN 'Quantile_5'
       WHEN RNK BETWEEN 1581 AND 1895 THEN 'Quantile_6'
       WHEN RNK BETWEEN 1896 AND 2211 THEN 'Quantile_7'
       WHEN RNK BETWEEN 2212 AND 2527 THEN 'Quantile_8'
       WHEN RNK BETWEEN 2528 AND 2843 THEN 'Quantile_9'
       WHEN RNK BETWEEN 2844 AND 3159 THEN 'Quantile_10' END quantile
  FROM (SELECT *,
			   ROW_NUMBER() OVER(ORDER BY F DESC) RNK
		  FROM (SELECT USER_ID,
					   COUNT(DISTINCT ORDER_ID) F
				  FROM INSTACART.ORDERS
				 GROUP BY 1) A
		) A;
		
# (방법2)
SELECT *,
	   CASE WHEN RNK <=316 THEN 'Quantile_1'
       WHEN RNK <=632 THEN 'Quantile_2'
       WHEN RNK <=948 THEN 'Quantile_3'
       WHEN RNK <=1264 THEN 'Quantile_4'
       WHEN RNK <=1580 THEN 'Quantile_5'
       WHEN RNK <=1895 THEN 'Quantile_6'
       WHEN RNK <=2211 THEN 'Quantile_7'
       WHEN RNK <=2527 THEN 'Quantile_8'
       WHEN RNK <=2843 THEN 'Quantile_9'
       WHEN RNK <=3159 THEN 'Quantile_10' END quantile
  FROM (SELECT *,
			   ROW_NUMBER() OVER(ORDER BY F DESC) RNK
		  FROM (SELECT USER_ID,
					   COUNT(DISTINCT ORDER_ID) F
				  FROM INSTACART.ORDERS
				 GROUP BY 1) A
		) A;
        
# 위의 조회 결과를 하나의 테이블로 생성
CREATE TEMPORARY TABLE INSTACART.USER_QUANTILE AS
SELECT *,
	   CASE WHEN RNK <=316 THEN 'Quantile_1'
       WHEN RNK <=632 THEN 'Quantile_2'
       WHEN RNK <=948 THEN 'Quantile_3'
       WHEN RNK <=1264 THEN 'Quantile_4'
       WHEN RNK <=1580 THEN 'Quantile_5'
       WHEN RNK <=1895 THEN 'Quantile_6'
       WHEN RNK <=2211 THEN 'Quantile_7'
       WHEN RNK <=2527 THEN 'Quantile_8'
       WHEN RNK <=2843 THEN 'Quantile_9'
       WHEN RNK <=3159 THEN 'Quantile_10' END quantile
  FROM (SELECT *,
			   ROW_NUMBER() OVER(ORDER BY F DESC) RNK
		  FROM (SELECT USER_ID,
					   COUNT(DISTINCT ORDER_ID) F
				  FROM INSTACART.ORDERS
				 GROUP BY 1) A
		) A;
  
# 테이블 생성 확인
SELECT *
  FROM INSTACART.USER_QUANTILE;
  
# 분위 수별 전체 주문 건수의 합
SELECT QUANTILE,
	   SUM(F) F
  FROM INSTACART.USER_QUANTILE
 GROUP BY 1;
       
# 전체 주문 건수 계산
SELECT SUM(F)
  FROM INSTACART.USER_QUANTILE;

# 각 분위 수의 주문 건수를 전체 주문 건수로 나누기
SELECT QUANTILE,
	   SUM(F)/3220 F
  FROM INSTACART.USER_QUANTILE
 GROUP BY 1;
# 각 분위 수별로 주문 건수가 거의 균등하게 분포되어 있음
# 즉 해당 서비스는 매출이 VIP에게 집중되지 않고, 전체 고객에 고르게 분호되어 있음을 알 수 있음

