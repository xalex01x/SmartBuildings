
-- stimacosto
DROP FUNCTION IF EXISTS stima;
DELIMITER $$ 
CREATE FUNCTION stima(descr VARCHAR(100))
RETURNS INT DETERMINISTIC
BEGIN
DECLARE s INTEGER DEFAULT 0;
SET s=(	SELECT AVG(costo)
		FROM lavoro
		WHERE Descrizione=descr);
RETURN s;
END $$
DELIMITER ;

-- calcola piano: per un sensore posizonato su una parete esterna ne individua il piano effettivo
DROP FUNCTION IF EXISTS calcola_piano;
DELIMITER $$
CREATE FUNCTION calcola_piano(Vano VARCHAR(10),Muro VARCHAR(10))
RETURNS INT DETERMINISTIC
BEGIN
DECLARE ris INTEGER DEFAULT 0;
select v1.piano into ris
from parete p inner join vano v1 on v1.codice=p.Codvano
where v1.codice=vano and p.codmuro=muro;
if(ris <> null) then return ris; end if;
WITH tutto as(select v1.codice, p.codmuro,v1.piano
from parete p inner join vano v1 on v1.codice=p.Codvano)
SELECT piano INTO ris
FROM tutto v1 inner join (select codvano,codmuro
						  from parete p inner join vano v1 on v1.codice=p.Codvano
						  where piano is null and codmuro=muro and codvano=vano) as v2 on v1.codice<>v2.codvano and v1.codmuro=v2.codmuro;
Return ris;
END $$
DELIMITER ;

/*calcolo dell'ampiezza delle onde sismiche generate da un terremoto*/
drop function if exists calcolo_ampiezza;
delimiter $$
create function calcolo_ampiezza(misurax float(5), misuray float(5), misuraz float(5)) returns float(5) deterministic
begin
set misurax=power(misurax,2);
set misuray=power(misuray,2);
set misuraz=power(misuraz,2);
return sqrt(misurax + misuray + misuraz);
end $$
delimiter ;
DROP PROCEDURE IF EXISTS isolamento_terreno;
DELIMITER $$
CREATE PROCEDURE isolamento_terreno(IN ed VARCHAR(13))
BEGIN
DECLARE piano1 INTEGER DEFAULT 0;
WITH Tab1 AS(SELECT calcola_piano(S.CodVano, S.CodMuro) AS PianoEffettivo, A.ValX-SS.SogliaX AS X, A.ValY-SS.SogliaY AS Y, A.ValZ-SS.SogliaZ AS Z
			FROM AlertSismico A NATURAL JOIN SensoreSismico SS INNER JOIN Sensore S ON S.Codice=SS.CodSensore INNER JOIN Vano V ON V.Codice=S.CodVano 
			WHERE A.Timestamp>=CURRENT_DATE - INTERVAL 30 DAY AND SS.Tipo='Giroscopio' AND V.CodEd=ed
			), MediaPiano AS(
            SELECT PianoEffettivo, AVG(X) AS MediaX, AVG(Y) AS MediaY, AVG(Z) AS MediaZ
            FROM Tab1
            GROUP BY PianoEffettivo
            )
			SELECT  PianoEffettivo  into piano1
            FROM MediaPiano
            WHERE PianoEffettivo=1 AND calcolo_ampiezza(MediaX,MediaY,MediaZ)> ALL(SELECT (calcolo_ampiezza(MediaX,MediaY,MediaZ)) 
														                            FROM MediaPiano
                                                                                    WHERE PianoEffettivo <>1);
IF(piano1=1) THEN
 INSERT INTO consigli_intervento
 VALUES('intero edificio','isolamento terreno',stima('isolamento terreno'),rischio(ed, 'giroscopio')); END IF; set piano1=0;

 END $$
 DELIMITER ;

DROP PROCEDURE IF EXISTS result_set_4;
DELIMITER $$
CREATE PROCEDURE result_set_4(IN ed varchar(13))
BEGIN
DROP TABLE IF EXISTS piani;
CREATE TEMPORARY TABLE piani(
piano INT,
PRIMARY KEY(piano));
INSERT INTO piani
WITH DatiTarget AS(SELECT calcola_piano(S.CodVano, S.CodMuro) AS PianoEffettivo, A.ValX-SS.SogliaX AS X, A.ValY-SS.SogliaY AS Y, A.ValZ-SS.SogliaZ AS Z
			FROM AlertSismico A NATURAL JOIN SensoreSismico SS INNER JOIN Sensore S ON S.Codice=SS.CodSensore INNER JOIN Vano V ON V.Codice=S.CodVano
			WHERE A.Timestamp>=CURRENT_DATE - INTERVAL 30 DAY AND SS.Tipo='Giroscopio' AND V.CodEd=ed
            ), DatiPerPiano AS(
            SELECT PianoEffettivo, AVG(X) AS MediaX, AVG(Y) AS MediaY, AVG(Z) AS MediaZ
            FROM DatiTarget
            GROUP BY PianoEffettivo), ConfrontoPiani AS(
			SELECT PianoEffettivo, MediaX, MediaY, MediaZ,LEAD(MediaX,1) OVER w AS Xs,LEAD(MediaY,1) OVER w AS Ys, LEAD(MediaZ,1) OVER w AS Zs
			FROM DatiPerPiano
WINDOW w AS(ORDER BY PianoEffettivo DESC 
			)), Differenza AS (
            SELECT PianoEffettivo, (MediaX-Xs) AS ValX,  (MediaY-Ys) AS ValY,  (MediaZ-Zs) AS ValZ
            FROM ConfrontoPiani
            )
            SELECT PianoEffettivo
            FROM Differenza
            WHERE ValX >10 OR ValY>10 OR ValZ>10 ;
