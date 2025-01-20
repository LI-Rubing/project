/*les requêtes SQL de la partie réseau :

Requête SQL pour la vérification de la carte vitale :*/

SELECT 1
FROM Patient p
JOIN Personne pers ON p.id_personne = pers.id_personne
WHERE p.num_secu = ? AND pers.nom = ? AND pers.prenom = ?
AND p.date_validite_carte_vitale = ?


/*Requête SQL pour la récupération des informations de l'ordonnance active */

SELECT o.id_ordonnance, o.date_ordonnance, o.date_expiration,
   	m.nom, m.forme, lo.quantite, lo.posologie
FROM Ordonnance o
JOIN Ligne_Ordonnance lo ON o.id_ordonnance = lo.id_ordonnance
JOIN medicament m ON lo.id_medicaments = m.id_medicaments
JOIN Patient p ON o.num_secu = p.num_secu
WHERE p.num_secu = ? AND o.status = 'ACTIVE'
AND o.date_expiration >= CURRENT_DATE




/*Requête SQL pour la mise à jour des stocks de médicaments*/

-- Mettre à jour la quantité d'un médicament par son nom
UPDATE stock_medicament sm
SET quantite = sm.quantite - ?
WHERE id_medicaments = (
	SELECT id_medicaments
	FROM medicament
	WHERE nom = ?  
)
AND sm.quantite >= ?;


/*Requête SQL pour mettre à jour la date de mise à jour du stock*/

-- Mettre à jour la date de mise à jour du stock
UPDATE stock
SET date_mise_a_jour = NOW() 
WHERE id_stock IN (
	SELECT id_stock
	FROM stock_medicament
	WHERE id_medicaments = (
    	SELECT id_medicaments
    	FROM medicament
    	WHERE nom = ?  
	)
);

/*les requêtes SQL de la partie Web :*/
/*Requêtes SQL pour gérer les patients :
Insertion dans la table Personne :*/

INSERT INTO Personne (prenom, nom, date_de_naissance, adresse) 
VALUES (:firstName, :lastName, :dateOfBirth, :address) 
RETURNING id_personne;
/*Insertion dans la table Patient :*/

INSERT INTO Patient (num_secu, assure, id_personne, date_validite_carte_vitale, regime_secu)
VALUES (:socialSecNum, :insured, :personId, :cardExpirationDate, :socialSecRegime);

/*Requêtes SQL pour gérer les médicaments :
Insertion dans la table Medicament :*/

INSERT INTO medicament (nom, descrip, principe_actif, prix, remboursable, famille_therapeutique, forme, code_cip, taux_remboursement)
VALUES (:medName, :description, :activePrinciple, :price, :reimbursable, :therapeuticFamily, :form, :cipCode, :reimbursementRate);

/*Requêtes SQL pour les alertes :
Récupérer les médicaments avec un stock faible ou expiré :*/

SELECT s.id_medicaments, m.nom, s.quantite, s.date_peremption
FROM stock_medicament s
JOIN medicament m ON s.id_medicaments = m.id_medicaments
WHERE s.quantite <= 10 OR s.date_peremption < CURRENT_DATE;

/*Utilisée pour récupérer un utilisateur dans la table pharmacien*/

SELECT login, mdp FROM pharmacien WHERE login = :login

/* Sélectionner un patient pour édition*/

SELECT p.num_secu, pr.prenom, pr.nom, pr.date_de_naissance, pr.adresse, p.date_validite_carte_vitale 
FROM patient p 
JOIN personne pr ON p.id_personne = pr.id_personne 
WHERE p.num_secu = ?
/*Mettre à jour les informations d'une personne*/
UPDATE Personne 
SET prenom = ?, nom = ?, adresse = ? 
WHERE id_personne = (
    SELECT id_personne FROM Patient WHERE num_secu = ?
)

/* Mettre à jour les informations d'un patient*/

UPDATE Patient 
SET date_validite_carte_vitale = ? 
WHERE num_secu = ?

/*Supprimer un patient*/

DELETE FROM patient WHERE num_secu = ?

/* Supprimer une personne associée à un patient*/

DELETE FROM personne WHERE id_personne = ?

/*Afficher tous les patients*/

SELECT p.num_secu, pr.prenom, pr.nom, pr.date_de_naissance, pr.adresse, p.date_validite_carte_vitale
FROM patient p
JOIN personne pr ON p.id_personne = pr.id_personne

/*Afficher tous les médicaments*/
SELECT id_medicaments, nom, descrip, principe_actif, prix, remboursable, famille_therapeutique, forme, code_cip, taux_remboursement
FROM medicament

/*Afficher un médicament spécifique (avec ID)*/

SELECT id_medicaments, nom, descrip, principe_actif, prix, remboursable, famille_therapeutique, forme, code_cip, taux_remboursement
FROM medicament
WHERE id_medicaments = :id

/*Mettre à jour un médicament*/

UPDATE medicament 
SET prix = ?, taux_remboursement = ? 
WHERE id_medicaments = ?

/*Supprimer un médicament*/

DELETE FROM medicament WHERE id_medicaments = ?

/*Filtrer par famille thérapeutique*/
SELECT famille_therapeutique, COUNT(*) AS total, 
       STRING_AGG(nom, ', ') AS noms_medicaments
FROM medicament
GROUP BY famille_therapeutique
ORDER BY famille_therapeutique