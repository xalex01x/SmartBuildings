

DROP PROCEDURE IF EXISTS ranking_pareti;
DELIMITER $$
CREATE PROCEDURE ranking_pareti (IN Ed VARCHAR(13))
BEGIN 
DECLARE Finito INTEGER DEFAULT 0;
DECLARE N INTEGER DEFAULT 0;
DECLARE i INTEGER DEFAULT 0;
DECLARE senscur VARCHAR(5) DEFAULT '';
DECLARE X FLOAT(5) DEFAULT -500;
DECLARE Y FLOAT(5) DEFAULT -500;
DECLARE Z FLOAT(5) DEFAULT -500;
DECLARE max1 FLOAT(5) DEFAULT -500;
DECLARE max2 FLOAT(5) DEFAULT -500;
DECLARE max3 FLOAT(5) DEFAULT -500;
DECLARE sensVin VARCHAR(5) DEFAULT '';
DECLARE popolamento CURSOR FOR
WITH SensoriTarget AS  (
SELECT D.CodSensore,D.ValX,D.ValY,D.ValZ
FROM ((SELECT MS.CodSensore, MS.ValX, MS.ValY, MS.ValZ
FROM MisurazioneSismica MS INNER JOIN Sensore S ON S.Codice=MS.CodSensore INNER JOIN Vano V ON V.Codice=S.CodVano
WHERE V.CodEd=Ed AND MS.Timestamp>=CURRENT_DATE - INTERVAL 1 DAY)
UNION
(SELECT  A.CodSensore,A.ValX, A.ValY,A.ValZ
FROM AlertSismico A INNER JOIN Sensore S ON S.Codice=A.CodSensore INNER JOIN Vano V ON V.Codice=S.CodVano
WHERE V.CodEd=Ed AND  A.Timestamp>=CURRENT_DATE - INTERVAL 1 DAY
))AS D), TabellaTarget AS(
SELECT ST.CodSensore,(AVG(ST.ValX)/SS.SogliaX) AS MediaX,(AVG(ST.ValY)/SS.SogliaY) AS MediaY,(AVG(ST.ValZ)/SS.SogliaZ) AS MediaZ 
FROM SensoriTarget ST NATURAL JOIN SensoreSismico SS
GROUP BY ST.CodSensore)
SELECT CodSensore,MediaX,MediaX,MediaZ
FROM TabellaTarget;

DECLARE ordinamento CURSOR FOR
SELECT * FROM sorgente;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET Finito=1;
DROP TABLE IF EXISTS sorgente;
CREATE TEMPORARY TABLE sorgente(
Codsensore VARCHAR(5) NOT NULL,
MediaX FLOAT(5) NOT NULL,
MediaY FLOAT(5) NOT NULL,
MediaZ FLOAT(5) NOT NULL,
PRIMARY KEY(CodSensore));
DROP TABLE IF EXISTS finale;
CREATE TEMPORARY TABLE finale(
CodSensore VARCHAR(5),
Vano VARCHAR(10) NOT NULL,
Muro VARCHAR(10) NOT NULL,
Classifica INT NOT NULL,
PRIMARY KEY(CodSensore));
OPEN popolamento;
scan:LOOP
FETCH popolamento INTO senscur, X,Y,Z;
IF(Finito=1) THEN LEAVE scan; END IF;
INSERT INTO sorgente VALUES(senscur, X,Y,Z);
END LOOP;
CLOSE popolamento;
SET Finito=0;
SELECT * FROM Sorgente;