END $$
DELIMITER ;

-- rischio: confronta i valori di un preciso edificio e di un tipo preciso di sensore con edifici nello stesso stato
DROP FUNCTION IF EXISTS rischio;
DELIMITER $$
CREATE FUNCTION rischio( ed1 VARCHAR(13), tipo1 VARCHAR(20))
RETURNS VARCHAR(20) DETERMINISTIC
BEGIN
DECLARE ValMedio FLOAT(5) DEFAULT 0;
DECLARE Valed1 FLOAT(5) DEFAULT 0;
DECLARE ed VARCHAR(13) DEFAULT '';
DECLARE S1 CHAR(1) DEFAULT '';
DECLARE S2 CHAR(1) DEFAULT '';
DECLARE Val2 FLOAT(5) DEFAULT 0;
DECLARE Finito INTEGER DEFAULT 0;
 -- assegnamento alle variabili i valori degl stati dell'edificio analizzato
SELECT ST.generale, ST.calamitoso INTO S1, S2
FROM  Stato ST
WHERE ST.COded=ed1 AND ST.Data= (	SELECT MAX(Data)
									FROM Stato ST2
									WHERE ST.coded=ST2.coded
												);
-- ricerca della media dei valori degli edifici attualmente nello stesso stato
 
WITH edificitarget AS(
SELECT ST.coded
FROM  Stato ST
WHERE ST.Coded<>ed1 AND ST.Calamitoso=S2 AND ST.Generale=S1 AND Data= (	SELECT MAX(Data)
														FROM Stato ST2
														WHERE ST.coded=ST2.coded
												))
,ValoriTarget AS(SELECT AVG(A.valx-SS.sogliax) AS X, AVG(A.valy-SS.sogliay) AS Y, AVG(A.valz-SS.sogliaz) AS Z , ET.CodEd
					 FROM EdificiTarget  ET NATURAL JOIN Vano V INNER JOIN Sensore S ON V.Codice=S.CodVano
					 INNER JOIN SensoreSismico SS ON SS.CodSensore=S.Codice NATURAL JOIN AlertSismico A
					 WHERE SS.tipo=tipo1
                     GROUP BY ET.CodEd), AmpiezzaEdifici AS(
	SELECT calcolo_ampiezza(VT.X,VT.Y,VT.Z) AS Modulo, VT.CodEd
    FROM ValoriTarget VT)
    SELECT AVG(Modulo) INTO ValMedio
    FROM AmpiezzaEdifici;

-- assegnamento del valora poi da confrontare del nostro edificio

WITH ValoreEdificio AS(SELECT AVG(A.valx-SS.sogliax) AS X, AVG(A.valy-SS.sogliay) AS Y, AVG(A.valz-SS.sogliaz) AS Z 
					 FROM  Vano V INNER JOIN Sensore S ON V.Codice=S.CodVano
					 INNER JOIN SensoreSismico SS ON SS.CodSensore=S.Codice NATURAL JOIN AlertSismico A
					 WHERE SS.tipo=tipo1 AND V.CodEd=ed1
                     GROUP BY V.CodEd)
	SELECT calcolo_ampiezza(VE.X,VE.Y,VE.Z) INTO Valed1
    FROM ValoreEdificio VE ;


IF(valMedio<valed1) THEN RETURN 'Alto'; 
ELSE RETURN 'Medio';
END IF;
END$$
DELIMITER ;

