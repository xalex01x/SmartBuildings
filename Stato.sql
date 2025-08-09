-- calcolo dello stato generale
TRUNCATE Stato;
DROP PROCEDURE IF EXISTS calcola_stato_generale;
DELIMITER $$
CREATE PROCEDURE calcola_stato_generale(IN Ed1 VARCHAR(15), OUT r CHAR(1))
BEGIN 
DECLARE StatoCorr CHAR(1) DEFAULT '';
DECLARE V1 FLOAT(5) DEFAULT 0;
DECLARE V2 FLOAT(5) DEFAULT 0;
DECLARE V3 FLOAT(5) DEFAULT 0;
DECLARE TipoCu VARCHAR(20) DEFAULT '';
DECLARE i  CHAR(1) DEFAULT '';
DECLARE Generale  CHAR(1) DEFAULT 'A';
DECLARE Calamitoso CHAR(1) DEFAULT 'A';
DECLARE Finito INT DEFAULT 0;
DECLARE Finito2 INT DEFAULT 0;
DECLARE CUR Cursor FOR
WITH SensoriTarget AS  ((SELECT MS.CodSensore, MS.ValX, MS.ValY, MS.ValZ
FROM MisurazioneSismica MS INNER JOIN Sensore S ON S.Codice=MS.CodSensore INNER JOIN Vano V ON V.Codice=S.CodVano
WHERE V.CodEd=Ed1 AND MS.Timestamp>=CURRENT_DATE - INTERVAL 7 DAY)
UNION ALL
(SELECT  A.CodSensore,A.ValX, A.ValY,A.ValZ
FROM AlertSismico A INNER JOIN Sensore S ON S.Codice=A.CodSensore INNER JOIN Vano V ON V.Codice=S.CodVano
WHERE V.CodEd=Ed1 AND  A.Timestamp>=CURRENT_DATE - INTERVAL 7 DAY
)), TabellaTarget AS(
SELECT CodSensore,ValX,ValY,ValZ
FROM SensoriTarget 
 )
SELECT Tipo, SUM(ValX-SogliaX)/COUNT(ValX ) AS MediaX,SUM(ValY-SogliaY)/COUNT(ValY ) AS MediaY,SUM(ValZ-SogliaZ)/COUNT(ValZ) AS MediaZ
FROM SensoreSismico NATURAL JOIN TabellaTarget
GROUP BY Tipo;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET Finito=1;

OPEN Cur;
scan:LOOP
FETCH Cur INTO TipoCu,V1,V2,V3;
IF(Finito=1) THEN LEAVE scan; END IF;
IF (TipoCu='Accelerometro') THEN 
	IF (V1>=0.1 OR V2>=0.1 OR V3>=0.1 ) THEN SET i='B'; END IF;
	IF(V1>0.2 OR V2>0.2OR V3>0.2 ) THEN SET i='C'; END IF;
	IF(V1>0.3 OR V2>0.3 OR V3>0.3 ) THEN SET i='D'; END IF;
	IF(V1>0.4 OR V2>0.4 OR V3>0.4 ) THEN SET i='E'; END IF;
	IF(V1>0.5 OR V2>0.5 OR V3>0.5 ) THEN SET i='F'; END IF;
	IF (V1<0.1 OR V2<0.1 OR V3<0.1 ) THEN  SET i='A'; END IF;
 END IF;

IF (TipoCu='Giroscopio') THEN 
    IF (V1<=0 OR V2<=0 OR V3<=0) THEN SET i='A'; END IF;
	IF (V1>0 OR V2>0 OR V3>0 ) THEN SET i='B'; END IF;
	IF(V1>5 OR V2>5 OR V3>5 ) THEN SET i='C'; END IF;
	IF(V1>15 OR V2>15 OR V3>15 ) THEN SET i='D'; END IF;
	IF(V1>35 OR V2>35 OR V3>35 ) THEN SET i='E'; END IF;
	IF(V1>85 OR V2>85 OR V3>85 ) THEN SET i='F'; END IF;

 END IF;

IF (TipoCu='Estensimetro') THEN 
	IF (V1<=0 OR V2<=0 OR V3<=0 ) THEN SET i='A'; END IF;
	IF (V1>0 OR V2>0 OR V3>0 ) THEN SET i='B'; END IF;
	IF(V1>15 OR V2>15 OR V3>15 ) THEN SET i='C'; END IF;
	IF(V1>30 OR V2>30 OR V3>30 ) THEN SET i='D'; END IF;
	IF(V1>50 OR V2>50 OR V3>50 ) THEN SET i='E'; END IF;
	IF(V1>70 OR V2>70 OR V3>70 ) THEN SET i='F'; END IF;

 END IF;
  
 IF(Generale<i) THEN SET Generale=i; END IF;
 SET r=generale;
 
 END LOOP;