SET N=(SELECT COUNT(*) FROM sorgente);
SELECT N; SELECT i;
WHILE (i<N) DO
OPEN ordinamento;
scan:LOOP
FETCH ordinamento INTO senscur, X,Y,Z;
IF(Finito=1) THEN LEAVE scan; END IF;
CASE
	WHEN(Max1<X) THEN IF(Y>=Z) THEN SET Max1=X; SET Max2=Y; SET  max3=z; SET SensVin=SensCur; 
					  ELSEIF(Y<Z) THEN SET Max2=Z; SET  max3=Y; SET Max1=X; 
					SET SensVin=SensCur;END IF;


	WHEN(Max1<Y) THEN IF(X>=Z) THEN SET Max1=Y; SET Max2=X;SET Max3=Z; SET SensVin=SensCur;
				   ELSEIF(Z>X) THEN SET Max1=Y; SET Max2=Z;SET Max3=X;
					SET SensVin=SensCur;END IF;

	WHEN(Max1<Z) THEN IF(X>=Y) THEN SET Max1=Z; SET Max2=X; SET Max3=Y; SET SensVin=SensCur;
				   ELSEIF (Y>X) THEN SET Max1=z; SET Max2=Y; SET Max3=X; 
					SET SensVin=SensCur;END IF;

	WHEN(Max1=X) THEN 
					IF(MAX2<Y) THEN SET Max1=X;SET Max2=Y; SET Max3=Z; SET SensVin=SensCur;
					ELSEIF (Max2<Z) THEN SET Max1=X; SET Max2=Z; SET Max3=Y; SET SensVin=SensCur;
					ELSEIF(Max2=Y) THEN 
								   IF(Max3<Z) THEN SET Max1=X; SET Max2=Y; SET Max3=z; SET SensVin=SensCur;
								   END IF;

					ELSEIF(Max2=Z) THEN 
								   IF(Max3<Y) THEN SET Max1=X; SET Max2=Z; SET Max3=Y;  SET SensVin=SensCur;
								   END IF;
					END IF;

								   
					
	WHEN(Max1=Y) THEN
					IF(MAX2<X) THEN SET Max1=Y;SET Max2=X; SET Max3=Z; SET SensVin=SensCur;
					ELSE IF (Max2<Z) THEN SET Max1=Y; SET Max2=Z; SET Max3=X; SET SensVin=SensCur;
					ELSEIF(Max2=X) THEN
								   IF(Max3<Z) THEN SET Max1=Y; SET Max2=X; SET Max3=z; SET SensVin=SensCur;
								   END IF;
				   
					ELSEIF(Max2=Z) THEN
								   IF(Max3<X) THEN SET Max1=Y; SET Max2=Z; SET Max3=X;  SET SensVin=SensCur;
								   END IF;
					END IF;
	END IF;
								
				
	WHEN(Max1=Z) THEN
					IF(MAX2<X) THEN SET Max1=Z;SET Max2=X; SET Max3=Y; SET SensVin=SensCur;
					ELSEIF (Max2<Y) THEN SET Max1=Z; SET Max2=Y; SET Max3=X;  SET SensVin=SensCur;
					ELSEIF(Max2=X) THEN 
								   IF(Max3<Y) THEN SET Max1=Z; SET Max2=X; SET Max3=Y;  SET SensVin=SensCur;
								   END IF;
					ELSEIF(Max2=Y) THEN 
								   IF(Max3<X) THEN SET Max1=Z; SET Max2=Y; SET Max3=X;  SET SensVin=SensCur;
								   END IF;

					END IF;
	ELSE BEGIN END;
END CASE;

END LOOP;
CLOSE ordinamento;


INSERT INTO finale
SELECT Codice, CodVano, CodMuro, (i+1)
FROM Sensore
WHERE Codice=SensVin;

DELETE
FROM sorgente
WHERE CodSensore=SensVin;
DO SLEEP(1);
SELECT * FROM sorgente;
IF(i<N) THEN SET Finito=0; SET Max1=-500; SET Max2=-500; SET max3=-500; SET Senscur=''; SET Sensvin='';
END IF; 
SET i=i+1;


END WHILE;
SELECT * FROM finale ORDER BY Classifica ;
END $$
DELIMITER ;
CALL ranking_pareti('FI00123032022');
