############################################################################
################      Script per progetto BDSI 2019/20     #################
############################################################################
#                                                                          #
# GRUPPO FORMATO DA:                                                       #
#                                                                          #
# Matricola: 5364115  Cognome: Barreto Donayre  Nome: Andre Cristhian      #
# Matricola: 6378449  Cognome: Bennati 	       Nome:  Gianni               #
#                                                                          # 
############################################################################

############################################################################
################   Creazione schema e vincoli database     #################
############################################################################

drop database if exists Saniven;
create database if not exists Saniven;
use Saniven;

drop table if exists Composizione;
drop table if exists Pagamento;
drop table if exists Ordine;
drop table if exists Vettore;
drop table if exists Prodotto;
drop table if exists Clienti;

create table Clienti( 
idC	varchar(4) primary key,
cognome varchar(15),
nome varchar(15),
nAzienda varchar(20),
email varchar(8) not null,
tipo enum('privato','azienda') not null,
cf varchar(5),
piva int (5),
via varchar (15),
nCivico smallint,
città varchar(15),
prov varchar(2),
cap varchar (5)
) ENGINE=INNODB;

create table Prodotto(
idProd varchar(4) primary key,
descrizione varchar(25),
pesoSpec decimal(2,2),
prezzoDettaglio decimal(5,2) 
) ENGINE=INNODB;

create table Vettore(
idVettore varchar(5) primary key,
tipo varchar(15),
distMax decimal(3,2)
) ENGINE=INNODB;

create table Ordine(	
idOrd varchar(5) primary key,
stato varchar(20) not null,
destinatario varchar(4),
vettore varchar(5),

foreign key (destinatario) references Clienti(idC) on delete cascade,
foreign key (vettore) references Vettore(idVettore) on delete restrict
)ENGINE=INNODB;

create table Pagamento(  
fattura int,
idPay varchar(6), 
tipo varchar(10),
ordine varchar(10),
totale decimal(8,2),
dataOra DATETIME,

primary key(fattura,idPay,ordine),
foreign key(ordine) references Ordine(idOrd) on delete restrict
)ENGINE=INNODB; 

create table Composizione( 
idOrd varchar(10),
idProd varchar(4),
qta int,

primary key(idOrd,idProd),
foreign key(idOrd) references Ordine(idOrd) on delete no action,
foreign key(idProd) references Prodotto(idProd) on delete no action
) ENGINE=INNODB;

############################################################################
################  Creazione istanza: popolamento database  #################
############################################################################

load data local infile '/home/dispater/Documents/SanivenSQL/clienti.csv' into table Clienti
fields terminated by ','
ignore 2 lines
(idC,cognome,nome,nAzienda,email,tipo,cf,piva,via,nCivico,città,prov,cap);

insert into Prodotto values
('D032','Guanti in lattice',0.1,0.10),
('D025','occhiali',0.10,2.50),
('D007','occhiali a maschera',0.15,2.80),
('D001','visiera',0.03,5.0),
('D050','maschera semi filtrante',0.03,5.0),
('D010','scarpe antifortunistiche',0.03,5.0),
('D042','tuta di plastica',0.03,5.0),
('D016','maschera antipolvere',0.03,5.0);

insert into Vettore values
('dr111','drone',9.00),
('dr892','drone',1.50),
('crr22','corriere',null),
('crr55','corriere',null),
('dr333','drone',7.34),
('dr546','drone',4.34),
('dr232','drone',3.33),
('crr34','corriere',null),
('crr88','corriere',null),
('dr212','drone',1.00);

insert into Ordine values
('F267B','preparazione','99BK','dr111'),
('A217B','consegnato','99BB','dr892'),
('G287B','spedito','99RT','crr22'),
('V117B','spedito','45GG','crr55'),
('F0F7B','preparazione','45GI','dr333'),
('Z3F7B','spedito','78BF','dr546'),
('M9F7B','consegnato','56RF','dr232'),
('R6F7B','consegnato','64TK','crr34'),
('U8F9B','preparazione','32FR','crr88'),
('S6F7B','spedito','45RT','dr212');

load data local infile '/home/dispater/Documents/SanivenSQL/Pagamento.in' into table Pagamento
fields terminated by ';'
optionally enclosed by '-'
optionally enclosed by ':'
lines terminated by '\n'
starting by '*'
ignore 4 lines
(fattura,idPay,tipo,ordine,totale,dataOra);

load data local infile '/home/dispater/Documents/SanivenSQL/Composizione.in' into table Composizione
fields terminated by '$'
lines terminated by '$'
starting by ';'
ignore 5 lines
(idOrd,idProd,qta);

#############################################################################
################  Ulteriori vncoli tramite viste e/o trigger ################
#############################################################################

###TROVA NUMERO DI CONSEGNE EFFETUATE DEI DRONI:

drop view if exists consegneDroni;

create view consegneDroni(numeroConsegne) as
select count(*)
from Saniven.Ordine ord 
where stato='consegnato' and vettore like'dr%';

## PER VERIFICARE IL FUNZIONAMENTO
select * from consegneDroni;

