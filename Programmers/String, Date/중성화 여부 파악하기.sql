SELECT  ANIMAL_ID, NAME,
        IF(SEX_UPON_INTAKE REGEXP 'Neutered|Spayed', 'O' , 'X') AS 중성화
  FROM  ANIMAL_INS;
