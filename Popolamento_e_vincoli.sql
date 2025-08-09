 /*trigger che aggiorni il costolavoro ad ogni inserimento di turno */

drop trigger if exists aggiorna_costo_lavoratori;
delimiter $$
create trigger aggiorna_costo_lavoratori after insert on Realizzazione
for each row
begin

declare CostoManodopera int default 0;
set CostoManodopera = (
select L.Stipendio
from Realizzazione R inner join Lavoratore L on L.CodFiscale=R.Lavoratore
where L.CodFiscale=New.Lavoratore and R.lavoro=new.lavoro and R.Data=NEW.data and R.Ora=New.Ora);
update Lavoro
set Costo= Costo+CostoManodopera
where Codice=New.Lavoro;

end $$
delimiter ;

drop trigger if exists aggiorna_costo_materiali;
delimiter $$
create trigger aggiorna_costo_materiali after insert on Schedario
for each row
begin
declare CostoMateriali int default 0;
set CostoMateriali = (select sum(M.Costo*S.Quantita)
from Lavoro L inner join Schedario S on S.Lavoro=L.Codice
			  inner join Produzione P on P.Lotto=S.Lotto
              inner join Materiale M on M.Codprodotto=P.CodProdotto
where L.Codice=New.Lavoro AND S.DataAcquisto=new.DataAcquisto and S.lotto=new.lotto);
update Lavoro 
set Costo= Costo+CostoMateriali
where Codice=New.Lavoro;
end $$
delimiter ;

drop trigger if exists aggiorna_costo_collaudi;
delimiter $$
create trigger aggiorna_costo_collaudi after insert on Collaudo
for each row
begin
declare CostoCollaudo int default 0;
set CostoCollaudo = (select R.Parcella
from Collaudo C inner join Responsabile R on R.CodFiscale=C.Responsabile
where R.CodFiscale=New.Responsabile and R.lavoro=new.lavoro );
update Lavoro L1
set L1.Costo= L1.Costo+CostoCollaudo
where L1.Codice=New.Lavoro;
end $$
delimiter ;

drop trigger if exists aggiorna_costo_capi;
delimiter $$
create trigger aggiorna_costo_capi after insert on Direzione
for each row
begin
declare CostoCapi int default 0;
set CostoCapi = (select C.Stipendio
from Direzione D inner join Capocantiere C on C.CodFiscale=D.Capocantiere
where C.CodFiscale=New.CapoCantiere and D.lavoro=new.lavoro and D.Data=NEW.data and D.Ora=New.Ora);
update Lavoro
set Costo= Costo+CostoCapi
where Codice=New.Lavoro;
end $$
delimiter ;

-- trigger che impedisce l'inserimento di lavoratori in un turno pieno. si possono inserire nuovi capocantieri ma non nuovi lavoratori
drop trigger if exists inserimento_lavoratore;
delimiter $$
create trigger inserimento_lavoratore before insert on Realizzazione
for each row
begin
declare Occupanti int default 0;
declare Posti int default 0;
set Occupanti = (
select count(R.Lavoratore)
from Realizzazione R 
where R.Data=New.Data and R.Ora=New.Ora and R.Lavoro=New.Lavoro
);
set Posti = (
select sum(C.MaxOperai)
from Direzione D inner join Capocantiere C on C.CodFiscale=D.Capocantiere
where D.Data=New.Data and D.Ora=New.Ora and New.Lavoro=D.Lavoro
);
if (Occupanti=Posti) then 
signal sqlstate '45000'
set message_text = 'Turno al completo';
end if;
end $$
delimiter ;

-- impossibile piazzare un infisso in una posizione già occupata da un altro 
drop trigger if exists controllo_infissi;
delimiter $$
create trigger controllo_infissi before insert on ViaDiAccesso
for each row
begin
declare VanoUtile int default 0;
declare x1 int default 0;
declare x2 int default 0;
declare y1 int default 0;
declare y2 int default 0;
declare NonValidi int default 0;
set x1= New.PosOrizzontale;
set x2= New.PosOrizzontale+New.Lunghezza;
set y1= New.PosVerticale;
set y2= New.PosVerticale+New.Altezza;   -- punti che delimitano l'area occupata dal nuovo infisso 