-- consigli intervento
DROP PROCEDURE IF EXISTS consigli;
DELIMITER $$
CREATE PROCEDURE consigli(IN ed VARCHAR(13))
BEGIN
DECLARE Piano1 INTEGER DEFAULT 0;
DECLARE Van1 VARCHAR(10) DEFAULT 0;
DECLARE MediaX FLOAT(5) DEFAULT 0;
DECLARE MediaY FLOAT(5) DEFAULT 0;
DECLARE MediaZ FLOAT(5) DEFAULT 0;
DECLARE modifica INTEGER DEFAULT 0;
DECLARE Val INTEGER DEFAULT 0;
DECLARE pianitarget VARCHAR(200) DEFAULT '';
DECLARE vanitarget VARCHAR(200) DEFAULT '';
DECLARE Finito INTEGER DEFAULT 0;
DECLARE PianiEd INTEGER DEFAULT 0;
DECLARE RispEd INTEGER DEFAULT 0;
-- confronta le medie dei valori di oscillazione intorno agli assi degli edifici nella stessa zona e
-- seleziona solo quelli con un numero di piani maggiore
DECLARE CUR CURSOR FOR
WITH ValoriTarget AS(SELECT E.Codice AS Edificio,  MAX(V.Piano) AS Npiani, AVG(A.ValX-SS.SogliaX) AS X, AVG(A.ValY-SS.SogliaY) AS Y, AVG(A.ValZ-SS.SogliaZ) AS Z
			FROM AlertSismico A NATURAL JOIN SensoreSismico SS INNER JOIN Sensore S ON S.Codice=SS.CodSensore INNER JOIN Vano V ON V.Codice=S.CodVano INNER JOIN Edificio E ON E.Codice=V.CodEd
			WHERE A.Timestamp>=CURRENT_DATE - INTERVAL 30 DAY AND SS.Tipo='Giroscopio' AND E.Area IN (SELECT Area
																									  FROM Edificio
                                                                                                      WHERE Codice=ed)
			GROUP BY E.Codice), RispostaTarget AS(
            SELECT Edificio, calcolo_ampiezza(X,Y,Z) AS Risposta, Npiani
            FROM ValoriTarget)
            SELECT Risposta
            FROM RispostaTarget
            WHERE Npiani>pianied;

-- ricerca di alert sui solai dei vani
DECLARE cur2 CURSOR FOR 
SELECT S.CodVano, AVG(A.ValX-SS.SogliaX), AVG(A.ValY-SS.SogliaY), AVG(A.ValZ-SS.SogliaZ)
FROM AlertSismico A NATURAL JOIN SensoreSismico SS INNER JOIN Sensore S ON S.Codice=SS.CodSensore NATURAL JOIN Parete P INNER JOIN Vano V ON V.Codice=P.CodVano 
WHERE  A.Timestamp>=CURRENT_DATE - INTERVAL 30 DAY AND SS.Tipo='Estensimetro' AND V.CodEd=ed AND P.Orientamento='T'
GROUP BY S.CodVano;

-- ricerca di crepe che hanno superato i valori di soglia
DECLARE cur3 CURSOR FOR 
SELECT (S.CodVano), AVG(A.ValX-SS.SogliaX), AVG(A.ValY-SS.SogliaY), AVG(A.ValZ-SS.SogliaZ)
FROM AlertSismico A NATURAL JOIN SensoreSismico SS INNER JOIN Sensore S ON S.Codice=SS.CodSensore NATURAL JOIN Parete P INNER JOIN Vano V ON V.Codice=P.CodVano 
WHERE A.Timestamp>=CURRENT_DATE - INTERVAL 30 DAY AND SS.Tipo='Estensimetro' AND V.CodEd=ed AND P.Orientamento<>'T'
GROUP BY (S.CodVano);


-- confronto con i valori di oscillazione del piano di sotto: dove risulta una maggiore differenza viene segnalato

DECLARE cur4 CURSOR FOR
SELECT * FROM Piani;

-- confronto oscillazioni tra vari vani, i sensori che generano alert piu pericolosi vengono selezionati (se hanno una porta e porta finestre)
DECLARE cur5 CURSOR FOR 
WITH Tab1 AS(SELECT S.CodVano AS Vano, AVG(A.ValX-SS.SogliaX) AS X, AVG(A.ValY-SS.SogliaY) AS Y, AVG(A.ValZ-SS.SogliaZ) AS Z
			FROM AlertSismico A NATURAL JOIN SensoreSismico SS INNER JOIN Sensore S ON S.Codice=SS.CodSensore INNER JOIN Vano V ON V.Codice=S.CodVano 
			WHERE A.Timestamp>=CURRENT_DATE - INTERVAL 30 DAY AND SS.Tipo='Giroscopio' AND V.CodEd=ed
			GROUP BY S.CodVano),Tab2 AS(
            SELECT Vano
            FROM Tab1
            WHERE calcolo_ampiezza(X,Y,Z)>=(SELECT AVG (calcolo_ampiezza(X,Y,Z))
											FROM Tab1 T2))
SELECT T2.Vano
FROM Tab2 T2 INNER JOIN ViaDiAccesso VA ON VA.LatoApertura=T2.Vano
WHERE VA.tipo='Porta' OR VA.tipo='PortaFinestra';


