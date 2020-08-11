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

load data local infile '/home/dispater/Downloads/SanivenSQL/clienti.csv' into table Clienti
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

load data local infile '/home/dispater/Downloads/SanivenSQL/Pagamento.in' into table Pagamento
fields terminated by ';'
optionally enclosed by '-'
optionally enclosed by ':'
lines terminated by '\n'
starting by '*'
ignore 4 lines
(fattura,idPay,tipo,ordine,totale,dataOra);

load data local infile '/home/dispater/Downloads/SanivenSQL/Composizione.in' into table Composizione
fields terminated by '$'
lines terminated by '$'
starting by ';'
ignore 5 lines
(idOrd,idProd,qta);

#############################################################################
################  Ulteriori vncoli tramite viste e/o trigger ################
#############################################################################

# TROVA NUMERO DI CONSEGNE EFFETUATE DEI DRONI :
create view consegneDroni(numeroConsegne) as
select count(*)
from Ordine ord 
where ord.stato='consegnato' and vettore='dr%';

# VISUALIZZA NOME COGNOME DEGLI UTENTI PRIVATI
create view Utenti as
select concat(c.nome,' ',c.cognome) as utenti , c.tipo
from Clienti c
where c.tipo = 'privato';

# VISUALIZZA I NOMINATIVI DELLE AZIENDE
create view Aziende as
select nAzienda as nomeAzienda, tipo
from Clienti 
where tipo = 'Azienda';

# VISUALIZZA IL COSTO DELLE L'ORDINAZIONI DEGLI UTENTI PRIVATI
create view spesaPrivati as 
select c.nome as utente , ord.idOrd as 'numero Ordine', pag.totale
from Ordine ord, Pagamento pag, Clienti c
where ord.idOrd=pag.ordine and ord.destinatario = c.idC and c.tipo = 'privato';

## QUESTO TRIGGER INVERTE LA MAIL AZIENDALE, PEC@ART DIVENTA @ARTPEC

DELIMITER $$

CREATE TRIGGER InvertLegalMail
BEFORE INSERT ON Saniven.Clienti
	FOR EACH ROW
		IF left(NEW.email,3)='pec' THEN SET NEW.email= CONCAT( substring(new.email,4,7),'pec' );
		END IF $$
		
DELIMITER ;

# per verificare il funzionamento:

insert into Clienti values
('GBAB',null,null,'InvertMail','pec@art','azienda',null,77777,'Sebino',4,'Prato','PO','59100');
select * from Clienti;

 
##QUESTO TRIGGER CONTROLLA CHE IL CODICE DI UN NUOVO CORRIERE CORRISPONDA ALLO STANDARD AZIENDALE

DELIMITER $$

CREATE TRIGGER checkCorriere
BEFORE INSERT ON Saniven.Vettore
FOR EACH ROW
    IF left(new.vettore,3)='crr' then 
		signal sqlstate '45000' SET message_text=' non è un corriere'        
	END IF;

DELIMITER ; 

# per verificare il funzionamento:

insert into Vettore values ('aaa11','corriere',9.00);
select * from Vettore;
delete from Vettore where Vettore.idVettore = 'aaa11';

## QUESTO TRIGGER CONTROLLA CHE IL CODICE DI UN NUOVO DRONE CORRISPONDA ALLO STANDARD AZIENDALE
 
DELIMITER $$

CREATE TRIGGER checkDrone
BEFORE INSERT ON Saniven.Vettore
for each row
begin
    if(substring(new.idVettore,2)!='dr') then
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'questo non è un drone aziendale';
    end if;
    
 end;

# per verificare il funzionamento:

insert into Vettore values ('aaa11','drone',9.00);
select * from Vettore;
delete from Vettore where Vettore.idVettore = 'aaa11';
 
 
 
############################################################################
################ 				 Interrogazioni   		   #################
############################################################################

# Possibilmente di vario tipo:  selezioni, proiezioni, join, con raggruppamento, 
# annidate, con funzioni per il controllo del flusso.

# 1- Quanti clienti si sono serviti di Saniven:
select count(idC) as Utenti
from Clienti;

# 2- Quanti privati:
select count(idC) as UtentiPrivati
from Clienti
where tipo ="privato";

# 3- Quante aziende di Firenze si sono servite di Saniven:
select count(idC) as AziendeFiorentine
from Clienti 
where tipo ="azienda" AND città="Firenze";

