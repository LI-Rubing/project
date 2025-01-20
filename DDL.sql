-- Création des séquences pour les ID auto-incrémentés
CREATE SEQUENCE personne_seq;
CREATE SEQUENCE pharmacien_seq;
CREATE SEQUENCE laboratoire_seq;
CREATE SEQUENCE medicament_seq;
CREATE SEQUENCE stock_seq;
CREATE SEQUENCE ordonnance_seq;
CREATE SEQUENCE ligne_ordonnance_seq;
CREATE SEQUENCE commande_seq;

-- Table Personne
CREATE TABLE Personne (
    id_personne INTEGER PRIMARY KEY DEFAULT nextval('personne_seq'),
    prenom VARCHAR(50) NOT NULL,
    nom VARCHAR(50) NOT NULL,
    date_de_naissance DATE,
    adresse TEXT
);

-- Table Pharmacien
CREATE TABLE Pharmacien (
    id_pharmacien INTEGER PRIMARY KEY DEFAULT nextval('pharmacien_seq'),
    mdp VARCHAR(255) NOT NULL,
    id_personne INTEGER REFERENCES Personne(id_personne)
);

-- Table Patient
CREATE TABLE Patient (
    num_secu VARCHAR(15) PRIMARY KEY,
    assure BOOLEAN DEFAULT TRUE,
    mdp VARCHAR(255),
    id_pharmacien INTEGER REFERENCES Pharmacien(id_pharmacien),
    id_personne INTEGER REFERENCES Personne(id_personne),
    date_validite_carte_vitale DATE,
    regime_secu VARCHAR(50)
);

-- Table Laboratoire
CREATE TABLE Laboratoire (
    id_laboratoire INTEGER PRIMARY KEY DEFAULT nextval('laboratoire_seq'),
    nom VARCHAR(100) NOT NULL,
    ville_labo VARCHAR(100),
    adresse_labo TEXT,
    telephone_labo VARCHAR(15),
    email VARCHAR(100)
);

-- Table Medicament
CREATE TABLE Medicament (
    id_medicaments INTEGER PRIMARY KEY DEFAULT nextval('medicament_seq'),
    nom VARCHAR(100) NOT NULL,
    description TEXT,
    principe_actif VARCHAR(100),
    prix DECIMAL(10,2),
    remboursable BOOLEAN,
    famille_therapeutique VARCHAR(100),
    forme VARCHAR(50),
    id_laboratoire INTEGER REFERENCES Laboratoire(id_laboratoire),
    code_cip VARCHAR(13) UNIQUE,
    taux_remboursement INTEGER
);

-- Table Stock
CREATE TABLE Stock (
    id_stock INTEGER PRIMARY KEY DEFAULT nextval('stock_seq'),
    date_mise_a_jour TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_pharmacien INTEGER REFERENCES Pharmacien(id_pharmacien)
);

-- Table Stock_Medicament
CREATE TABLE Stock_Medicament (
    id_stock INTEGER REFERENCES Stock(id_stock),
    id_medicaments INTEGER REFERENCES Medicament(id_medicaments),
    quantite INTEGER NOT NULL DEFAULT 0,
    seuil_alerte INTEGER,
    date_peremption DATE,
    PRIMARY KEY (id_stock, id_medicaments)
);

-- Table Ordonnance
CREATE TABLE Ordonnance (
    id_ordonnance INTEGER PRIMARY KEY DEFAULT nextval('ordonnance_seq'),
    date_ordonnance DATE NOT NULL,
    date_expiration DATE,
    id_pharmacien INTEGER REFERENCES Pharmacien(id_pharmacien),
    num_secu VARCHAR(15) REFERENCES Patient(num_secu),
    status VARCHAR(20) DEFAULT 'ACTIVE',
    CHECK (status IN ('ACTIVE', 'EXPIREE', 'UTILISEE'))
);