set NonValidi = (
select COUNT(*)
from ViaDiAccesso 
where codmuro=new.codmuro and(
(PosOrizzontale<=x1 and x1<=PosOrizzontale+Lunghezza) and (PosVerticale<=y1 and y1<=PosVerticale+Altezza) or
(PosOrizzontale<=x2 and x2<=PosOrizzontale+Lunghezza) and (PosVerticale<=y1 and y1<=PosVerticale+Altezza) or
(PosOrizzontale<=x2 and x2<=PosOrizzontale+Lunghezza) and (PosVerticale<=y2 and y2<=PosVerticale+Altezza) or
(PosOrizzontale<=x1 and x1<=PosOrizzontale+Lunghezza) and (PosVerticale<=y2 and y2<=PosVerticale+Altezza) or
(PosOrizzontale<=x1 and x2<=PosOrizzontale+Lunghezza) and (PosVerticale<=y1 and y2<=PosVerticale+Altezza) or
(x1<=PosOrizzontale and PosOrizzontale+Lunghezza<=x2) and (y1<=PosVerticale and PosVerticale+Altezza<=y2)
));
if (NonValidi!=0) then 
signal sqlstate '45000'
set message_text = 'Impossibile aggiungere nuova via di accesso in quanto si sovrappone ad una precedente';
end if;

end $$
delimiter ;

DROP TRIGGER IF EXISTS Calamita_Coerenti;
DELIMITER $$
CREATE TRIGGER Calamita_Coerenti
BEFORE INSERT ON Calamita
FOR EACH ROW
BEGIN
DECLARE MESSAGE_TEXT VARCHAR(200) DEFAULT '';
IF NEW.Evento NOT IN (SELECT DISTINCT Nome
				      FROM Rischio)
                      THEN SIGNAL SQLSTATE '45000';
                      SET MESSAGE_TEXT='Tipo di evento calamitoso inesistente';END IF;
                      
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS Linee_Coerenti;
DELIMITER $$
CREATE TRIGGER Linee_Coerenti
BEFORE INSERT ON Muro
FOR EACH ROW
BEGIN
DECLARE MESSAGE_TEXT VARCHAR(200) DEFAULT '';
IF NEW.Linea NOT IN ('Semicirconferenza', 'Retta','Arco','Cironferenza')
                      THEN SIGNAL SQLSTATE '45000';
                      SET MESSAGE_TEXT='Tipo di linea inesistente';END IF;
                      
END $$
DELIMITER ;





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
INSERT INTO AreaGeografica
VALUES('Firenze'), ('Foligno'),('Careggine'),('Norcia'), ('Orbetello');
COMMIT;
INSERT INTO Edificio
VALUES('FI00123032022', 'Abitazione',43.769, 11.254,'Firenze'),('FI00128032021', 'Deposito', 43.771, 11.255,'Firenze' ),
('FI00101012022', 'Abitazione', 43.773, 11.255,'Firenze' ),
('FI00124042022', 'Abitazione',43.770, 11.253,'Firenze'),
('CA00101022004', 'Ufficio',  44.119, 10.325, 'Careggine' ),('NO00131122021', 'Abitazione',  42.791, 13.096 , 'Norcia'),('OB00105062022', 'Abitazione', 42.440, 11.219,'Orbetello' );
INSERT INTO Muro
VALUES
('abcde12345',300,500, "retta"),
('abcdef2345',300,500,"retta"),
('abcdefg345',300,500,"retta"),
('bcde123456',300,400,"retta"),
('bcdef23456',300,300,"arco"),
('cde1234567',400,400,"retta"),
('de12345678',400,500,"retta"),
('ef23456789',300,600,"arco"),
('efg1234567',300,700,"semicirconferenza"),
('efgh123456',400,800,"arco"),
('cr12121212',400,900,"retta"),
('ob33333333',400,400,"semicirconferenza"),
('ob44444444',400,500,"retta"),
('ob55555555',300,600,"retta"),
('no24242424',300,600,"retta"),
('no34343434',300,300,"arco");

