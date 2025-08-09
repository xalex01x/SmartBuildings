/* ranking edifici più redditizi */
/* effettua la somma di tutti i costi dei lavori relativi su tutti gli edifici, genera la classifica degli edifici ordinata per edifici che hanno speso di piu */
-- operazione1
drop procedure if exists edifici_redditizi;
delimiter $$
create procedure edifici_redditizi()
begin
select T.*, rank() over( order by T.CostoLavori desc) as classifica
from(
select E.Codice,sum(L.Costo) as CostoLavori	
from Edificio E inner join ProgettoEdilizio P on P.CodEd=E.Codice inner join Lavoro L on L.CodProgetto=P.Codice
group by E.Codice
                ) as T;
end $$
DELIMITER ;

-- operazione 2:costo lavoro
drop procedure if exists costo_lavoro;
delimiter $$
create procedure costo_lavoro(in lav1 varchar(20))
begin
with Spesatotale as (
select sum(T.Spesa) as spesatot
from
(
select  sum(L.Stipendio) as spesa
from Realizzazione R inner join Lavoratore L on L.CodFiscale=R.Lavoratore
where R.Lavoro=lav1
UNION ALL
select sum(C.Stipendio) as spesa
from Direzione D inner join Capocantiere C on C.CodFiscale=D.Capocantiere
where D.Lavoro=lav1
UNION ALL
select sum(R.Parcella) as spesa
from Collaudo C inner join Responsabile R on R.CodFiscale=C.Responsabile
where C.Lavoro=lav1
UNION ALL
select sum(M.Costo*S.Quantita) as spesa
from Lavoro L inner join Schedario S on S.Lavoro=L.Codice
			  inner join Produzione P on P.Lotto=S.Lotto
              inner join Materiale M on M.Codprodotto=P.CodProdotto
where L.Codice=lav1)  as T)
select spesatot
from spesatotale;
end $$
delimiter ;


DROP PROCEDURE IF EXISTS aree_danneggiate;
DELIMITER $$
CREATE PROCEDURE aree_danneggiate()
BEGIN
WITH tabDanni AS(
SELECT E.Area, COUNT(D.Codice) OVER(PARTITION BY  E.Area) AS N, D.Descrizione
FROM  Danno D INNER JOIN PareteDanneggiata PD ON PD.CodDanno=D.Codice
      INNER JOIN Vano V ON V.Codice=PD.CodVano
      INNER JOIN Edificio E ON E.Codice=V.CodEd
), ContoDanni AS(
SELECT TD.Descrizione, TD.Area, TD.N, COUNT(*) AS conto
FROM TabDanni TD
GROUP BY TD.Descrizione,TD.Area)
SELECT RANK() OVER(ORDER BY N DESC) AS Classifica, CD.Area, CD.Descrizione
FROM ContoDanni CD
WHERE CD.Conto=(SELECT MAX(CD2.Conto)
                FROM ContoDanni CD2 
                WHERE CD.Area=CD2.Area);
END $$
DELIMITER ;

/*ranking dei lavori più in ritardo */
/*troviamo prima la data più alta di turno per un lavoro*/
drop procedure if exists lavori_piu_in_ritardo;
delimiter $$
create procedure lavori_piu_in_ritardo()
begin

WITH LavoriUltimaData AS (
	select DISTINCT(L.Codice), Datediff(T.Data,S.StimaFine) as Ritardo
	from Turno T inner join Lavoro L on T.Lavoro=L.Codice
					  inner join Stadio S on L.CodStadio=S.livello and L.CodProgetto=S.CodProgetto
	where T.Data>= (
	select max(T1.Data)
	from Turno T1
	where T1.Lavoro=T.Lavoro))
    SELECT Codice, Ritardo, Rank() OVER(ORDER BY Ritardo DESC) AS Classifica
    FROM LavoriUltimaData;


end $$
delimiter ;

-- operazione 5
DROP PROCEDURE IF EXISTS MaterialiMigliori;
DELIMITER $$
CREATE PROCEDURE MaterialiMigliori()
BEGIN
DECLARE prod1 VARCHAR(45) DEFAULT '';
DECLARE qua1 INTEGER  DEFAULT 0;
DECLARE costo1 INTEGER  DEFAULT 0;
DECLARE pezzi1 INTEGER  DEFAULT 0;
DECLARE Finito INTEGER DEFAULT 0;
WITH ProdottiTarget AS (
SELECT P.CodProdotto, SUM(S.Quantita)*M.costo AS spesatotale,SUM(S.Quantita)*M.pezzi AS pezzitotali
FROM  Schedario S NATURAL JOIN Produzione P NATURAL JOIN Materiale M
WHERE S.DataAcquisto>= CURRENT_DATE - INTERVAL 30 DAY
GROUP BY P.CodProdotto),
ProdPiuUsati AS(
SELECT PT.CodProdotto, PT.spesatotale
FROM ProdottiTarget PT 
WHERE PT.pezzitotali >=(SELECT AVG(PT2. pezzitotali)
				        FROM ProdottiTarget PT2)
)
SELECT CodProdotto, SpesaTotale, RANK() OVER(ORDER BY SpesaTotale) AS Classifica
FROM ProdPiuUsati;
END $$
DELIMITER ;

