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
