-- TEST
CALL edifici_redditizi();
CALL costo_lavoro('wrk123F');
SELECT costo
FROM Lavoro
WHERE Codice='wrk123F';
CALL parti_monitorate('FI00123032022');
CALL parti_monitorate2('FI00123032022');
CALL aree_danneggiate();
CALL lavori_piu_in_ritardo();
CALL MaterialiMigliori();
SELECT * FROM Realizzazione;
CALL sposta_lavoratore('wrk123F',CURRENT_DATE,1);
SELECT * FROM Realizzazione;

CALL inserisci_sensore('gr352','co1010no22','no34343434',100,100);
SELECT * FROM Sensore;

SELECT * FROM Vano WHERE Codice='co1010no22';
DELETE 
FROM Sensore
WHERE Codice='gr352';

