/*calcolo della distanza tra due punti*/
drop function if exists distanza;
delimiter $$
create function distanza(lon1 float(5), lon2 float(5), lat1 float(5), lat2 float(5)) returns float deterministic
begin
set lon1=lon1*pi()/180;
set lon2=lon2*pi()/180;
set lat1=lat1*pi()/180;
set lat2=lat2*pi()/180;
return 6373* acos((sin(lat1)*sin(lat2))+cos(lat1)*cos(lat2)*cos(lon2-lon1));
end $$
delimiter ;

/*calcolo dell'ampiezza delle onde sismiche generate da un terremoto*/
drop function if exists calcolo_ampiezza;
delimiter $$
create function calcolo_ampiezza(misurax float(5), misuray float(5), misuraz float(5)) returns float(5) deterministic
begin
return sqrt(power(misurax,2)+power(misuray,2)+power(misuraz,2));
end $$
delimiter ;

/*calcolo dell'ampiezza media delle oscillazioni recepite da un edificio nei due minuti successivi ad un dato timestamp */
drop function if exists calcolo_ampiezza_media;
delimiter $$
create function calcolo_ampiezza_media(soggetto varchar(13), istante datetime) returns float(5) deterministic
begin
declare avgampiezzax float(5) default 0;
declare avgampiezzay float(5) default 0;
declare avgampiezzaz float(5) default 0;

select avg(A.ValX),avg(A.ValY),avg(A.ValZ) into avgampiezzax, avgampiezzay, avgampiezzaz
from alertsismico A inner join sensoresismico SS on SS.CodSensore=A.CodSensore
                    inner join sensore S on S.Codice=SS.CodSensore
                    inner join Vano V on V.Codice=S.CodVano
where V.CodEd=soggetto and SS.Tipo='accelerometro' and istante>=A.Timestamp and A.Timestamp <= istante+interval 120 second;

return calcolo_ampiezza(avgampiezzax, avgampiezzay, avgampiezzaz);
end $$
delimiter ;

/*in base ai valori dell'accelerometro calcola l'intensità*/
drop function if exists intensita;
delimiter $$
create function intensita(val float(5)) returns int deterministic
begin
case
when (val<0.00046) then return 1;
when (val>=0.00046 and val<0.00145) then return 2;
when (val>=0.00145 and val<0.00297) then return 3;
when (val>=0.00297 and val<0.0276) then return 4;
when (val>=0.0276 and val<0.115) then return 5;
when (val>=0.115 and val<0.215) then return 6;
when (val>=0.215 and val<0.401) then return 7;
when (val>=0.401 and val<0.747) then return 8;
when (val>=0.747 and val<1.39) then return 9;
when (val>=1.39) then return 10;
end case;
end $$
delimiter ;

drop function if exists intensita_edificio;
delimiter $$
create function intensita_edificio(tempo datetime, edificio varchar(13))
returns int deterministic
begin
declare ampiezza float(5) default 0;
declare intensita int default 0;


set ampiezza = calcolo_ampiezza_media(edificio, tempo);
set intensita= intensita(ampiezza);
return intensita;
end $$
delimiter ;

/*calcolo dell'intensità di un evento nel suo epicentro   I(x)= Im - k(x^2)/Im  data una calamità ed un edificio calcola l'intensità nell'epicentro  */
drop function if exists intensita_epicentro;
delimiter $$
create function intensita_epicentro(tempo datetime, lat_evento float(5), lon_evento float(5), tipo varchar(45), edificio varchar(13)) returns float deterministic
begin
declare ampiezza float(5) default 0;
declare raggio float(5) default 0;
declare intensita int default 0;
declare intensitacentro int default 0;
declare lat_edificio float(5) default 0;
declare lon_edificio float(5) default 0;
declare rischio int default 1;
declare area varchar(45) default '';

select E.Latitudine, E.Longitudine, E.Area into lat_edificio, lon_edificio, area
from Edificio E
where E.Codice=edificio;

set rischio = ( 
select R. Coefficiente
from Rischio R
where R.Nome=tipo and R.Area=area and R.UltimoUpdate=(
												 select max(R1.UltimoUpdate)
                                                 from Rischio R1
                                                 where R1.Nome=tipo and R1.Area=area));

set ampiezza = calcolo_ampiezza_media(edificio, tempo);
set intensita= intensita(ampiezza);
set raggio = distanza(lon_edificio,lon_evento,lat_edificio,lat_evento);

set intensitacentro = (intensita + (sqrt(power(intensita,2) + 4*rischio*power(raggio,2))))/2;
return intensitacentro;

end $$
delimiter ;
/*popola percezione e calamita con nuovi dati*/
drop function if exists aggiorna_calamita;
delimiter $$
create function aggiorna_calamita(tempo datetime, lat_evento float(5), lon_evento float(5), edificio varchar(13), tipo varchar(45),mag int) returns float(5) deterministic
begin

if not exists ( select *
                from Calamita C
                where C.latitudine=lat_evento and C.Longitudine=lon_evento and C.Timestamp=tempo ) then
	insert Calamita
    values (lat_evento,lon_evento,tempo,'indefinito',mag); -- ancora non si conosce l'  identità della calamità verrà poi aggiornata
    else
    update Calamita C
    set C.Magnitudo=mag
    where C.latitudine=lat_evento and C.Longitudine=lon_evento and C.Timestamp=tempo;
    end if;



return mag;
end $$
delimiter ;

drop function if exists aggiorna_percezione;
delimiter $$
create function aggiorna_percezione(tempo datetime, lat_evento float(5), lon_evento float(5),edificio varchar(13), valore int) returns float(5) deterministic
begin
if not exists ( select *
                from Percezione P
                where P.latitudine=lat_evento and P.Longitudine=lon_evento and P.Timestamp=tempo and P.Coded=edificio ) then
	insert Percezione 
    values (lat_evento,lon_evento,tempo,edificio,valore);
    else
    update Percezione P
    set P.Intensita=valore
    where P.latitudine=lat_evento and P.Longitudine=lon_evento and P.Timestamp=tempo and P.Coded=edificio;
    end if;
    return valore;
    end $$
    delimiter ;
SELECT * FROM Calamita;
SET @a= intensita_epicentro ('2023-01-06 20:16:51',43.769, 11.206,'Terremoto','FI00123032022');
select @a;
SELECt aggiorna_calamita('2023-01-06 20:16:51',43.769, 11.206,'FI00123032022','terremoto',@a);
SELECT * FROM Calamita;
select distanza(43.769,43.769, 11.254, 11.206);
select avg(A.ValX),avg(A.ValY),avg(A.ValZ) into @ax,@ay, @az
from alertsismico A inner join sensoresismico SS on SS.CodSensore=A.CodSensore
                    inner join sensore S on S.Codice=SS.CodSensore
                    inner join Vano V on V.Codice=S.CodVano
where V.CodEd='FI00123032022' and SS.Tipo='accelerometro' and '2023-01-06 20:16:51'>=A.Timestamp and A.Timestamp <= '2023-01-06 20:16:51'+interval 120 second;
set @modulo=calcolo_ampiezza(@ax,@ay,@az);
select @modulo;
set @i=intensita(@modulo);
SELECt aggiorna_percezione('2023-01-06 20:16:51',43.769, 11.206,'FI00123032022',@i);
SELECT * FROM Percezione;
DELETE FROM Percezione
WHERE TimeStamp='2023-01-06 20:16:51';