-- operazione 6
-- sposta lavoratore
DROP PROCEDURE IF EXISTS sposta_lavoratore; -- cerca l' operaio con lo stipendio piu basso e spostalo 
DELIMITER $$
CREATE PROCEDURE sposta_lavoratore( IN Lavoro1 VARCHAR(15), IN Data1 DATE, IN Ora1 INT )
BEGIN 
DECLARE OperaioCur VARCHAR(16) DEFAULT '';
DECLARE Finito INTEGER DEFAULT 0;
DECLARE CUR CURSOR FOR 
SELECT L.CodFiscale 
FROM Realizzazione R INNER JOIN Lavoratore L ON L.CodFiscale=R.Lavoratore
WHERE R.Data=data1 AND R.Ora=ora1 AND R.Lavoro<>Lavoro1 AND L.Stipendio =(SELECT MIN(L2.Stipendio)
                                                                          FROM Realizzazione R2 INNER JOIN Lavoratore L2 ON R2.Lavoratore=L2.CodFiscale
																		  WHERE R2.Data=data1 AND R2.Ora=ora1 AND R2.Lavoro<>Lavoro1);
DECLARE CONTINUE HANDLER FOR NOT FOUND SET Finito=1;
OPEN CUR;
scan:LOOP
FETCH CUR INTO OperaioCur;
IF (Finito=1) THEN LEAVE Scan; END IF;  
UPDATE Realizzazione
SET Lavoro=lavoro1
WHERE  Data=data1 AND Ora=ora1 AND Lavoratore=OperaioCur;-- preleva solo 1
LEAVE SCAN;
END LOOP;
CLose CUR;
END $$
DELIMITER ;

-- operazione 7

-- operazione 7
-- Ranking delle parti piu monitorate di un edificio se un sensore non e' presente mette 0
DROP PROCEDURE IF EXISTS parti_monitorate;
DELIMITER $$
CREATE PROCEDURE parti_monitorate(IN ed VARCHAR(13))
BEGIN
WITH VaniNoSensor AS(
SELECT V.Codice, 0 AS NumSensori
FROM Vano V LEFT OUTER JOIN Sensore S ON V.Codice=S.CodVano
WHERE V.CodEd=ed AND S.Codice IS NULL)
SELECT D.Codice, RANK()OVER (ORDER BY D.NumSensori DESC) AS Classifica,NumSensori
FROM((
SELECT Codice,NumSensori
FROM VaniNoSensor
) UNION ALL
(SELECT V.Codice, COUNT(DISTINCT(S.Codice)) AS NumSensori
 FROM Vano V INNER JOIN Sensore S ON V.Codice=S.CodVano
 WHERE V.coded=ed
 GROUP BY V.Codice)) AS D;
 END $$
 DELIMITER ;
 
 -- operazione 7 con ridondanza
 DROP PROCEDURE IF EXISTS parti_monitorate2;
 DELIMITER $$
 CREATE PROCEDURE parti_monitorate2(IN ed VARCHAR(13))
 BEGIN
 SELECT Codice, RANK() OVER(ORDER BY NumSensori DESC) AS Classifica, NumSensori
 FROM Vano
 WHERE CodEd=ed;
 END $$
 DELIMITER ;




 
 -- operazione 8
 -- inserimento di un sensore
  -- aggiornamento della ridondanza
DROP TRIGGER IF EXISTS AggiornaNumSensori;
DELIMITER $$
CREATE TRIGGER AggiornaNumSensori
AFTER INSERT ON Sensore
FOR EACH ROW
BEGIN 
UPDATE Vano
SET NumSensori=NumSensori+1
WHERE NEW.CodVano=Codice;
END $$
DELIMITER ;
DROP TRIGGER IF EXISTS AggiornaNumSensori2;
DELIMITER $$
CREATE TRIGGER AggiornaNumSensori2
AFTER DELETE ON Sensore 
FOR EACH ROW
BEGIN 
UPDATE Vano
SET NumSensori=NumSensori-1
WHERE OLD.CodVano=Codice;
END $$
DELIMITER ;
 
 DROP PROCEDURE IF EXISTS inserisci_sensore;
 DELIMITER $$
 CREATE PROCEDURE inserisci_sensore(IN cod1 VARCHAR(10),  IN vano VARCHAR(10), IN muro VARCHAR(10), IN posX FLOAT(5), IN posY FLOAT(5))
 BEGIN
 INSERT INTO Sensore
 VALUES(cod1,vano, muro, posX, posY);
 END $$
 DELIMITER ;