INSERT INTO Vano 
VALUES('FI00123032022','ba1010fi22', 15, 15, 30, 30,8, 'Balcone',0,1),('FI00123032022','sa1020fi22', 15, 15, 30, 30,8, 'Salotto',0,1),
('FI00123032022','cu2010fi22', 15, 15, 30, 30,8, 'Cucina',0,2),('FI00123032022','ca2020fi22', 15, 15, 30, 30,8, 'Camera',0,2),
('FI00123032022','ba3010fi22', 15, 15, 30, 30,8, 'Bagno',0,3),('FI00123032022','ca3030fi22', 15, 15, 30, 30,8, 'Camera',0,3),
('FI00123032022','ca4010fi22', 15, 15, 30, 30,8, 'Camera',0,4),('FI00123032022','es0015fi22', NULL, NULL, NULL, NULL,NULL, 'Esterno',0,NULL),
('FI00128032021','co5010fi22', 15, 15, 30, 30,8, 'Corridoio',0,5), -- edificio a firenze con numero piani maggiore
('FI00101012022','co3011fi22', 15, 15, 30, 30,8, 'Corridoio',0,3), -- edificio a firenze con numero piani minore
('FI00124042022','co6011fi22', 15, 15, 30, 30,8, 'Corridoio',0,6), -- edificio a firenze con numero piani maggiore

('NO00131122021','co1010no22',15, 15, 30, 30,8, 'Corridoio',0,1),
('NO00131122021','co1012no22', NULL, NULL, NULL, NULL,NULL, 'Esterno',0,NULL),('NO00131122021','co1013no22',15, 15, 30, 30,8, 'Corridoio',0,1),
('OB00105062022','co1010ob22',15, 15, 30, 30,8, 'Corridoio',0,1),
('CA00101022004','co1010ca22',15, 15, 30, 30,8, 'Corridoio',0,1);


INSERT INTO Parete
VALUES
('ba1010fi22','abcde12345','T'),
('sa1020fi22','abcdef2345','E'),
('sa1020fi22','abcdefg345','N'),
('cu2010fi22','bcde123456','T'),
('ca2020fi22','bcdef23456','T'),
('ba3010fi22','cde1234567','E'),
('ca4010fi22','de12345678','W'),
('es0015fi22','de12345678','E'),
('co5010fi22','ef23456789','E'),
('co3011fi22','efg1234567','E'),
('co6011fi22','efgh123456','E'),
('co1010no22','no34343434','E'),
('co1012no22','no24242424','S'),
('co1010ob22','ob33333333','T'),
('co1010ca22','cr12121212','E');
INSERT INTO ViaDiAccesso
VALUES('abcdefg345', 50, 0,'porta',NULL,100,100,'sa1020fi22'), ('bcdef23456', 50, 0,'portafinestra',NULL,100,100,'ca2020fi22') ;
insert into Danno
values
           (1111,'Crepa profonda','2012-12-10'),
            (1112,'Crepa leggera','2022-11-16'),
(1113,'Distaccamento tamponatura','2022-12-12'),
         (1114,'Crollo Pilastro','2022-12-20'),
     (2222,'Sfaldamento intonaco','2022-12-25'),
          (2225,'Crollo Pilastro','2022-09-17'),
     (2223,'Sfaldamento intonaco','2022-11-12'),
     (2224,'Sfaldamento intonaco','2022-11-13'),
        (3333,'Caduta calcinacci','2022-11-10'),

        (3336,'Caduta calcinacci','2022-10-10'),
        (3334,'Caduta calcinacci','2012-10-10'),
        (3335,'Caduta calcinacci','2007-10-10'),
        
        (6666,'Caduta calcinacci','2023-01-01'),

        (4444,'Caduta calcinacci','2007-10-10'),
(4445,'distaccamento tamponatura','2007-11-10'),
(4446,'distaccamento tamponatura','2022-12-10'),
            (4447,'Crepa leggera','2017-11-10'),
            (4448,'Crepa leggera','2022-11-24'),
            (4449,'Crepa leggera','2022-11-25'),

          (5551,'Crollo Pilastro','2022-12-16');

INSERT INTO PareteDanneggiata
VALUES

