-- stima dei danni

DROP PROCEDURE IF EXISTS prodotti_piu_usati;
DELIMITER  $$
CREATE PROCEDURE prodotti_piu_usati( IN edificio VARCHAR(13), OUT prod1 VARCHAR(20), OUT prod2 VARCHAR(20), OUT prod3 VARCHAR(20), OUT prod4 VARCHAR(20))
BEGIN
DECLARE i VARCHAR(20) DEFAULT '';
DECLARE classifica VARCHAR(20) DEFAULT '';
DECLARE Finito INTEGER DEFAULT 0;

DECLARE cur CURSOR FOR
WITH Tabella AS(
SELECT D.CodProdotto, D.TotaleQuantita
FROM(
SELECT CM.CodProdotto,  SUM(Quantita) AS TotaleQuantita
FROM ComposizioneMuro CM INNER JOIN Muro M ON M.Codice=CM.CodMuro INNER JOIN Parete P ON M.Codice=P.CodMuro INNER JOIN Vano V ON V.Codice=P.CodVano
WHERE V.CodEd=edificio
UNION ALL
SELECT CP.CodProdotto, SUM(Quantita) AS TotaleQuantita
FROM ComposizioneParete CP NATURAL JOIN Parete P INNER JOIN Vano V ON V.Codice=P.CodVano
WHERE V.CodEd=edificio
) AS D
GROUP BY D.CodProdotto)

SELECT T.CodProdotto
FROM Tabella T
ORDER BY T.TotaleQuantita
LIMIT 4;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET Finito=1;
SET prod1='';
SET prod2='';
SET prod3='';
SET prod4='';
OPEN cur;
scan: LOOP
FETCH cur INTO i;
IF(Finito=1) THEN LEAVE scan; END IF;
IF(prod1='') THEN SET prod1=i; 
ELSEIF(prod2='') THEN SET prod2=i; 
ELSEIF(prod3='') THEN SET prod3=i;
ELSEIF(prod4='') THEN SET prod4=i; END IF;
END LOOP;
CLOSE cur;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS stima_danni;
DELIMITER $$
CREATE PROCEDURE stima_danni(IN Ed VARCHAR(13))
BEGIN
DECLARE Finito INTEGER DEFAULT 0;
DECLARE gen1 CHAR(1) DEFAULT '';
DECLARE cal1 CHAR(1) DEFAULT '';
DECLARE Day1 DATE DEFAULT '2022-01-01';
DECLARE i DATE DEFAULT '2022-01-01';
DECLARE b bool DEFAULT 0;
DECLARE test1 CHAR(1) DEFAULT '';
DECLARE test2 CHAR(1) DEFAULT '';
DECLARE test3 INT DEFAULT -50;
DECLARE edcur VARCHAR(13) DEFAULT '';
DECLARE prod1 VARCHAR(10) DEFAULT '';
DECLARE prod2 VARCHAR(10) DEFAULT '';
DECLARE prod3 VARCHAR(10) DEFAULT '';
DECLARE prod4 VARCHAR(10) DEFAULT '';
DECLARE p1 VARCHAR(10) DEFAULT '';
DECLARE p2 VARCHAR(10) DEFAULT '';
DECLARE p3 VARCHAR(10) DEFAULT '';
DECLARE p4 VARCHAR(10) DEFAULT '';
DECLARE punti INT DEFAULT 0;

DECLARE perccur INT DEFAULT 0;
DECLARE dancur VARCHAR(50) DEFAULT '';
DECLARE evencur VARCHAR(50) DEFAULT '';
DECLARE Datadanno DATE DEFAULT  '2022-01-01';

DECLARE edificinuovi CURSOR FOR
SELECT DISTINCT(CodEd) 
FROM Stato 
WHERE Data=i AND (generale=gen1 OR calamitoso=cal1) AND CodEd NOT IN (SELECT *
                                                                      FROM edificitarget);-- scorre gli edifici che in un dterminato giorno hanno assunto lo stato target


DECLARE EdificiNOtarget CURSOR FOR
SELECT calamitoso,generale, CodEd FROM Stato WHERE Data=i  AND CodEd IN (SELECT *
                                                                         FROM edificitarget); -- scorre gli edifici presenti nello stato target un dato giorno 