# 4- Quanti membri di una stessa famiglia abitano a FIRENZE hanno ordinato DPI:
select  count(c1.idC) as famigliari
from Clienti c1, Clienti c2
where c1.città = 'Firenze' and c1.cognome=c2.cognome and c1.nome <> c2.nome;

# 5- visualizzare codiceCliente, nomi completi degli utenti registrati ordina per cognome:
select c1.idC as codiceCliente, concat(c1.nome,' ',c1.cognome) as nomeCompleto
from Clienti c1, Clienti c2
where c1.cognome=c2.cognome and c1.nome <> c2.nome
order by c1.cognome;

# 6- trova i codici degli ordini che sono stati spediti e codice dei vettori che li trasportano:
select ord.idOrd, ord.vettore
from Ordine ord
where stato ='spedito';

# 7- trova la distanza media percorsa da parte dei droni aziendali:
select AVG(distMax) as distanzaMedia
from Vettore
where tipo = 'drone';

# 8- trova nome e codice dei clienti che hanno qualche ordine in preparazione:
select idC, nome, cognome, nAzienda as Azienda
from Clienti
where idC in ( select destinatario from Ordine where stato='preparazione');

# 9- trova per ogni azienda tutti gli ordini che hanno richiesto: visualizza numero dell'ordine, nome dell'azienda e lo stato dell'ordinazione:
select distinct Ordine.idOrd, Clienti.nAzienda as nomeAzienda, Ordine.stato
from Ordine, Clienti
where destinatario in ( select idC from Clienti where tipo ='azienda') and Clienti.tipo='Azienda';

# 10- trova quanti sono gli ordini "preparazione", "spediti", " consegnati" :
select stato,count(*) as 'ordiniInCorso'
from Ordine
group by stato
order by stato;

# 11- conta quanti prodotti vende l'azienda "SANIVEN":
select count(*) as 'prodotti in vendita'
from Prodotto;

# 12- trova codice e descrizione del prodotto più pesante
select idProd, descrizione
from Prodotto
where pesoSpec = ( select max(pesoSpec) as 'Oggetto-Pesante' from Prodotto );

# 13- trova per ogni composizione il peso complessivo e organizzali in maniera crescente
select c.idOrd, (c.qta*pesoSpec) as 'pesoComplessivo', c.qta as 'numero pezzi', p.descrizione
from Composizione c, Prodotto p
where c.idProd = p.idProd
order by (pesoComplessivo) ASC;

# 14- trova per ogni ordine il suo costo 
select  ord.idOrd, pag.totale
from Ordine ord, Pagamento pag
where ord.idOrd=pag.ordine;

# 15- elencare nome e cognome di tutti i clienti in caratteri maiuscoli, il cui nome termina con i e il cognome inizia con b.
select  upper(nome) as 'NOME', upper(cognome) 'COGNOME'
from Clienti
where cognome like'B%' or nome like '%i';

# 16- elencare nome e cognome di tutti i clienti che hanno la prima cifra del cap uguale a '5'.
select nome, cognome, nAzienda 
from Clienti
where substring(cap, 1,1)='5';

# 17-  elenca tutti gli articoli venduti dalla Saniven ordinandoli a seconda del loro numero di prodotto
select descrizione 
from Prodotto
order by idProd;

# 18- per ogni cliente si vuole la lunghezza totale del suo nome e cognome.
select nome, cognome, (length(nome)+length(cognome)) as Lunghezzatotale
from Clienti
where nome  not in (select nome from Clienti where nome ='null');

# 19- per ogni ordine elencare numero data ora e totale pagato.
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

#
DELIMITER $$
DROP PROCEDURE IF EXISTS TipoPagamento $$
CREATE PROCEDURE TotalePagato(p VARCHAR(6))
	SELECT totale
	FROM Pagamento
	WHERE idPay = p $$
DELIMITER ;

CALL TotalePagato('478456');

# 
DELIMITER $$
DROP FUNCTION IF EXISTS Saniven.calcolaPeso$$
CREATE FUNCTION Saniven.calcolaPeso(qta INT,peso DEC(10,2))
RETURNS DEC(10,2)
begin
    RETURN qta* peso;

end $$
DELIMITER ;

select Saniven.calcolaPeso(10,5.5) as 'Peso Complessivo';