(1111,'co3011fi22','efg1234567'),
(1112,'co3011fi22','efg1234567'),
(1113,'co3011fi22','efg1234567'),
(1114,'co3011fi22','efg1234567'),
(2222,'ba3010fi22','cde1234567'),
(2222,'sa1020fi22','abcdef2345'),
(2225,'sa1020fi22','abcdef2345'),
(2223,'ba3010fi22','cde1234567'),
(2224,'cu2010fi22','bcde123456'),
(3333,'co6011fi22','efgh123456'),
(3336,'co1010no22','no34343434'),
(3334,'co1010no22','no34343434'),
(3335,'co1010no22','no34343434'),
(6666,'co1012no22','no24242424'),
(4444,'co1010ob22','ob33333333'),
(4445,'co1010ob22','ob33333333'),
(4446,'co1010ob22','ob33333333'),
(4447,'co1010ob22','ob33333333'),
(4448,'co1010ob22','ob33333333'),
(4449,'co1010ob22','ob33333333'),
(5551,'co1010ca22','cr12121212');



   
INSERT INTO Sensore
VALUES 
('grh01','ba1010fi22','abcde12345',152,153),
('grh02','ba1010fi22','abcde12345',152,153),
('erh03','sa1020fi22','abcdef2345',152,153),
('grh03','sa1020fi22','abcdefg345',152,153),
('grh04','sa1020fi22','abcdefg345',100,153),
('grh05','cu2010fi22','bcde123456',152,153),
('grh06','ca2020fi22','bcdef23456',122,153),
('grh07','ba3010fi22','cde1234567',152,153),
('grh08','ca4010fi22','de12345678',152,153),
('grh09','es0015fi22','de12345678',152,153),
('acc01','ca4010fi22','de12345678',152,153),

('grh10','co5010fi22','ef23456789',152,153),
('grh11','co3011fi22','efg1234567',152,153),
('grh12','co6011fi22','efgh123456',102,103),

('grh13','co6011fi22','efgh123456',152,153),

('acc14','co1010ca22','cr12121212',152,153),
('grh14','co1010ca22','cr12121212',152,153);
COMMIT;

Insert INTO SensoreSismico
VALUES('grh01', 'Estensimetro',2,2,2),('grh02', 'Estensimetro',2,2,2),('grh03', 'Giroscopio',2,2,2),('erh03', 'Estensimetro',2,2,2),('grh14', 'Estensimetro',2,2,2),
('grh04', 'Giroscopio',1.5,1.5,1.5),('grh05', 'Giroscopio',2,2,2),('grh06', 'Giroscopio',2,2,2),('grh07', 'Giroscopio',2,2,2),('grh08', 'Giroscopio',2,2,2),
('grh09', 'Giroscopio',2,2,2),('grh10', 'Giroscopio',1,1,1),('grh11', 'Giroscopio',1,1,1),('grh12', 'Giroscopio',1,1,1),('acc01', 'Accelerometro',0,0,0),('acc14','Accelerometro',2,2,2);
INSERT INTO sensoreAmbientale
VALUES('grh13','Termometro',5);

INSERT INTO Stato
VALUES ('FI00123032022','2022-12-10', 'D', 'D'),
('FI00123032022','2022-12-13', 'C', 'C'),
 ('FI00123032022','2022-12-15', 'D', 'D'),
('CA00101022004', '2022-12-16', 'D', 'D'),
('CA00101022004','2022-12-22','D','D'),
('OB00105062022','2022-11-23','D','D'),
('OB00105062022','2022-12-03','C','C'),
('FI00123032022',CURRENT_DATE,'D', 'D'),
('FI00101012022','2022-12-19','D', 'D'),
('NO00131122021','2022-12-31','D', 'D'),
('FI00124042022',CURRENT_DATE,'D', 'D');