-- Table Ligne_Ordonnance
CREATE TABLE Ligne_Ordonnance (
    id_ligne_ordonnance INTEGER PRIMARY KEY DEFAULT nextval('ligne_ordonnance_seq'),
    id_ordonnance INTEGER REFERENCES Ordonnance(id_ordonnance),
    id_medicaments INTEGER REFERENCES Medicament(id_medicaments),
    quantite INTEGER NOT NULL,
    posologie TEXT,
    duree_traitement INTEGER,
    instructions TEXT
);

-- Table Commande
CREATE TABLE Commande (
    id_commande INTEGER PRIMARY KEY DEFAULT nextval('commande_seq'),
    date_commande TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    id_pharmacien INTEGER REFERENCES Pharmacien(id_pharmacien),
    status VARCHAR(20) DEFAULT 'EN_COURS',
    CHECK (status IN ('EN_COURS', 'VALIDEE', 'LIVREE', 'ANNULEE'))
);

-- Table Ligne_Commande
CREATE TABLE Ligne_Commande (
    id_commande INTEGER REFERENCES Commande(id_commande),
    id_medicaments INTEGER REFERENCES Medicament(id_medicaments),
    quantite INTEGER NOT NULL,
    prix_unitaire DECIMAL(10,2),
    PRIMARY KEY (id_commande, id_medicaments)
);

-- Création des index pour optimiser les recherches
CREATE INDEX idx_patient_num_secu ON Patient(num_secu);
CREATE INDEX idx_medicament_code_cip ON Medicament(code_cip);
CREATE INDEX idx_ordonnance_date ON Ordonnance(date_ordonnance);
CREATE INDEX idx_ordonnance_status ON Ordonnance(status);
CREATE INDEX idx_stock_date ON Stock(date_mise_a_jour);

-- Création des triggers pour la mise à jour automatique des dates
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_mise_a_jour = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_stock_timestamp
    BEFORE UPDATE ON Stock
    FOR EACH ROW
    EXECUTE PROCEDURE update_timestamp();

-- Fonction pour vérifier le stock
CREATE OR REPLACE FUNCTION verifier_stock_disponible()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quantite < NEW.seuil_alerte THEN
        RAISE NOTICE 'Stock bas pour le médicament %', NEW.id_medicaments;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER check_stock_level
    AFTER INSERT OR UPDATE ON Stock_Medicament
    FOR EACH ROW
    EXECUTE PROCEDURE verifier_stock_disponible();
    
 -- ____insertion:__________
 --Insertion dans la table Personne :

 INSERT INTO Personne (prenom, nom, date_de_naissance, adresse) VALUES
('Jean', 'Dupont', '1980-05-15', '123 Rue de Paris, 75001 Paris'),
('Marie', 'Martin', '1975-08-22', '456 Avenue Victor Hugo, 75016 Paris'),
('Pierre', 'Dubois', '1990-03-10', '789 Boulevard Voltaire, 75011 Paris'),
('Sophie', 'Lefebvre', '1985-12-05', '321 Rue du Commerce, 75015 Paris'),
('Lucas', 'Bernard', '1995-07-20', '654 Avenue Mozart, 75016 Paris'),
('Emma', 'Petit', '1988-09-30', '147 Rue de la Paix, 75002 Paris');

--Insertion dans la table Pharmacien :

INSERT INTO Pharmacien (mdp, id_personne) VALUES
('hash123', 1),  -- Jean Dupont
('hash456', 2);  -- Marie Martin

--Insertion dans la table Patient :
INSERT INTO Patient (num_secu, assure, mdp, id_pharmacien, id_personne, date_validite_carte_vitale, regime_secu) VALUES
('196123456789123', true, 'hash789', 1, 3, '2024-12-31', 'Général'),
('285123456789456', true, 'hash101', 1, 4, '2024-12-31', 'Général'),
('195123456789789', true, 'hash102', 2, 5, '2024-12-31', 'Agricole'),
('198123456789012', true, 'hash103', 2, 6, '2024-12-31', 'Général');

--Insertion dans la table Laboratoire :