CLOSE CUR;
END $$
DELIMITER ;
-- stato totale
DROP PROCEDURE IF EXISTS calcola_stato;
DELIMITER $$
CREATE PROCEDURE calcola_stato(IN Ed1 VARCHAR(15))
BEGIN 
DECLARE StatoCorr CHAR(1) DEFAULT '';
DECLARE V1 FLOAT(5) DEFAULT 0;
DECLARE V2 FLOAT(5) DEFAULT 0;
DECLARE V3 FLOAT(5) DEFAULT 0;
DECLARE TipoCu VARCHAR(20) DEFAULT '';
DECLARE i  CHAR(1) DEFAULT '';
DECLARE Generale  CHAR(1) DEFAULT '';
DECLARE Calamitoso CHAR(1) DEFAULT 'A';
DECLARE Finito2 INT DEFAULT 0;


DECLARE CUR2 Cursor FOR
WITH SensoriTarget AS  ((SELECT MS.CodSensore, MS.ValX, MS.ValY, MS.ValZ
FROM  MisurazioneSismica MS INNER JOIN Sensore S ON S.Codice=MS.CodSensore INNER JOIN Vano V ON V.Codice=S.CodVano INNER JOIN Percezione P ON P.CodEd=V.CodEd
WHERE V.CodEd=Ed1 AND P.Timestamp+INTERVAL 1 DAY>MS.Timestamp AND MS.TimeStamp>=P.TimeStamp)
UNION ALL
(SELECT  A.CodSensore,A.ValX, A.ValY,A.ValZ
FROM  AlertSismico A INNER JOIN Sensore S INNER JOIN Vano V ON V.Codice=S.CodVano INNER JOIN Percezione P ON P.CodEd=V.CodEd
WHERE V.CodEd=Ed1 AND  P.Timestamp+INTERVAL 1 DAY>A.Timestamp AND A.TimeStamp>=P.TimeStamp)), TabellaTarget AS(
SELECT CodSensore,ValX,ValY,ValZ
FROM SensoriTarget 
 )
SELECT Tipo, SUM(ValX-SogliaX)/COUNT(ValX ) AS MediaX,SUM(ValY-SogliaY)/COUNT(ValY ) AS MediaY,SUM(ValZ-SogliaZ)/COUNT(ValZ) AS MediaZ
FROM SensoreSismico NATURAL JOIN TabellaTarget
GROUP BY Tipo;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET Finito2=1;

OPEN Cur2;
scan:LOOP
FETCH Cur2 INTO TipoCu,V1,V2,V3;
IF(Finito2=1) THEN LEAVE scan; END IF;
IF (TipoCu='Accelerometro') THEN 
	IF (V1>=0.1 OR V2>=0.1 OR V3>=0.1 ) THEN SET i='B'; END IF;
	IF(V1>0.2 OR V2>0.2OR V3>0.2 ) THEN SET i='C'; END IF;
	IF(V1>0.3 OR V2>0.3 OR V3>0.3 ) THEN SET i='D'; END IF;
	IF(V1>0.4 OR V2>0.4 OR V3>0.4 ) THEN SET i='E'; END IF;
	IF(V1>0.5 OR V2>0.5 OR V3>0.5 ) THEN SET i='F'; END IF;
	IF (V1<0.1 OR V2<0.1 OR V3<0.1 ) THEN  SET i='A'; END IF;
 END IF;

IF (TipoCu='Giroscopio') THEN 
    IF (V1<=0 OR V2<=0 OR V3<=0) THEN SET i='A'; END IF;
	IF (V1>0 OR V2>0 OR V3>0 ) THEN SET i='B'; END IF;
	IF(V1>5 OR V2>5 OR V3>5 ) THEN SET i='C'; END IF;
	IF(V1>15 OR V2>15 OR V3>15 ) THEN SET i='D'; END IF;
	IF(V1>35 OR V2>35 OR V3>35 ) THEN SET i='E'; END IF;
	IF(V1>85 OR V2>85 OR V3>85 ) THEN SET i='F'; END IF;

 END IF;

IF (TipoCu='Estensimetro') THEN 
	IF (V1<=0 OR V2<=0 OR V3<=0 ) THEN SET i='A'; END IF;
	IF (V1>0 OR V2>0 OR V3>0 ) THEN SET i='B'; END IF;
	IF(V1>15 OR V2>15 OR V3>15 ) THEN SET i='C'; END IF;
	IF(V1>30 OR V2>30 OR V3>30 ) THEN SET i='D'; END IF;
	IF(V1>50 OR V2>50 OR V3>50 ) THEN SET i='E'; END IF;
	IF(V1>70 OR V2>70 OR V3>70 ) THEN SET i='F'; END IF;

 END IF;

 IF(Calamitoso<i) THEN SET Calamitoso=i; END IF;
 
 
 END LOOP;
CLOSE CUR2;
IF(i='') THEN SET Calamitoso=NULL; END IF; -- non ci sono state calamita nell' intervallo misurato
CALL calcola_stato_generale (Ed1,Generale);
INSERT INTO Stato
VALUES(Ed1,CURRENT_DATE,Generale,Calamitoso);
SELECT * FROM Stato; 
END $$
DELIMITER ;






CALL calcola_stato('FI00123032022')