INSERT INTO AlertSismico
VALUES('grh01',CURRENT_TIMESTAMP,3.0,3.00,3.00); -- estensimetro soffitto
INSERT INTO AlertSismico
VALUES('grh02',CURRENT_TIMESTAMP,3.0,3.02,3.00); -- estensimetro soffitto
INSERT INTO AlertSismico
VALUES('grh14',CURRENT_TIMESTAMP,100.0,100.02,100.00); -- estensimetro su edificio diverso ma nello stesso stato 
INSERT INTO AlertSismico
VALUES('erh03',CURRENT_TIMESTAMP,35.0,35.02,35.5); -- piano1 estensimetro pparete nord
INSERT INTO AlertSismico
VALUES('grh03',CURRENT_TIMESTAMP,35.0,35.02,35.5) -- piano 1 giroscopio porta
,('grh04',CURRENT_TIMESTAMP,31.0,31.0,31.0) -- piano 1
,('grh05',CURRENT_TIMESTAMP,1.0,1.02,1.5) -- piano2
,('grh06',CURRENT_TIMESTAMP,20.0,20.00,20.00) -- piano2 con portafinestra
,('grh07',CURRENT_TIMESTAMP,2.0,2.00,2.00) -- piano3
,('grh08',CURRENT_TIMESTAMP,20.0,20.00,20.00) -- piano 4
,('grh09',CURRENT_TIMESTAMP,10.00,10.00,10.00) -- piano 4
,('grh11',CURRENT_TIMESTAMP,5.0,1.00,3.00) -- firenze edificio con meno piani
,('grh12',CURRENT_TIMESTAMP,3.0,3.00,3.00); -- firenze con piu piani
INSERT INTO AlertSismico
VALUES('acc01','2023-01-06 20:16:51',0.00297 ,0.00297 ,0.00297 ); -- intensita=4
INSERT INTO AlertSismico
VALUES('acc14','2023-01-06 20:16:51',4,4,4 ); 
DROP FUNCTION IF EXISTS stringherandom;
DELIMITER $$
CREATE FUNCTION stringherandom()
RETURNS VARCHAR(20) DETERMINISTIC
BEGIN
DECLARE res VARCHAR(20) DEFAULT "";
DECLARE i INT DEFAULT 0;
WHILE(i<20) DO
IF(i<15) THEN
SET res=CONCAT( (CHAR(FLOOR(65+RAND()*(90-65)))),res);
ELSE
SET res=CONCAT( (CHAR(FLOOR(48+RAND()*(57-48)))),res);
END IF;
SET i=i+1;
END WHILE;
RETURN res;
END $$
DELIMITER ;
BEGIN;
INSERT INTO Materiale
VALUES 
('Mte10','Solid Mattone',20,5),
('Mte11','Solid Mattone',20,5),
('Mte12','Solid Mattone',20,3),
('Mte13','CemenTop',20,10),
('Mte14','CemenTop',80,3),
('Mte15','CemenTop',20,3),
('Mte16','GlobaLaterizi',100,30),
('Mte17','GlobaLaterizi',12,40),
('Mte18','GlobaLaterizi',80,30),
('Mte19','GlobaLaterizi',12,3),
('PtH31','Solid Mattone',28,1),
('PtH32','Solid Mattone',16,4),
('PtH33','GlobaLaterizi',90,10),
('PtH34','CemenTop',50,6),
('It82A','CemenTop',90,15),
('It82B','CemenTop',100,32),
('It82C','CemenTop',200,12),
('It82D','GlobaLaterizi',120,43),
('Ps12A','Solid Mattone',220,23),
('Ps12B','GlobaLaterizi',20,32),
('Ps12C','GlobaLaterizi',20,12),
('Ps12D','Solid Mattone',120,100),
('Ps12E','CemenTop',203,31),
('Ps12F','Solid Mattone',20,3),
('MGx35','Solid Mattone',120,103);






BEGIN;
INSERT INTO MaterialeGenerico
VALUES('MGx35','Cemento',5,6,7,8);
COMMIT;


insert into Piastrella values /*6 piastrelle*/
('Ps12A', 'Fiore', 12, 'Quadrato', 'Argilla', 20, 20, 3),
('Ps12B',  'Esagono', 7, 'Esagono', 'Ceramica', 35, 35, 3),
('Ps12C', 'Diamante', 8, 'Esagono', 'Ceramica', 40, 40, 3),
('Ps12D',  NULL, 10, 'Quadrato', 'Ceramica', 20, 20, 3),
('Ps12E',  'Diamante', 8, 'Rettangolo', 'Argilla', 20, 40, 3),
('Ps12F',  NULL, 10, 'Rettangolo', 'Legno', 10, 30, 4);



insert into Intonaco values /*4 intonaci*/
('It82A', 'Rasato', 'Cemento e calcare', 1, 1),
('It82B','Decorativo','Cemento e calcare', 2, 2),
('It82C', 'Rustico','Cemento e argilla', 3, 2),
('It82D', 'Rasato','Cemento e argilla', 3, 1);

insert into Pietra values /*4 pietre*/
('PtH31', 'Random', 120, 60, 'Quarzo'),
('PtH32',  'Ordinate orizzontalmente', 150, 50, 'Marmo'),
('PtH33',  'Ordinate verticalmente', 110, 60, 'Granito'),
('PtH34',  'Random', 110, 80, 'Silicati');