DECLARE CONTINUE HANDLER FOR NOT FOUND SET Finito=1;


CALL result_set_4(ed);

WITH ValoriEdificio AS(SELECT V.CodEd AS Edificio, MAX(calcola_piano(S.Codvano, S.CodMuro)) AS Npiani, AVG(A.ValX-SS.SogliaX) AS X, AVG(A.ValY-SS.SogliaY) AS Y, AVG(A.ValZ-SS.SogliaZ) AS Z
			FROM AlertSismico A NATURAL JOIN SensoreSismico SS INNER JOIN Sensore S ON S.Codice=SS.CodSensore INNER JOIN Vano V ON V.Codice=S.CodVano 
			WHERE A.Timestamp>=CURRENT_DATE - INTERVAL 30 DAY AND SS.Tipo='Giroscopio' 
			GROUP BY V.CodEd)
            SELECT calcolo_ampiezza(X,Y,Z) AS Risposta, Npiani  INTO  rispEd, pianied
            FROM ValoriEdificio
            WHERE Edificio=ed;
DROP TABLE IF EXISTS consigli_intervento;
CREATE TEMPORARY TABLE consigli_intervento(
	 PosizioniDanno VARCHAR(200) NOT NULL,
     lavoro VARCHAR(50) NOT NULL,
     StimaCosto INT NULL,
     RischioDanno VARCHAR(6) NOT NULL,
     PRIMARY KEY(Lavoro)
	);
-- confronto oscillazioni tra il primo piano e tutti gli altri se genera valori di distacco maggiori viene segnalato

CALL isolamento_terreno(ed);

-- se ha valori più pericolosi di un edificio con piani piu alti della stessa zona consiglia il sopraelevamento
OPEN cur;
scan: LOOP
FETCH cur INTO val;
IF(Finito=1) THEN LEAVE scan; END IF;
IF(val<risped) THEN SET modifica=1; END IF;
END LOOP;
CLOSE cur;
IF(Modifica=1) THEN
INSERT INTO consigli_intervento
VALUES('intero edificio','sopraelevamento struttura',stima('sopraelevamento struttura'),rischio(ed, 'giroscopio')); 
END IF;
 
SET pianitarget=''; SET Finito=0;


OPEN cur2;
scan: LOOP
FETCH cur2 INTO Van1,MediaX,MediaY,MediaZ;
IF(Finito=1) THEN LEAVE scan; END IF;
SET vaniTarget=CONCAT('Vano:',Van1,' ',vanitarget );
END LOOP;
CLOSE cur2;
IF(vanitarget <> '') THEN
 INSERT INTO consigli_intervento
 VALUES(vaniTarget,'Consolidamento dei solai',stima('consolidamento dei solai'),rischio(ed, 'estensimetro'));
 SET vanitarget=''; END IF; SET Finito=0;
 
 OPEN cur3;
scan: LOOP
FETCH cur3 INTO Van1,MediaX,MediaY,MediaZ;
IF(Finito=1) THEN LEAVE scan; END IF;
SET vaniTarget=CONCAT('Vano:',Van1,' ',vanitarget ); 
END LOOP;
CLOSE cur3;
IF(vanitarget <> '') THEN
 INSERT INTO consigli_intervento
 VALUES(vaniTarget,'installazione di cuciture in metallo',stima('installazione di cuciture in metallo'),rischio(ed, 'estensimetro'));
 SET vanitarget=''; END IF; SET Finito=0;
 
OPEN cur4;
scan: LOOP
FETCH cur4 INTO piano1;
IF(Finito=1) THEN LEAVE scan; END IF;
SET pianiTarget=CONCAT('piano:',piano1,' ',pianitarget ); 
END LOOP;
CLOSE cur4;
IF(pianitarget <> '') THEN
 INSERT INTO consigli_intervento
 VALUES(pianiTarget,'installazione di giunti sismici',stima('installazione di giunti sismici'),rischio(ed, 'giroscopio'));
 SET pianitarget=''; END IF; SET Finito=0;
 
OPEN cur5;
scan: LOOP
FETCH cur5 INTO van1;
IF(Finito=1) THEN LEAVE scan; END IF;
SET vaniTarget=CONCAT('Vano:',van1,' ',vanitarget ); 
END LOOP;
CLOSE cur5;
IF(vanitarget <> '') THEN
 INSERT INTO consigli_intervento
 VALUES(vaniTarget,'consolidamento cerchiature',stima('consolidamento cerchiature'),rischio(ed, 'giroscopio'));
 SET vanitarget=''; END IF; SET Finito=0;


 SELECT * FROM consigli_intervento;
 END $$
 DELIMITER ;
 
 CALL consigli('FI00123032022');
 