INSERT INTO Laboratoire (nom, ville_labo, adresse_labo, telephone_labo, email) VALUES
('Sanofi', 'Paris', '54 Rue La Boétie, 75008 Paris', '0123456789', 'contact@sanofi.fr'),
('Pfizer', 'Lyon', '23 Avenue du Docteur Lannelongue', '0234567890', 'contact@pfizer.fr'),
('Novartis', 'Marseille', '2 Boulevard Victor', '0345678901', 'contact@novartis.fr'),
('Bayer', 'Lille', '10 Rue de l''Innovation', '0456789012', 'contact@bayer.fr');

--Insertion dans la table Medicament :

INSERT INTO Medicament (nom, description, principe_actif, prix, remboursable, famille_therapeutique, forme, id_laboratoire, code_cip, taux_remboursement) VALUES
('Doliprane', 'Antalgique et antipyrétique', 'Paracétamol', 2.50, true, 'Antalgique', 'comprimé', 1, 'CIP123456', 65),
('Ibuprofène', 'Anti-inflammatoire', 'Ibuprofène', 3.50, true, 'AINS', 'gélule', 2, 'CIP234567', 65),
('Amoxicilline', 'Antibiotique', 'Amoxicilline', 5.90, true, 'Antibiotique', 'comprimé', 3, 'CIP345678', 65),
('Ventoline', 'Bronchodilatateur', 'Salbutamol', 4.80, true, 'Antiasthmatique', 'spray', 1, 'CIP456789', 65),
('Spasfon', 'Antispasmodique', 'Phloroglucinol', 3.90, true, 'Antispasmodique', 'comprimé', 2, 'CIP567890', 30);

--Insertion dans la table Stock :

INSERT INTO Stock (id_pharmacien) VALUES
(1),
(2);

--Insertion dans la table Stock_Medicament :

INSERT INTO Stock_Medicament (id_stock, id_medicaments, quantite, seuil_alerte, date_peremption) VALUES
(1, 1, 100, 20, '2024-12-31'),
(1, 2, 75, 15, '2024-12-31'),
(1, 3, 50, 10, '2024-12-31'),
(2, 4, 30, 10, '2024-12-31'),
(2, 5, 60, 15, '2024-12-31');

--Insertion dans la table Ordonnance :

INSERT INTO Ordonnance (date_ordonnance, date_expiration, id_pharmacien, num_secu, status) VALUES
('2023-11-01', '2024-02-01', 1, '196123456789123', 'ACTIVE'),
('2023-11-05', '2024-02-05', 1, '285123456789456', 'ACTIVE'),
('2023-10-15', '2024-01-15', 2, '195123456789789', 'ACTIVE'),
('2023-09-01', '2023-12-01', 2, '198123456789012', 'EXPIREE');

--Insertion dans la table Ligne_Ordonnance :

INSERT INTO Ligne_Ordonnance (id_ordonnance, id_medicaments, quantite, posologie, duree_traitement, instructions) VALUES
(1, 1, 2, '1 comprimé matin et soir', 7, 'À prendre pendant les repas'),
(1, 2, 1, '1 gélule si douleur', 5, 'À prendre en cas de douleur'),
(2, 3, 1, '1 comprimé 3 fois par jour', 10, 'À prendre à heure fixe'),
(3, 4, 1, '2 bouffées en cas de crise', 30, 'En cas de crise d''asthme'),
(3, 5, 2, '1 comprimé avant les repas', 15, 'À prendre avant les repas');

--Insertion dans la table Commande :

INSERT INTO Commande (id_pharmacien, status) VALUES
(1, 'EN_COURS'),
(1, 'VALIDEE'),
(2, 'LIVREE');

--Insertion dans la table Ligne_Commande :

INSERT INTO Ligne_Commande (id_commande, id_medicaments, quantite, prix_unitaire) VALUES
(1, 1, 50, 2.50),
(1, 2, 30, 3.50),
(2, 3, 20, 5.90),
(3, 4, 15, 4.80),
(3, 5, 25, 3.90);