insert into Alveolatura values /*3 alveolature*/
('ARE01',  12, 2,2, 'Vuoto', 'Quadrato', 6),
('ARM01', 12, 2, 3, 'Vuoto', 'Rettangolo', 6),
('ARI01', 5, 2, 2, 'Isolante termico', 'Esagono', 8);
insert into Mattone values /*10 mattoni*/
('Mte10', 5, 12, 25, 'Calcestruzzo','ARI01'),
('Mte11',  12, 15, 30, 'Laterizio','ARI01'),
('Mte12',  12, 15, 30,'Laterizio','ARI01'),
('Mte13', 5, 12, 25, 'Argilla','ARI01'),
('Mte14', 12, 24,24, 'Laterizio','ARI01'),
('Mte15', 12, 15, 30, 'Calcestruzzo','ARI01'),
('Mte16',5, 12, 25, 'Laterizio','ARI01'),
('Mte17',12, 24,24, 'Argilla','ARI01'),
('Mte18', 12, 15, 30, 'Laterizio','ARI01'),
('Mte19',5, 12, 25, 'Calcestruzzo','ARI01');







INSERT INTO ProgettoEdilizio
VALUES('abr5st6ed29qwe','2022-01-03','2022-02-03','2022-02-08','2022-09-03','FI00123032022'),
('cbr5st6ed29qwe','2022-01-03','2022-02-03','2022-02-08','2022-09-03','CA00101022004'),
('orb5st6ed29qwe','2022-01-03','2022-02-03','2022-02-08','2022-09-03','OB00105062022');
COMMIT;
INSERT INTO Stadio
VALUES ('abr5st6ed29qwe',1,'Allestimento cantiere','2022-02-08','2022-02-12'),('abr5st6ed29qwe',2,'Costruzione scheletro','2022-02-13','2022-04-07'),
('cbr5st6ed29qwe',3,'Costruzione pareti','2022-04-08','2022-06-15'),('cbr5st6ed29qwe',4,'Copertura pareti','2022-06-16','2022-09-01'),
('orb5st6ed29qwe',5,'Smantellamento cantiere','2022-09-02','2022-09-03');
COMMIT;
INSERT INTO Lavoro
VALUES('wrk123F','abr5st6ed29qwe',1,'scavo fondamenta',0),
('wrk123X','abr5st6ed29qwe',2,'installazione di giunti sismici',0),
('erxR456X','cbr5st6ed29qwe',3,'costruzione',0),
('prxT456X','abr5st6ed29qwe',1,'costruzione pilastri',0),
('bystre4312','abr5st6ed29qwe',1,'Colata cemento',0),
('Axtreiu02','abr5st6ed29qwe',1,'Posa mattoni',0),
('erxT156X','cbr5st6ed29qwe',4,'Posa pietra',0),
('p7890tyf','abr5st6ed29qwe',1,'installazione di cuciture in metallo',0), -- TEST
('UIoparte5671','cbr5st6ed29qwe',4,'sopraelevamento struttura',0),
('34aQWert567','cbr5st6ed29qwe',4,'Posa infisso',0),
('ciao2098Q','cbr5st6ed29qwe',4,'isolamento terreno',0),
('drdaes8907','cbr5st6ed29qwe',4,'consolidamento dei solai',0),
('UIyetra342','cbr5st6ed29qwe',4,'sopraelevamento struttura',0),
('Tyraes4561','orb5st6ed29qwe',5,'consolidamento cerchiature',0);
COMMIT;
INSERT INTO Turno
VALUES(CURRENT_DATE,1,'wrk123F'),(CURRENT_DATE,3,'wrk123F'),(CURRENT_DATE,5,'wrk123F'),(current_date(),6,'wrk123X'),(CURRENT_DATE,1,'wrk123X');
insert into Lavoratore (Cognome, Nome, CodFiscale,Stipendio)
values /*15 lavoratori*/
('Teci','Aristeo','TCERST17M19G022E',10),
('Isajia','Samuele','SJISML14R07L989V',11),
('Baldessare','Gerardo','BLDGRD46E09H556Q',11),
('Battagliese','Ciriaco','BTTCRC08A23B408P',10),
('Agazzino','Efisio','GZZFSE86E21E238V',9),
('Sandonini','Remondo','SNDRND48B17B268I',10),
('Avantaggiato','Torquato','VNTTQT02B28A010E',10),
('Carosio','Pompeo','CRSPMP53S17C268E',9),
('Cunial','Filippo','CNLFPP03E08A650U',9),
('Cuomo','Folco','CMUFLC76C11A220D',10),
('Bechi','Arrigo','BCHRRG40E24G877Y',11),
('Sasso','Napoleone','SSSNLN17H11L575L',11),
('Lunghi','Alarico','LNGLRC34H13D927C',10),
('Bosi','Aureliano','BSORLN61E27I417M',11),
('Caverzaghi','Elio','CVRLEI20P07B013T',10);