###VISUALIZZA NOME COGNOME DEGLI UTENTI PRIVATI:

drop view if exists Utenti;

create view Utenti as
select concat(c.nome,' ',c.cognome) as utenti , c.tipo
from Clienti c
where c.tipo = 'privato';

## PER VERIFICARE IL FUNZIONAMENTO
select * from Utenti;

###VISUALIZZA I NOMINATIVI DELLE AZIENDE:

drop view if exists Aziende;

create view Aziende as
select nAzienda as nomeAzienda, tipo
from Clienti 
where tipo = 'Azienda';

## PER VERIFICARE IL FUNZIONAMENTO
#select * from Aziende;

###VISUALIZZA IL COSTO DELLE ORDINAZIONI DEGLI UTENTI PRIVATI:

drop view if exists spesaPrivati; 

create view spesaPrivati as 
select c.nome as utente , ord.idOrd as 'numero Ordine', pag.totale
from Ordine ord, Pagamento pag, Clienti c
where ord.idOrd=pag.ordine and ord.destinatario = c.idC and c.tipo = 'privato';

## PER VERIFICARE IL FUNZIONAMENTO
#select * from spesaPrivati;

###QUESTO TRIGGER INVERTE LA MAIL AZIENDALE, PEC@ART DIVENTA @ARTPEC:

DROP TRIGGER IF EXISTS InvertLegalMail;

DELIMITER $$

CREATE TRIGGER InvertLegalMail
BEFORE INSERT ON Saniven.Clienti
	FOR EACH ROW
		IF left(NEW.email,3)='pec' THEN SET NEW.email= CONCAT( substring(new.email,4,7),'pec' );
		END IF $$
		
DELIMITER ;

## PER VERIFICARE IL FUNZIONAMENTO:
# insert into Clienti values ('GBAB',null,null,'InvertMail','pec@art','azienda',null,77777,'Sebino',4,'Prato','PO','59100');
# select * from Clienti where Clienti.idC='GBAB';

### QUESTO TRIGGER CONTROLLA CHE IL CODICE DI UN NUOVO DRONE CORRISPONDA ALLO STANDARD AZIENDALE:

DROP TRIGGER IF EXISTS Saniven.checkDrone;
 
DELIMITER $$

CREATE TRIGGER CheckDrone
BEFORE INSERT ON Saniven.Vettore
for each row
begin
    if(substring(new.idVettore,2)!='dr') then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'questo non è un drone aziendale';
    end if;
    
 end$$

DELIMITER ;

## PER VERIFICARE IL FUNZIONAMENTO:

#select * from Saniven.Vettore; # stato attuale
# insert into Vettore values ('aaa11','drone',9.00); # blocherà l'inserimento di questi valori
# select * from Saniven.Vettore; # infatti esso non è presente nella tabella, tabella invariata

###QUESTO TRIGGER CONTROLLA CHE IL CODICE DI UN NUOVO CORRIERE CORRISPONDA ALLO STANDARD AZIENDALE:

DROP TRIGGER IF EXISTS Saniven.checkCorriere;

DELIMITER $$

CREATE TRIGGER checkCorriere
BEFORE INSERT ON Saniven.Vettore
FOR EACH ROW
BEGIN
    IF left(new.idVettore,3)!='crr' then 
		signal sqlstate '45000' SET message_text=' non è un corriere';        
	END IF;
END$$

DELIMITER ; 

## PER VERIFICARE IL FUNZIONAMENTO:
#select * from Vettore; # stato corrente 
#insert into Vettore values ('aaa11','corriere',9.00); # bloccherà l'inserimento di questa 
#select * from Vettore; # stato invariato

############################################################################
################ 				 Interrogazioni   		   #################
############################################################################

# 1- QUANTI CLIENTI SI SONO SERVITI DI SANIVEN:

select count(idC) as Utenti
from Clienti;

# 2- QUANTI PRIVATI:

select count(idC) as UtentiPrivati
from Clienti
where tipo ="privato";

# 3- QUANTE AZIENDE DI FIRENZE SI SONO SERVITE DI SANIVEN:

select count(idC) as AziendeFiorentine
from Clienti 
where tipo ="azienda" AND città="Firenze";

# 4- QUANTI MEMBRI DI UNA STESSA FAMIGLIA ABITANO A FIRENZE HANNO ORDINATO DPI:

select  count(c1.idC) as famigliari
from Clienti c1, Clienti c2
where c1.città = 'Firenze' and c1.cognome=c2.cognome and c1.nome <> c2.nome;

# 5- VISUALIZZARE CODICECLIENTE, NOMI COMPLETI DEGLI UTENTI REGISTRATI ORDINA PER COGNOME:

select c1.idC as codiceCliente, concat(c1.nome,' ',c1.cognome) as nomeCompleto
from Clienti c1, Clienti c2
where c1.cognome=c2.cognome and c1.nome <> c2.nome
order by c1.cognome;

# 6- TROVA I CODICI DEGLI ORDINI CHE SONO STATI SPEDITI E CODICE DEI VETTORI CHE LI TRASPORTANO:

select ord.idOrd, ord.vettore
from Ordine ord
where stato ='spedito';