DECLARE inserimento CURSOR FOR
SELECT edificio FROM Edificitarget; -- scorrimento degli edifici in quello stato quel giorno
DECLARE edificitarget CURSOR FOR
SELECT Edificio FROM CalendarioSismico; -- scorrimento del calendario (viene aperto quando e' completo)
DECLARE CONTINUE HANDLER FOR NOT FOUND SET Finito=1;

SELECT Generale, Calamitoso INTO gen1 , cal1 
FROM  Stato
WHERE CodEd = ed AND data=(SELECT MAX(data)
                           FROM stato
                           WHERE coded=Ed); -- trovo lo stato attuale dell'edificio
                          
SET Day1=(SELECT MIN(Data) FROM Stato WHERE Generale=gen1 OR Calamitoso=cal1); -- la prima volta che un edificio si è trovato nello stato target
DROP TABLE IF EXISTS edificitarget;
CREATE TEMPORARY TABLE IF NOT EXISTS edificitarget (
    edificio VARCHAR(13) NOT NULL,
    PRIMARY KEY (edificio)
)ENGINE=INNODB DEFAULT CHARSET latin1;
 
DROP TABLE IF EXISTS CalendarioSismico;
CREATE TEMPORARY TABLE IF NOT EXISTS CalendarioSismico (
    Danno INT NOT NULL,
    Giorno DATE NOT NULL,
    edificio VARCHAR(13) NOT NULL,
    Probabilita INT DEFAULT 0,
    PRIMARY KEY ( Danno, Giorno , Edificio)
) ENGINE=INNODB DEFAULT CHARSET latin1;

 SET i=Day1;
 WHILE(i<=CURRENT_DATE ) DO
 OPEN edificinuovi;
 scan:LOOP
 FETCH edificinuovi INTO edcur;
 IF(finito=1) THEN LEAVE scan; END IF;
 INSERT INTO edificitarget VALUES(edcur);
END LOOP;
CLOSE edificinuovi;
-- scorrimento secondo cursore:
-- rimuove eventuali edifici che non si trovano più in quello stato

SET finito=0;
OPEN edificiNOtarget;
scan:LOOP
FETCH edificiNOtarget INTO test1,test2,edcur;
IF(finito=1) THEN LEAVE scan; END IF;

IF(test1<>cal1 AND test2 <> gen1) THEN 
                                  DELETE 
                                  FROM edificitarget
                                  WHERE edificio=edcur;
END IF; 

 SELECT COUNT(*) INTO test3 FROM edificitarget;
IF(test3=0) THEN
 SET Day1=(SELECT Min(Data) FROM Stato WHERE (Calamitoso=cal1 OR generale=gen1) AND Data>i);-- se gli edifici sono zero dopo la nuova cancellazione trova
                                                                                            -- un nuovo giorno da cui far ripartire il calendario
 SET i=Day1;
 END IF;
END LOOP;
CLOSE edificiNOtarget;
Set Finito=0;
-- per gli edifici che si trovano in quello stato quel giorno trova un danno rilevato il giorno stesso
-- poi popola 
OPEN inserimento;
scan:LOOP
FETCH inserimento INTO edcur;
IF(finito=1) THEN LEAVE scan; END IF; 

INSERT INTO CalendarioSismico
SELECT DISTINCT(D.Codice),i,edcur,0
FROM Danno D INNER JOIN PareteDanneggiata PD ON D.Codice=PD.CodDanno INNER JOIN Vano V ON V.Codice=PD.CodVano
WHERE V.CodEd=edcur AND D.DataComparsa=i;

END LOOP;
CLOSE inserimento;
SET Finito=0;

SET i=i+INTERVAL 1 DAY;
END WHILE;

Set Finito=0;
CALL prodotti_piu_usati(ed,prod1,prod2,prod3,prod4);
-- calcola la probabilita di un danno rispetto ad uno specifico edificio
OPEN edificitarget;
Scan:LOOP
FETCH edificitarget INTO Edcur;
IF(Finito=1) THEN LEAVE scan;END IF;
SET punti=0;
CALL prodotti_piu_usati(edcur,p1,p2,p3,p4); -- calcola la probabilita rispetto all'edificio in questione
IF(p1=prod1) THEN SET punti=punti+10; END IF;
IF(p1=prod1 OR p2=Prod2) THEN SET punti=punti+8; END IF;
IF(p1=prod3 OR p2=prod3 OR p3=Prod3 ) THEN SET punti=punti+5; END IF;
IF(p1=prod4 OR p2=prod4 OR p3=Prod4 OR p4=Prod4) THEN SET punti=punti+3; END IF;
UPDATE CalendarioSismico
SET probabilita=punti
WHERE edificio=edcur; -- aggiorna le riche dove compare l'edifico scorso
END LOOP;
CLOSE edificitarget;
SET Finito=0;
SELECT * FROM calendariosismico ORDER BY Giorno;
 
WITH tab1 AS (
SELECT   traduci(orientamento, funzione) AS Zona, D.descrizione AS Danno, CS.probabilita
FROM CalendarioSismico CS 
     INNER JOIN Danno D ON CS.Danno=D.Codice 
     INNER JOIN PareteDanneggiata PD ON PD.CodDanno=D.Codice 
     NATURAL JOIN Parete P INNER JOIN Vano V ON V.Codice=P.CodVano
 ),
Tab2 AS(
SELECT Zona, Danno, SUM(probabilita) AS Probabilita
FROM Tab1
GROUP BY Zona,Danno)
SELECT RANK() OVER (ORDER BY Probabilita DESC) AS Classifica, Danno, Zona, Probabilita
FROM Tab2;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS traduci;
DELIMITER $$
CREATE FUNCTION traduci(dir CHAR(3), funzione VARCHAR(50))
RETURNS CHAR(20) DETERMINISTIC
BEGIN
CASE 
WHEN(dir='T'OR dir='TSW' OR dir='TNW' OR dir='TE' OR dir='TNE' OR dir='TSE') THEN RETURN 'soffitto';
WHEN(dir='B') THEN RETURN 'pavimento';
WHEN((dir='W' OR dir='SW' OR dir='NW' OR dir='E' OR dir='NE' OR dir='SE'OR dir='N' OR dir='S') AND funzione='esterno') THEN RETURN 'parete perimetrale';
ELSE RETURN 'parete interna';

END CASE;
END $$
DELIMITER ;


CALL stima_danni('FI00123032022');



                              

 
 