insert into Capocantiere (Cognome, Nome, CodFiscale, Stipendio, MaxOperai)
values -- 4 capicantiere
('Cappilli','Ilaria','CPPLRI07T53G455N',11,5),
('Cologna','Polidoro','CLGPDR83R30E880G',12,4),
('Franchino','Giusto','FRNGST88R17B880N',10,5),
('Legè','Leda','LGELDE35A56H405Z',11,6);

INSERT INTO Realizzazione
VALUES('wrk123F',CURRENT_DATE,1,'TCERST17M19G022E'),
('wrk123F',CURRENT_DATE,3,'TCERST17M19G022E'),
('wrk123F',CURRENT_DATE,5,'TCERST17M19G022E'),
('wrk123X',CURRENT_DATE,1,'SJISML14R07L989V'),
('wrk123X',CURRENT_DATE,1,'GZZFSE86E21E238V'), -- stipendio piu basso
('wrk123X',CURRENT_DATE,1,'SNDRND48B17B268I');
SELECT costo
FROM Lavoro
WHERE Codice='wrk123F';
INSERT INTO Rischio 
VALUES('Terremoto','Firenze','2','1950-06-15'),('Terremoto','Foligno',4,'1950-06-15'),('Terremoto','Careggine',5,'1950-06-15'),('Terremoto','Norcia',2,'1950-06-15'),
('Terremoto','Orbetello',1,'1950-06-15'),('Frana','Careggine',2,'1950-06-15'),('Frana','Foligno',3,'1950-06-15'),('Frana','Norcia',3,'1950-06-15'),
('Frana','Firenze',4,'1950-06-15'),('Frana','Orbetello',1,'1950-06-15'),('Incendio','Careggine',3,'1950-06-15'),('Incendio','Foligno',3,'1950-06-15'),
('Incendio','Norcia',2,'1950-06-15'),('Incendio','Firenze',2,'1950-06-15'),('Incendio','Orbetello',1,'1950-06-15'),
('Allagamento','Firenze',3,'1950-06-15'),('Allagamento','Foligno',2,'1950-06-15'),('Allagamento','Norcia',3,'1950-06-15'),
('Allagamento','Careggine',1,'1950-06-15'),('Allagamento','Orbetello',4,'1950-06-15'),('Caldo','Foligno',4,'1950-06-15');
COMMIT;
INSERT INTO Calamita
VALUES (43.769, 11.206,'2023-01-06 20:16:51','Terremoto',0);-- circa 4 km da edificio
INSERT INTO ComposizioneMuro
VALUES('Mte10','abcde12345',60),('Mte11','bcde123456',40),('Mte11','ob33333333',60),('Mte10','cr12121212',60),('Mte12','abcde12345',60);

COMMIT;
DROP PROCEDURE IF EXISTS popola_composizione_parete;
DELIMITER $$
CREATE PROCEDURE popola_composizione_parete()
BEGIN
DECLARE MatCurr VARCHAR(20) DEFAULT '';
DECLARE MuroCurr VARCHAR(20) DEFAULT '';
DECLARE VanoCurr VARCHAR (20) DEFAULT '';
DECLARE EdCurr VARCHAR (20) DEFAULT '';
DECLARE Finito INTEGER DEFAULT 0;
DECLARE cur1 CURSOR FOR (
SELECT D.CodProdotto
FROM (SELECT M.CodProdotto
  FROM Pietra P NATURAL JOIN Materiale M 
  UNION ALL
  SELECT M.CodProdotto
  FROM Piastrella PI NATURAL JOIN Materiale M
  UNION ALL
  SELECT M.CodProdotto
  FROM Intonaco I NATURAL JOIN Materiale M) AS D
ORDER BY RAND() LIMIT 5);
DECLARE cur2 CURSOR FOR (
SELECT  CodMuro, CodVano
FROM Parete
ORDER BY RAND() LIMIT 5);
DECLARE CONTINUE HANDLER FOR NOT FOUND SET Finito=1; 
OPEN Cur1;
OPEN cur2;
scan: LOOP
FETCH cur1 INTO MatCurr;
FETCH cur2 INTO  MuroCurr,VanoCurr;
IF(Finito=1) THEN LEAVE scan; END IF;
INSERT INTO ComposizioneParete
VALUES(MatCurr, MuroCurr,VanoCurr,1+RAND()*100);
END LOOP;
CLOSE cur1;
CLOSE cur2;
END $$
DELIMITER ;
CALL popola_composizione_parete();