# 7- TROVA LA DISTANZA MEDIA PERCORSA DA PARTE DEI DRONI AZIENDALI:

select AVG(distMax) as distanzaMedia
from Vettore
where tipo = 'drone';

# 8- TROVA NOME E CODICE DEI CLIENTI CHE HANNO QUALCHE ORDINE IN PREPARAZIONE:

select idC, nome, cognome, nAzienda as Azienda
from Clienti
where idC in ( select destinatario from Ordine where stato='preparazione');

# 9- TROVA PER OGNI AZIENDA TUTTI GLI ORDINI CHE HANNO RICHIESTO: VISUALIZZA NUMERO DELL'ORDINE, NOME DELL'AZIENDA E LO STATO DELL'ORDINAZIONE:

select distinct Ordine.idOrd, Clienti.nAzienda as nomeAzienda, Ordine.stato
from Ordine, Clienti
where destinatario in ( select idC from Clienti where tipo ='azienda') and Clienti.tipo='Azienda';

# 10- TROVA QUANTI SONO GLI ORDINI "PREPARAZIONE", "SPEDITI", " CONSEGNATI" :

select stato,count(*) as 'ordiniInCorso'
from Ordine
group by stato
order by stato;

# 11- CONTA QUANTI PRODOTTI VENDE L'AZIENDA "SANIVEN":

select count(*) as 'prodotti in vendita'
from Prodotto;

# 12- TROVA CODICE E DESCRIZIONE DEL PRODOTTO PIÙ PESANTE:

select idProd, descrizione
from Prodotto
where pesoSpec = ( select max(pesoSpec) as 'Oggetto-Pesante' from Prodotto );

# 13- TROVA PER OGNI COMPOSIZIONE IL PESO COMPLESSIVO E ORGANIZZALI IN MANIERA CRESCENTE:

select c.idOrd, (c.qta*pesoSpec) as 'pesoComplessivo', c.qta as 'numero pezzi', p.descrizione
from Composizione c, Prodotto p
where c.idProd = p.idProd
order by (pesoComplessivo) ASC;

# 14- TROVA PER OGNI ORDINE IL SUO COSTO:
 
select  ord.idOrd, pag.totale
from Ordine ord, Pagamento pag
where ord.idOrd=pag.ordine;

# 15- ELENCARE NOME E COGNOME DI TUTTI I CLIENTI IN CARATTERI MAIUSCOLI, IL CUI NOME TERMINA CON I E IL COGNOME INIZIA CON B:

select  upper(nome) as 'NOME', upper(cognome) 'COGNOME'
from Clienti
where cognome like'B%' or nome like '%i';

# 16- ELENCARE NOME E COGNOME DI TUTTI I CLIENTI CHE HANNO LA PRIMA CIFRA DEL CAP UGUALE A '5':

select nome, cognome, nAzienda 
from Clienti
where substring(cap, 1,1)='5';

# 17- ELENCA TUTTI GLI ARTICOLI VENDUTI DALLA SANIVEN ORDINANDOLI A SECONDA DEL LORO NUMERO DI PRODOTTO:

select descrizione 
from Prodotto
order by idProd;

# 18- PER OGNI CLIENTE SI VUOLE LA LUNGHEZZA TOTALE DEL SUO NOME E COGNOME:

select nome, cognome, (length(nome)+length(cognome)) as Lunghezzatotale
from Clienti
where nome  not in (select nome from Clienti where nome ='null');

# 19- PER OGNI ORDINE ELENCARE NUMERO DATA ORA E TOTALE PAGATO:

-- join naturale
select O.idOrd, T.dataOra, T.totale
from Ordine O natural join Pagamento T;

select * 
from Ordine;

select * 
from Pagamento;

-- oppure join esplicito
select O.idOrd, T.dataOra, T.totale
from Ordine O join Pagamento T on O.idOrd=T.Ordine;

-- join implicito
select O.idOrd, T.dataOra, T.totale
from Ordine O, Pagamento T
where O.idOrd=T.Ordine;

############################################################################
################          Procedure e funzioni             #################
############################################################################

### RITORNA IL PESO COMPLESSIVO, DATA UNA QUANTIÀ E UN PESO SPECIFICO:
DELIMITER $$
DROP FUNCTION IF EXISTS Saniven.calcolaPeso$$
CREATE FUNCTION Saniven.calcolaPeso(qta INT,peso DEC(10,2))
RETURNS DEC(10,2)
begin
    RETURN qta* peso;

end $$
DELIMITER ;
## PER VERIFICARE IL FUNZIONAMENTO:
# select Saniven.calcolaPeso(10,5.5) as 'Peso Complessivo';

### DATO UN IDENTIFICATIVO DI PAGAMENTO, RITORNA IL TOTALE PAGATO:
DELIMITER $$
DROP PROCEDURE IF EXISTS TotalePagato $$
CREATE PROCEDURE TotalePagato(p VARCHAR(6))
	SELECT totale
	FROM Pagamento
	WHERE idPay = p $$
DELIMITER ;

## PER VERIFICARE IL FUNZIONAMENTO:
#CALL TotalePagato('478456');