DROP PROCEDURE IF EXISTS popola_composizione_muro;
DELIMITER $$
CREATE PROCEDURE popola_composizione_muro()
BEGIN
DECLARE MatCurr VARCHAR(20) DEFAULT '';
DECLARE MuroCurr VARCHAR(20) DEFAULT '';
DECLARE Finito INTEGER DEFAULT 0;
DECLARE cur1 CURSOR FOR (
SELECT D.CodProdotto
FROM (SELECT M.CodProdotto
  FROM Pietra P NATURAL JOIN Materiale M 
  UNION ALL
  SELECT M.CodProdotto 
  FROM Mattone MA NATURAL JOIN Materiale M) AS D
ORDER BY RAND() LIMIT 5);
DECLARE cur2 CURSOR FOR (
SELECT Codice
FROM Muro
ORDER BY RAND() LIMIT 5);
DECLARE CONTINUE HANDLER FOR NOT FOUND SET Finito=1; 
OPEN Cur1;
OPEN cur2;
scan: LOOP
FETCH cur1 INTO MatCurr;
FETCH cur2 INTO MuroCurr;
IF(Finito=1) THEN LEAVE scan; END IF;
INSERT INTO ComposizioneMuro
VALUES(MatCurr,MuroCurr,1+RAND()*100);
END LOOP;
CLOSE cur1;
CLOSE cur2;
END $$
DELIMITER ;
CALL popola_composizione_muro();

DROP PROCEDURE IF EXISTS popola_produzione;
DELIMITER $$
CREATE PROCEDURE popola_produzione()
BEGIN

DECLARE matcorr VARCHAR(5) DEFAULT '';
DECLARE finito INTEGER DEFAULT 0;
DECLARE cur CURSOR FOR(
   SELECT CodProdotto
   FROM Materiale
   ORDER BY RAND() lIMIT 5);
DECLARE CONTINUE HANDLER FOR NOT FOUND SET FInito=1;
   

OPEN cur;
scan:LOOP

FETCH cur INTO matcorr;
IF (Finito=1) THEN LEAVE scan; END IF;
INSERT INTO Produzione
VALUES(stringherandom(),matcorr);
END LOOP ;
CLOSE cur;
END $$
DELIMITER ;
   
CALL popola_produzione;
SELECT * FROM produzione;

DROP PROCEDURE IF EXISTS popola_schedario;
DELIMITER $$
CREATE PROCEDURE popola_schedario()
BEGIN 
DECLARE lavcorr VARCHAR(20) DEFAULT '';
DECLARE lotcorr VARCHAR(20) DEFAULT '';
DECLARE finito INTEGER DEFAULT 0;
DECLARE cur1 CURSOR FOR(
   SELECT codice
   FROM Lavoro
   ORDER BY RAND() LIMIT 5);
DECLARE cur2 CURSOR FOR(
       SELECT lotto
       FROM Produzione
       ORDER BY RAND() lIMIT 5);
DECLARE CONTINUE HANDLER FOR NOT FOUND SET FInito=1;
       
OPEN cur1;
OPEN cur2;
scan:LOOP
FETCH cur1 INTO lavCorr;
FETCH cur2 INTO lotcorr;
IF (Finito=1) THEN LEAVE scan; END IF;
INSERT INTO Schedario
VALUES(lavcorr,lotcorr, NOW()- INTERVAL RAND()*30 DAY,1+RAND()*(100-0));
END LOOP ;
CLOSE cur1;
CLOSE cur2;
END $$
DELIMITER ;
CALL popola_schedario();

CALL popola_schedario();
CALL popola_schedario();
SELECT costo
FROM Lavoro
WHERE Codice='wrk123F';
SELECT * FROM Schedario;
