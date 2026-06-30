/*
    Projet : Palimpseste
    Cours  : Gestion et exploitation de bases de données
    Script : Base de donnees.sql
    SGBD   : MariaDB

    Script complet : création de la base, tables, contraintes,
    données de référence, triggers, procédures et jeu de données initial.
*/

DROP DATABASE IF EXISTS palimpseste;
CREATE DATABASE palimpseste CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE palimpseste;
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
/* ============================================================
   1. Tables de référence
   ============================================================ */

CREATE TABLE type_fragment (
    id_type_fragment INT AUTO_INCREMENT,
    libelle VARCHAR(100) NOT NULL,
    CONSTRAINT pk_type_fragment PRIMARY KEY (id_type_fragment),
    CONSTRAINT uq_type_fragment_libelle UNIQUE (libelle)
) ENGINE=InnoDB;

CREATE TABLE auteur (
    id_auteur INT AUTO_INCREMENT,
    nom VARCHAR(150) NOT NULL,
    prenom VARCHAR(150),
    description TEXT,
    CONSTRAINT pk_auteur PRIMARY KEY (id_auteur)
) ENGINE=InnoDB;

CREATE TABLE humeur (
    id_humeur INT AUTO_INCREMENT,
    libelle VARCHAR(100) NOT NULL,
    CONSTRAINT pk_humeur PRIMARY KEY (id_humeur),
    CONSTRAINT uq_humeur_libelle UNIQUE (libelle)
) ENGINE=InnoDB;

CREATE TABLE mode_archivage (
    id_mode_archivage INT AUTO_INCREMENT,
    libelle VARCHAR(100) NOT NULL,
    CONSTRAINT pk_mode_archivage PRIMARY KEY (id_mode_archivage),
    CONSTRAINT uq_mode_archivage_libelle UNIQUE (libelle)
) ENGINE=InnoDB;

CREATE TABLE theme (
    id_theme INT AUTO_INCREMENT,
    libelle VARCHAR(100) NOT NULL,
    CONSTRAINT pk_theme PRIMARY KEY (id_theme),
    CONSTRAINT uq_theme_libelle UNIQUE (libelle)
) ENGINE=InnoDB;

CREATE TABLE mot_cle (
    id_mot_cle INT AUTO_INCREMENT,
    libelle VARCHAR(100) NOT NULL,
    CONSTRAINT pk_mot_cle PRIMARY KEY (id_mot_cle),
    CONSTRAINT uq_mot_cle_libelle UNIQUE (libelle)
) ENGINE=InnoDB;

/* ============================================================
   2. Tables principales
   ============================================================ */

CREATE TABLE utilisateur (
    id_utilisateur INT AUTO_INCREMENT,
    pseudo VARCHAR(80) NOT NULL,
    email VARCHAR(255) NOT NULL,
    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actif BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_utilisateur PRIMARY KEY (id_utilisateur),
    CONSTRAINT uq_utilisateur_pseudo UNIQUE (pseudo),
    CONSTRAINT uq_utilisateur_email UNIQUE (email)
) ENGINE=InnoDB;

CREATE TABLE fragment (
    id_fragment INT AUTO_INCREMENT,
    id_createur INT NOT NULL,
    id_type_fragment INT NOT NULL,
    id_auteur INT,
    texte TEXT NOT NULL,
    source_titre VARCHAR(255),
    source_url VARCHAR(500),
    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    visibilite ENUM('PRIVE', 'PARTAGE', 'PUBLIC') NOT NULL DEFAULT 'PRIVE',
    supprime_logiquement BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_fragment PRIMARY KEY (id_fragment),
    CONSTRAINT fk_fragment_createur FOREIGN KEY (id_createur) REFERENCES utilisateur(id_utilisateur) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_fragment_type FOREIGN KEY (id_type_fragment) REFERENCES type_fragment(id_type_fragment) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_fragment_auteur FOREIGN KEY (id_auteur) REFERENCES auteur(id_auteur) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_fragment_texte_non_vide CHECK (CHAR_LENGTH(TRIM(texte)) > 0)
) ENGINE=InnoDB;

CREATE TABLE collection_fragment (
    id_collection_fragment INT AUTO_INCREMENT,
    id_utilisateur INT NOT NULL,
    id_fragment INT NOT NULL,
    id_humeur INT,
    id_mode_archivage INT,
    commentaire_personnel TEXT,
    favori BOOLEAN NOT NULL DEFAULT FALSE,
    archive BOOLEAN NOT NULL DEFAULT FALSE,
    date_ajout DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_collection_fragment PRIMARY KEY (id_collection_fragment),
    CONSTRAINT fk_collection_fragment_utilisateur FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_collection_fragment_fragment FOREIGN KEY (id_fragment) REFERENCES fragment(id_fragment) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_collection_fragment_humeur FOREIGN KEY (id_humeur) REFERENCES humeur(id_humeur) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_collection_fragment_mode_archivage FOREIGN KEY (id_mode_archivage) REFERENCES mode_archivage(id_mode_archivage) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT uq_collection_utilisateur_fragment UNIQUE (id_utilisateur, id_fragment)
) ENGINE=InnoDB;

CREATE TABLE collection_theme (
    id_collection_fragment INT NOT NULL,
    id_theme INT NOT NULL,
    CONSTRAINT pk_collection_theme PRIMARY KEY (id_collection_fragment, id_theme),
    CONSTRAINT fk_collection_theme_collection FOREIGN KEY (id_collection_fragment) REFERENCES collection_fragment(id_collection_fragment) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_collection_theme_theme FOREIGN KEY (id_theme) REFERENCES theme(id_theme) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE collection_mot_cle (
    id_collection_fragment INT NOT NULL,
    id_mot_cle INT NOT NULL,
    CONSTRAINT pk_collection_mot_cle PRIMARY KEY (id_collection_fragment, id_mot_cle),
    CONSTRAINT fk_collection_mot_cle_collection FOREIGN KEY (id_collection_fragment) REFERENCES collection_fragment(id_collection_fragment) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_collection_mot_cle_mot_cle FOREIGN KEY (id_mot_cle) REFERENCES mot_cle(id_mot_cle) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ============================================================
   3. Groupes, demandes et avis
   ============================================================ */

CREATE TABLE groupe_utilisateur (
    id_groupe INT AUTO_INCREMENT,
    id_createur INT NOT NULL,
    nom VARCHAR(150) NOT NULL,
    description TEXT,
    date_creation DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_groupe_utilisateur PRIMARY KEY (id_groupe),
    CONSTRAINT fk_groupe_createur FOREIGN KEY (id_createur) REFERENCES utilisateur(id_utilisateur) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE membre_groupe (
    id_groupe INT NOT NULL,
    id_utilisateur INT NOT NULL,
    role_groupe ENUM('CREATEUR', 'ADMIN', 'MEMBRE') NOT NULL DEFAULT 'MEMBRE',
    date_adhesion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_membre_groupe PRIMARY KEY (id_groupe, id_utilisateur),
    CONSTRAINT fk_membre_groupe_groupe FOREIGN KEY (id_groupe) REFERENCES groupe_utilisateur(id_groupe) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_membre_groupe_utilisateur FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE demande_avis (
    id_demande INT AUTO_INCREMENT,
    id_fragment INT NOT NULL,
    id_demandeur INT NOT NULL,
    id_utilisateur_cible INT,
    id_groupe_cible INT,
    message_demande TEXT,
    date_demande DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    statut ENUM('EN_ATTENTE', 'EN_COURS', 'TRAITEE', 'ANNULEE') NOT NULL DEFAULT 'EN_ATTENTE',
    CONSTRAINT pk_demande_avis PRIMARY KEY (id_demande),
    CONSTRAINT fk_demande_avis_fragment FOREIGN KEY (id_fragment) REFERENCES fragment(id_fragment) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_demande_avis_demandeur FOREIGN KEY (id_demandeur) REFERENCES utilisateur(id_utilisateur) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_demande_avis_utilisateur_cible FOREIGN KEY (id_utilisateur_cible) REFERENCES utilisateur(id_utilisateur) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_demande_avis_groupe_cible FOREIGN KEY (id_groupe_cible) REFERENCES groupe_utilisateur(id_groupe) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT chk_demande_avis_cible_unique CHECK ((id_utilisateur_cible IS NOT NULL AND id_groupe_cible IS NULL) OR (id_utilisateur_cible IS NULL AND id_groupe_cible IS NOT NULL))
) ENGINE=InnoDB;

CREATE TABLE destinataire_demande_avis (
    id_demande INT NOT NULL,
    id_utilisateur INT NOT NULL,
    statut_reponse ENUM('EN_ATTENTE', 'REPONDU', 'IGNORE') NOT NULL DEFAULT 'EN_ATTENTE',
    date_notification DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_destinataire_demande_avis PRIMARY KEY (id_demande, id_utilisateur),
    CONSTRAINT fk_destinataire_demande_demande FOREIGN KEY (id_demande) REFERENCES demande_avis(id_demande) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_destinataire_demande_utilisateur FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE avis_fragment (
    id_avis INT AUTO_INCREMENT,
    id_demande INT NOT NULL,
    id_fragment INT NOT NULL,
    id_utilisateur INT NOT NULL,
    type_avis ENUM('PERTINENT','A_REVOIR','DOUBLON','MAL_CLASSE','INTERESSANT','HORS_SUJET') NOT NULL,
    note TINYINT NOT NULL,
    commentaire TEXT,
    date_avis DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_avis_fragment PRIMARY KEY (id_avis),
    CONSTRAINT fk_avis_fragment_demande FOREIGN KEY (id_demande) REFERENCES demande_avis(id_demande) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_avis_fragment_fragment FOREIGN KEY (id_fragment) REFERENCES fragment(id_fragment) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_avis_fragment_utilisateur FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_avis_note CHECK (note BETWEEN 1 AND 5),
    CONSTRAINT uq_avis_demande_utilisateur UNIQUE (id_demande, id_utilisateur)
) ENGINE=InnoDB;

/* ============================================================
   4. Suivi, historique, erreurs et bilans
   ============================================================ */

CREATE TABLE preference_reapparition (
    id_preference INT AUTO_INCREMENT,
    id_collection_fragment INT NOT NULL,
    score_preference INT NOT NULL DEFAULT 1,
    nombre_apparitions INT NOT NULL DEFAULT 0,
    date_derniere_apparition DATETIME,
    est_masque_accueil BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_preference_reapparition PRIMARY KEY (id_preference),
    CONSTRAINT fk_preference_collection FOREIGN KEY (id_collection_fragment) REFERENCES collection_fragment(id_collection_fragment) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT uq_preference_collection UNIQUE (id_collection_fragment),
    CONSTRAINT chk_preference_nombre_apparitions CHECK (nombre_apparitions >= 0)
) ENGINE=InnoDB;

CREATE TABLE interaction_fragment (
    id_interaction INT AUTO_INCREMENT,
    id_collection_fragment INT NOT NULL,
    type_interaction ENUM('APPARITION','PLUS_SOUVENT','MOINS_SOUVENT','MASQUER','FAVORI','OUVERTURE_DETAIL') NOT NULL,
    date_interaction DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_interaction_fragment PRIMARY KEY (id_interaction),
    CONSTRAINT fk_interaction_collection FOREIGN KEY (id_collection_fragment) REFERENCES collection_fragment(id_collection_fragment) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE mouvement_fragment (
    id_mouvement INT AUTO_INCREMENT,
    id_fragment INT NOT NULL,
    id_utilisateur INT NOT NULL,
    type_mouvement ENUM('CREATION','AJOUT_COLLECTION','MODIFICATION','ARCHIVAGE','DEMANDE_AVIS','AVIS_RECU','REAPPARITION','SUPPRESSION_LOGIQUE') NOT NULL,
    date_mouvement DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    commentaire TEXT,
    CONSTRAINT pk_mouvement_fragment PRIMARY KEY (id_mouvement),
    CONSTRAINT fk_mouvement_fragment_fragment FOREIGN KEY (id_fragment) REFERENCES fragment(id_fragment) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_mouvement_fragment_utilisateur FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE historique_fragment (
    id_historique INT AUTO_INCREMENT,
    id_fragment INT NOT NULL,
    id_utilisateur INT,
    action ENUM('INSERTION','MODIFICATION','SUPPRESSION_LOGIQUE') NOT NULL,
    ancien_texte TEXT,
    nouveau_texte TEXT,
    ancienne_visibilite ENUM('PRIVE', 'PARTAGE', 'PUBLIC'),
    nouvelle_visibilite ENUM('PRIVE', 'PARTAGE', 'PUBLIC'),
    date_action DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_historique_fragment PRIMARY KEY (id_historique),
    CONSTRAINT fk_historique_fragment_fragment FOREIGN KEY (id_fragment) REFERENCES fragment(id_fragment) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_historique_fragment_utilisateur FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE erreur_trigger (
    id_erreur INT AUTO_INCREMENT,
    nom_trigger VARCHAR(150) NOT NULL,
    table_concernee VARCHAR(150) NOT NULL,
    operation_declencheuse VARCHAR(50) NOT NULL,
    message_erreur TEXT NOT NULL,
    date_erreur DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_erreur_trigger PRIMARY KEY (id_erreur)
) ENGINE=InnoDB;

CREATE TABLE bilan_utilisateur (
    id_bilan INT AUTO_INCREMENT,
    id_utilisateur INT NOT NULL,
    nb_fragments_crees INT NOT NULL DEFAULT 0,
    nb_fragments_conserves INT NOT NULL DEFAULT 0,
    nb_favoris INT NOT NULL DEFAULT 0,
    nb_avis_donnes INT NOT NULL DEFAULT 0,
    nb_avis_recus INT NOT NULL DEFAULT 0,
    nb_demandes_avis INT NOT NULL DEFAULT 0,
    nb_reapparitions INT NOT NULL DEFAULT 0,
    date_bilan DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_bilan_utilisateur PRIMARY KEY (id_bilan),
    CONSTRAINT fk_bilan_utilisateur FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE bilan_groupe (
    id_bilan_groupe INT AUTO_INCREMENT,
    id_groupe INT NOT NULL,
    nb_membres INT NOT NULL DEFAULT 0,
    nb_demandes_avis INT NOT NULL DEFAULT 0,
    nb_avis_rendus INT NOT NULL DEFAULT 0,
    note_moyenne DECIMAL(4,2),
    date_bilan DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_bilan_groupe PRIMARY KEY (id_bilan_groupe),
    CONSTRAINT fk_bilan_groupe FOREIGN KEY (id_groupe) REFERENCES groupe_utilisateur(id_groupe) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_bilan_groupe_note CHECK (note_moyenne IS NULL OR note_moyenne BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE TABLE bilan_publication_utilisateur (
    id_bilan_publication INT AUTO_INCREMENT,
    id_utilisateur INT NOT NULL,
    nb_fragments_originaux INT NOT NULL DEFAULT 0,
    nb_conservations_par_autres INT NOT NULL DEFAULT 0,
    nb_avis_recus INT NOT NULL DEFAULT 0,
    note_moyenne DECIMAL(4,2),
    nb_reapparitions INT NOT NULL DEFAULT 0,
    date_bilan DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_bilan_publication_utilisateur PRIMARY KEY (id_bilan_publication),
    CONSTRAINT fk_bilan_publication_utilisateur FOREIGN KEY (id_utilisateur) REFERENCES utilisateur(id_utilisateur) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_bilan_publication_note CHECK (note_moyenne IS NULL OR note_moyenne BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE INDEX idx_fragment_createur ON fragment(id_createur);
CREATE INDEX idx_collection_utilisateur ON collection_fragment(id_utilisateur);
CREATE INDEX idx_collection_fragment ON collection_fragment(id_fragment);
CREATE INDEX idx_demande_statut ON demande_avis(statut);
CREATE INDEX idx_interaction_type ON interaction_fragment(type_interaction);
CREATE INDEX idx_mouvement_type ON mouvement_fragment(type_mouvement);

/* ============================================================
   5. Données de référence
   ============================================================ */

INSERT INTO type_fragment (libelle) VALUES ('Citation'),('Idée personnelle'),('Extrait web'),('Note de lecture'),('Pensée courte');

INSERT INTO auteur (nom, prenom, description) VALUES
('Héraclite', NULL, 'Philosophe présocratique associé à la pensée du devenir.'),
('Nietzsche', 'Friedrich', 'Philosophe allemand du XIXe siècle.'),
('Cioran', 'Emil', 'Essayiste et moraliste d’origine roumaine.'),
('Camus', 'Albert', 'Écrivain et philosophe français.'),
('Auteur inconnu', NULL, 'Auteur non identifié ou volontairement non renseigné.');

INSERT INTO humeur (libelle) VALUES ('Lucidité'),('Mélancolie'),('Ironie'),('Apaisement'),('Colère'),('Étonnement'),('Solitude'),('Discipline');

INSERT INTO mode_archivage (libelle) VALUES ('Indexé'),('Archive libre'),('À relire'),('En attente d’avis'),('Masqué de l’accueil');

INSERT INTO theme (libelle) VALUES ('Philosophie'),('Littérature'),('Cours'),('Politique'),('Technique'),('Spiritualité'),('Mémoire'),('Temps'),('Solitude'),('Discipline'),('Changement');

INSERT INTO mot_cle (libelle) VALUES ('temps'),('mort'),('discipline'),('solitude'),('mémoire'),('changement'),('devenir'),('lucidité'),('archive'),('citation'),('cours'),('fragment'),('réapparition'),('critique'),('partage');

/* ============================================================
   6. Triggers
   ============================================================ */

DELIMITER $$

CREATE TRIGGER trg_fragment_ai_creation
AFTER INSERT ON fragment
FOR EACH ROW
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO erreur_trigger (nom_trigger, table_concernee, operation_declencheuse, message_erreur)
        VALUES ('trg_fragment_ai_creation', 'fragment', 'AFTER INSERT', 'Erreur lors de la création du mouvement CREATION.');
    END;

    INSERT INTO mouvement_fragment (id_fragment, id_utilisateur, type_mouvement, date_mouvement, commentaire)
    VALUES (NEW.id_fragment, NEW.id_createur, 'CREATION', NEW.date_creation, 'Création du fragment.');
END $$

CREATE TRIGGER trg_collection_fragment_ai_preference_mouvement
AFTER INSERT ON collection_fragment
FOR EACH ROW
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO erreur_trigger (nom_trigger, table_concernee, operation_declencheuse, message_erreur)
        VALUES ('trg_collection_fragment_ai_preference_mouvement', 'collection_fragment', 'AFTER INSERT', 'Erreur lors de la création de la préférence ou du mouvement AJOUT_COLLECTION.');
    END;

    INSERT INTO preference_reapparition (id_collection_fragment, score_preference, nombre_apparitions, date_derniere_apparition, est_masque_accueil)
    VALUES (NEW.id_collection_fragment, 1, 0, NULL, FALSE);

    INSERT INTO mouvement_fragment (id_fragment, id_utilisateur, type_mouvement, date_mouvement, commentaire)
    VALUES (NEW.id_fragment, NEW.id_utilisateur, 'AJOUT_COLLECTION', NEW.date_ajout, 'Ajout du fragment à une collection.');
END $$

CREATE TRIGGER trg_interaction_fragment_ai_preference
AFTER INSERT ON interaction_fragment
FOR EACH ROW
BEGIN
    DECLARE v_id_fragment INT DEFAULT NULL;
    DECLARE v_id_utilisateur INT DEFAULT NULL;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO erreur_trigger (nom_trigger, table_concernee, operation_declencheuse, message_erreur)
        VALUES ('trg_interaction_fragment_ai_preference', 'interaction_fragment', 'AFTER INSERT', 'Erreur lors de la mise à jour des préférences.');
    END;

    IF NEW.type_interaction = 'APPARITION' THEN
        UPDATE preference_reapparition
        SET nombre_apparitions = nombre_apparitions + 1,
            date_derniere_apparition = NEW.date_interaction
        WHERE id_collection_fragment = NEW.id_collection_fragment;

        SELECT id_fragment, id_utilisateur
        INTO v_id_fragment, v_id_utilisateur
        FROM collection_fragment
        WHERE id_collection_fragment = NEW.id_collection_fragment;

        INSERT INTO mouvement_fragment (id_fragment, id_utilisateur, type_mouvement, date_mouvement, commentaire)
        VALUES (v_id_fragment, v_id_utilisateur, 'REAPPARITION', NEW.date_interaction, 'Réapparition du fragment à l’accueil.');

    ELSEIF NEW.type_interaction = 'PLUS_SOUVENT' THEN
        UPDATE preference_reapparition SET score_preference = score_preference + 1 WHERE id_collection_fragment = NEW.id_collection_fragment;
    ELSEIF NEW.type_interaction = 'MOINS_SOUVENT' THEN
        UPDATE preference_reapparition SET score_preference = score_preference - 1 WHERE id_collection_fragment = NEW.id_collection_fragment;
    ELSEIF NEW.type_interaction = 'MASQUER' THEN
        UPDATE preference_reapparition SET est_masque_accueil = TRUE WHERE id_collection_fragment = NEW.id_collection_fragment;
    ELSEIF NEW.type_interaction = 'FAVORI' THEN
        UPDATE preference_reapparition SET score_preference = score_preference + 2 WHERE id_collection_fragment = NEW.id_collection_fragment;
    END IF;
END $$

CREATE TRIGGER trg_demande_avis_ai_mouvement
AFTER INSERT ON demande_avis
FOR EACH ROW
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO erreur_trigger (nom_trigger, table_concernee, operation_declencheuse, message_erreur)
        VALUES ('trg_demande_avis_ai_mouvement', 'demande_avis', 'AFTER INSERT', 'Erreur lors de la création du mouvement DEMANDE_AVIS.');
    END;

    INSERT INTO mouvement_fragment (id_fragment, id_utilisateur, type_mouvement, date_mouvement, commentaire)
    VALUES (NEW.id_fragment, NEW.id_demandeur, 'DEMANDE_AVIS', NEW.date_demande, 'Demande d’avis créée.');
END $$

CREATE TRIGGER trg_avis_fragment_ai_suivi
AFTER INSERT ON avis_fragment
FOR EACH ROW
BEGIN
    DECLARE v_nb_attente INT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO erreur_trigger (nom_trigger, table_concernee, operation_declencheuse, message_erreur)
        VALUES ('trg_avis_fragment_ai_suivi', 'avis_fragment', 'AFTER INSERT', 'Erreur lors du suivi automatique après insertion d’un avis.');
    END;

    INSERT INTO mouvement_fragment (id_fragment, id_utilisateur, type_mouvement, date_mouvement, commentaire)
    VALUES (NEW.id_fragment, NEW.id_utilisateur, 'AVIS_RECU', NEW.date_avis, 'Avis reçu sur le fragment.');

    UPDATE destinataire_demande_avis
    SET statut_reponse = 'REPONDU'
    WHERE id_demande = NEW.id_demande
      AND id_utilisateur = NEW.id_utilisateur;

    SELECT COUNT(*) INTO v_nb_attente
    FROM destinataire_demande_avis
    WHERE id_demande = NEW.id_demande
      AND statut_reponse = 'EN_ATTENTE';

    IF v_nb_attente = 0 THEN
        UPDATE demande_avis SET statut = 'TRAITEE' WHERE id_demande = NEW.id_demande;
    ELSE
        UPDATE demande_avis SET statut = 'EN_COURS' WHERE id_demande = NEW.id_demande;
    END IF;
END $$

/* ============================================================
   7. Procédures stockées
   ============================================================ */

CREATE PROCEDURE compter_fragments_conserves (IN p_id_utilisateur INT, OUT p_total INT)
BEGIN
    SELECT COUNT(*) INTO p_total
    FROM collection_fragment
    WHERE id_utilisateur = p_id_utilisateur;
END $$

CREATE PROCEDURE modifier_fragment (
    IN p_id_fragment INT,
    IN p_id_utilisateur INT,
    IN p_nouveau_texte TEXT,
    IN p_nouvelle_visibilite VARCHAR(20)
)
BEGIN
    DECLARE v_id_createur INT DEFAULT NULL;
    DECLARE v_ancien_texte TEXT;
    DECLARE v_ancienne_visibilite VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        SELECT id_createur, texte, visibilite
        INTO v_id_createur, v_ancien_texte, v_ancienne_visibilite
        FROM fragment
        WHERE id_fragment = p_id_fragment
        FOR UPDATE;

        IF v_id_createur <> p_id_utilisateur THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Modification refusée : seul le créateur du fragment peut le modifier.';
        END IF;

        IF CHAR_LENGTH(TRIM(p_nouveau_texte)) = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Modification refusée : le texte ne peut pas être vide.';
        END IF;

        IF p_nouvelle_visibilite NOT IN ('PRIVE', 'PARTAGE', 'PUBLIC') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Modification refusée : visibilité invalide.';
        END IF;

        INSERT INTO historique_fragment (id_fragment, id_utilisateur, action, ancien_texte, nouveau_texte, ancienne_visibilite, nouvelle_visibilite)
        VALUES (p_id_fragment, p_id_utilisateur, 'MODIFICATION', v_ancien_texte, p_nouveau_texte, v_ancienne_visibilite, p_nouvelle_visibilite);

        UPDATE fragment
        SET texte = p_nouveau_texte,
            visibilite = p_nouvelle_visibilite
        WHERE id_fragment = p_id_fragment;

        INSERT INTO mouvement_fragment (id_fragment, id_utilisateur, type_mouvement, commentaire)
        VALUES (p_id_fragment, p_id_utilisateur, 'MODIFICATION', 'Modification contrôlée du fragment.');

    COMMIT;
END $$

CREATE PROCEDURE ajouter_fragment_complet (
    IN p_id_createur INT,
    IN p_id_type_fragment INT,
    IN p_id_auteur INT,
    IN p_texte TEXT,
    IN p_source_titre VARCHAR(255),
    IN p_source_url VARCHAR(500),
    IN p_visibilite VARCHAR(20),
    IN p_id_humeur INT,
    IN p_id_mode_archivage INT,
    IN p_commentaire_personnel TEXT,
    IN p_favori BOOLEAN,
    IN p_archive BOOLEAN,
    OUT p_id_fragment_cree INT,
    OUT p_id_collection_fragment_cree INT
)
BEGIN
    DECLARE v_nb_createur INT DEFAULT 0;
    DECLARE v_nb_type INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

        SELECT COUNT(*) INTO v_nb_createur FROM utilisateur WHERE id_utilisateur = p_id_createur AND actif = TRUE;
        IF v_nb_createur = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Création impossible : créateur introuvable ou inactif.';
        END IF;

        SELECT COUNT(*) INTO v_nb_type FROM type_fragment WHERE id_type_fragment = p_id_type_fragment;
        IF v_nb_type = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Création impossible : type de fragment introuvable.';
        END IF;

        IF CHAR_LENGTH(TRIM(p_texte)) = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Création impossible : le texte ne peut pas être vide.';
        END IF;

        IF p_visibilite NOT IN ('PRIVE', 'PARTAGE', 'PUBLIC') THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Création impossible : visibilité invalide.';
        END IF;

        INSERT INTO fragment (id_createur, id_type_fragment, id_auteur, texte, source_titre, source_url, visibilite)
        VALUES (p_id_createur, p_id_type_fragment, p_id_auteur, p_texte, p_source_titre, p_source_url, p_visibilite);

        SET p_id_fragment_cree = LAST_INSERT_ID();

        INSERT INTO collection_fragment (id_utilisateur, id_fragment, id_humeur, id_mode_archivage, commentaire_personnel, favori, archive)
        VALUES (p_id_createur, p_id_fragment_cree, p_id_humeur, p_id_mode_archivage, p_commentaire_personnel, p_favori, p_archive);

        SET p_id_collection_fragment_cree = LAST_INSERT_ID();

    COMMIT;
END $$

CREATE PROCEDURE ajouter_theme_a_entree (IN p_id_collection_fragment INT, IN p_id_theme INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
        INSERT INTO collection_theme (id_collection_fragment, id_theme) VALUES (p_id_collection_fragment, p_id_theme);
    COMMIT;
END $$

CREATE PROCEDURE ajouter_mot_cle_a_entree (IN p_id_collection_fragment INT, IN p_id_mot_cle INT)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
        INSERT INTO collection_mot_cle (id_collection_fragment, id_mot_cle) VALUES (p_id_collection_fragment, p_id_mot_cle);
    COMMIT;
END $$

CREATE PROCEDURE soumettre_fragment_pour_avis_utilisateur (
    IN p_id_fragment INT,
    IN p_id_demandeur INT,
    IN p_id_utilisateur_cible INT,
    IN p_message_demande TEXT,
    OUT p_id_demande_creee INT
)
BEGIN
    DECLARE v_nb_fragment INT DEFAULT 0;
    DECLARE v_nb_demandeur INT DEFAULT 0;
    DECLARE v_nb_cible INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        SELECT COUNT(*) INTO v_nb_fragment FROM fragment WHERE id_fragment = p_id_fragment AND supprime_logiquement = FALSE;
        IF v_nb_fragment = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Demande impossible : fragment introuvable ou supprimé.'; END IF;

        SELECT COUNT(*) INTO v_nb_demandeur FROM utilisateur WHERE id_utilisateur = p_id_demandeur AND actif = TRUE;
        IF v_nb_demandeur = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Demande impossible : demandeur introuvable ou inactif.'; END IF;

        SELECT COUNT(*) INTO v_nb_cible FROM utilisateur WHERE id_utilisateur = p_id_utilisateur_cible AND actif = TRUE;
        IF v_nb_cible = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Demande impossible : utilisateur cible introuvable ou inactif.'; END IF;

        INSERT INTO demande_avis (id_fragment, id_demandeur, id_utilisateur_cible, id_groupe_cible, message_demande, statut)
        VALUES (p_id_fragment, p_id_demandeur, p_id_utilisateur_cible, NULL, p_message_demande, 'EN_ATTENTE');

        SET p_id_demande_creee = LAST_INSERT_ID();

        INSERT INTO destinataire_demande_avis (id_demande, id_utilisateur, statut_reponse)
        VALUES (p_id_demande_creee, p_id_utilisateur_cible, 'EN_ATTENTE');
    COMMIT;
END $$

CREATE PROCEDURE soumettre_fragment_pour_avis_groupe (
    IN p_id_fragment INT,
    IN p_id_demandeur INT,
    IN p_id_groupe_cible INT,
    IN p_message_demande TEXT,
    OUT p_id_demande_creee INT
)
BEGIN
    DECLARE v_id_membre INT;
    DECLARE v_membre_actif BOOLEAN;
    DECLARE v_fin INT DEFAULT 0;
    DECLARE v_nb_destinataires INT DEFAULT 0;

    DECLARE cur_membres CURSOR FOR
        SELECT mg.id_utilisateur, u.actif
        FROM membre_groupe mg
        INNER JOIN utilisateur u ON mg.id_utilisateur = u.id_utilisateur
        WHERE mg.id_groupe = p_id_groupe_cible
          AND mg.id_utilisateur <> p_id_demandeur;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        INSERT INTO demande_avis (id_fragment, id_demandeur, id_utilisateur_cible, id_groupe_cible, message_demande, statut)
        VALUES (p_id_fragment, p_id_demandeur, NULL, p_id_groupe_cible, p_message_demande, 'EN_COURS');

        SET p_id_demande_creee = LAST_INSERT_ID();

        OPEN cur_membres;
        boucle_membres: LOOP
            FETCH cur_membres INTO v_id_membre, v_membre_actif;
            IF v_fin = 1 THEN LEAVE boucle_membres; END IF;
            IF v_membre_actif = FALSE THEN ITERATE boucle_membres; END IF;

            INSERT INTO destinataire_demande_avis (id_demande, id_utilisateur, statut_reponse)
            VALUES (p_id_demande_creee, v_id_membre, 'EN_ATTENTE');

            SET v_nb_destinataires = v_nb_destinataires + 1;
        END LOOP;
        CLOSE cur_membres;

        IF v_nb_destinataires = 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Demande impossible : aucun destinataire actif dans le groupe.';
        END IF;
    COMMIT;
END $$

CREATE PROCEDURE enregistrer_avis_fragment (
    IN p_id_demande INT,
    IN p_id_fragment INT,
    IN p_id_utilisateur INT,
    IN p_type_avis VARCHAR(30),
    IN p_note TINYINT,
    IN p_commentaire TEXT
)
BEGIN
    DECLARE v_nb_destinataire INT DEFAULT 0;
    DECLARE v_statut_reponse VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;
        IF p_note < 1 OR p_note > 5 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Avis refusé : note invalide.'; END IF;
        IF p_type_avis NOT IN ('PERTINENT','A_REVOIR','DOUBLON','MAL_CLASSE','INTERESSANT','HORS_SUJET') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Avis refusé : type invalide.'; END IF;

        SELECT COUNT(*) INTO v_nb_destinataire FROM destinataire_demande_avis WHERE id_demande = p_id_demande AND id_utilisateur = p_id_utilisateur;
        IF v_nb_destinataire = 0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Avis refusé : utilisateur non destinataire.'; END IF;

        SELECT statut_reponse INTO v_statut_reponse
        FROM destinataire_demande_avis
        WHERE id_demande = p_id_demande AND id_utilisateur = p_id_utilisateur
        FOR UPDATE;

        IF v_statut_reponse = 'REPONDU' THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Avis refusé : utilisateur déjà répondu.'; END IF;

        INSERT INTO avis_fragment (id_demande, id_fragment, id_utilisateur, type_avis, note, commentaire)
        VALUES (p_id_demande, p_id_fragment, p_id_utilisateur, p_type_avis, p_note, p_commentaire);
    COMMIT;
END $$

CREATE PROCEDURE generer_bilan_utilisateurs ()
BEGIN
    DECLARE v_id_utilisateur INT;
    DECLARE v_fin INT DEFAULT 0;
    DECLARE v_nb_fragments_crees INT DEFAULT 0;
    DECLARE v_nb_fragments_conserves INT DEFAULT 0;
    DECLARE v_nb_favoris INT DEFAULT 0;
    DECLARE v_nb_avis_donnes INT DEFAULT 0;
    DECLARE v_nb_avis_recus INT DEFAULT 0;
    DECLARE v_nb_demandes_avis INT DEFAULT 0;
    DECLARE v_nb_reapparitions INT DEFAULT 0;

    DECLARE cur_utilisateurs CURSOR FOR SELECT id_utilisateur FROM utilisateur WHERE actif = TRUE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;

    OPEN cur_utilisateurs;
    boucle_utilisateurs: LOOP
        FETCH cur_utilisateurs INTO v_id_utilisateur;
        IF v_fin = 1 THEN LEAVE boucle_utilisateurs; END IF;

        SELECT COUNT(*) INTO v_nb_fragments_crees FROM fragment WHERE id_createur = v_id_utilisateur AND supprime_logiquement = FALSE;
        SELECT COUNT(*) INTO v_nb_fragments_conserves FROM collection_fragment WHERE id_utilisateur = v_id_utilisateur;
        SELECT COUNT(*) INTO v_nb_favoris FROM collection_fragment WHERE id_utilisateur = v_id_utilisateur AND favori = TRUE;
        SELECT COUNT(*) INTO v_nb_avis_donnes FROM avis_fragment WHERE id_utilisateur = v_id_utilisateur;
        SELECT COUNT(*) INTO v_nb_avis_recus FROM avis_fragment af INNER JOIN fragment f ON af.id_fragment = f.id_fragment WHERE f.id_createur = v_id_utilisateur AND af.id_utilisateur <> v_id_utilisateur;
        SELECT COUNT(*) INTO v_nb_demandes_avis FROM demande_avis WHERE id_demandeur = v_id_utilisateur;
        SELECT COUNT(*) INTO v_nb_reapparitions FROM interaction_fragment i INNER JOIN collection_fragment cf ON i.id_collection_fragment = cf.id_collection_fragment WHERE cf.id_utilisateur = v_id_utilisateur AND i.type_interaction = 'APPARITION';

        INSERT INTO bilan_utilisateur (id_utilisateur, nb_fragments_crees, nb_fragments_conserves, nb_favoris, nb_avis_donnes, nb_avis_recus, nb_demandes_avis, nb_reapparitions)
        VALUES (v_id_utilisateur, v_nb_fragments_crees, v_nb_fragments_conserves, v_nb_favoris, v_nb_avis_donnes, v_nb_avis_recus, v_nb_demandes_avis, v_nb_reapparitions);
    END LOOP;
    CLOSE cur_utilisateurs;
END $$

CREATE PROCEDURE generer_bilan_groupes ()
BEGIN
    DECLARE v_id_groupe INT;
    DECLARE v_fin INT DEFAULT 0;
    DECLARE v_nb_membres INT DEFAULT 0;
    DECLARE v_nb_demandes_avis INT DEFAULT 0;
    DECLARE v_nb_avis_rendus INT DEFAULT 0;
    DECLARE v_note_moyenne DECIMAL(4,2);

    DECLARE cur_groupes CURSOR FOR SELECT id_groupe FROM groupe_utilisateur;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;

    OPEN cur_groupes;
    boucle_groupes: LOOP
        FETCH cur_groupes INTO v_id_groupe;
        IF v_fin = 1 THEN LEAVE boucle_groupes; END IF;

        SELECT COUNT(*) INTO v_nb_membres FROM membre_groupe WHERE id_groupe = v_id_groupe;
        SELECT COUNT(*) INTO v_nb_demandes_avis FROM demande_avis WHERE id_groupe_cible = v_id_groupe;
        SELECT COUNT(*) INTO v_nb_avis_rendus FROM avis_fragment af INNER JOIN demande_avis da ON af.id_demande = da.id_demande WHERE da.id_groupe_cible = v_id_groupe;
        SELECT AVG(af.note) INTO v_note_moyenne FROM avis_fragment af INNER JOIN demande_avis da ON af.id_demande = da.id_demande WHERE da.id_groupe_cible = v_id_groupe;

        INSERT INTO bilan_groupe (id_groupe, nb_membres, nb_demandes_avis, nb_avis_rendus, note_moyenne)
        VALUES (v_id_groupe, v_nb_membres, v_nb_demandes_avis, v_nb_avis_rendus, v_note_moyenne);
    END LOOP;
    CLOSE cur_groupes;
END $$

CREATE PROCEDURE generer_bilan_publications_utilisateurs ()
BEGIN
    DECLARE v_id_utilisateur INT;
    DECLARE v_fin INT DEFAULT 0;
    DECLARE v_nb_fragments_originaux INT DEFAULT 0;
    DECLARE v_nb_conservations_par_autres INT DEFAULT 0;
    DECLARE v_nb_avis_recus INT DEFAULT 0;
    DECLARE v_note_moyenne DECIMAL(4,2);
    DECLARE v_nb_reapparitions INT DEFAULT 0;

    DECLARE cur_utilisateurs_publications CURSOR FOR SELECT id_utilisateur FROM utilisateur WHERE actif = TRUE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = 1;

    OPEN cur_utilisateurs_publications;
    boucle_publications: LOOP
        FETCH cur_utilisateurs_publications INTO v_id_utilisateur;
        IF v_fin = 1 THEN LEAVE boucle_publications; END IF;

        SELECT COUNT(*) INTO v_nb_fragments_originaux FROM fragment WHERE id_createur = v_id_utilisateur AND supprime_logiquement = FALSE;
        SELECT COUNT(*) INTO v_nb_conservations_par_autres FROM collection_fragment cf INNER JOIN fragment f ON cf.id_fragment = f.id_fragment WHERE f.id_createur = v_id_utilisateur AND cf.id_utilisateur <> v_id_utilisateur;
        SELECT COUNT(*) INTO v_nb_avis_recus FROM avis_fragment af INNER JOIN fragment f ON af.id_fragment = f.id_fragment WHERE f.id_createur = v_id_utilisateur AND af.id_utilisateur <> v_id_utilisateur;
        SELECT AVG(af.note) INTO v_note_moyenne FROM avis_fragment af INNER JOIN fragment f ON af.id_fragment = f.id_fragment WHERE f.id_createur = v_id_utilisateur AND af.id_utilisateur <> v_id_utilisateur;
        SELECT COUNT(*) INTO v_nb_reapparitions FROM interaction_fragment i INNER JOIN collection_fragment cf ON i.id_collection_fragment = cf.id_collection_fragment INNER JOIN fragment f ON cf.id_fragment = f.id_fragment WHERE f.id_createur = v_id_utilisateur AND i.type_interaction = 'APPARITION';

        INSERT INTO bilan_publication_utilisateur (id_utilisateur, nb_fragments_originaux, nb_conservations_par_autres, nb_avis_recus, note_moyenne, nb_reapparitions)
        VALUES (v_id_utilisateur, v_nb_fragments_originaux, v_nb_conservations_par_autres, v_nb_avis_recus, v_note_moyenne, v_nb_reapparitions);
    END LOOP;
    CLOSE cur_utilisateurs_publications;
END $$

CREATE PROCEDURE rechercher_fragments_preparee (IN p_terme VARCHAR(100))
BEGIN
    SET @sql_recherche = 'SELECT f.id_fragment, f.texte, f.visibilite, u.pseudo AS createur FROM fragment f INNER JOIN utilisateur u ON f.id_createur = u.id_utilisateur WHERE f.supprime_logiquement = FALSE AND f.texte LIKE ?';
    SET @motif_recherche = CONCAT('%', p_terme, '%');
    PREPARE stmt_recherche FROM @sql_recherche;
    EXECUTE stmt_recherche USING @motif_recherche;
    DEALLOCATE PREPARE stmt_recherche;
END $$

DELIMITER ;

/* ============================================================
   8. Jeu de données initial
   ============================================================ */

INSERT INTO utilisateur (pseudo, email, actif) VALUES
('francois', 'francois@example.com', TRUE),
('dominique', 'dominique@example.com', TRUE),
('judith', 'judith@example.com', TRUE),
('alcide', 'alcide@example.com', TRUE);

INSERT INTO fragment (id_createur, id_type_fragment, id_auteur, texte, source_titre, source_url, visibilite) VALUES
(1, (SELECT id_type_fragment FROM type_fragment WHERE libelle = 'Citation'), (SELECT id_auteur FROM auteur WHERE nom = 'Héraclite'), 'On ne se baigne jamais deux fois dans le même fleuve.', 'Fragment attribué à Héraclite', NULL, 'PUBLIC'),
(1, (SELECT id_type_fragment FROM type_fragment WHERE libelle = 'Idée personnelle'), NULL, 'Un fragment ne vaut pas seulement par son contenu, mais par la manière dont il revient.', 'Carnet personnel', NULL, 'PRIVE'),
(2, (SELECT id_type_fragment FROM type_fragment WHERE libelle = 'Note de lecture'), (SELECT id_auteur FROM auteur WHERE nom = 'Nietzsche'), 'La solitude peut être une fuite, mais aussi une méthode.', 'Note de lecture', NULL, 'PARTAGE'),
(3, (SELECT id_type_fragment FROM type_fragment WHERE libelle = 'Pensée courte'), NULL, 'Classer, ce n’est pas enfermer : c’est rendre retrouvable.', 'Pensée personnelle', NULL, 'PUBLIC');

INSERT INTO collection_fragment (id_utilisateur, id_fragment, id_humeur, id_mode_archivage, commentaire_personnel, favori, archive) VALUES
(1, 1, (SELECT id_humeur FROM humeur WHERE libelle = 'Lucidité'), (SELECT id_mode_archivage FROM mode_archivage WHERE libelle = 'Indexé'), 'Fragment essentiel sur le devenir et le changement.', TRUE, FALSE),
(1, 2, (SELECT id_humeur FROM humeur WHERE libelle = 'Discipline'), (SELECT id_mode_archivage FROM mode_archivage WHERE libelle = 'À relire'), 'Idée centrale pour le système de réapparition.', TRUE, FALSE),
(2, 1, (SELECT id_humeur FROM humeur WHERE libelle = 'Apaisement'), (SELECT id_mode_archivage FROM mode_archivage WHERE libelle = 'Indexé'), 'Belle image littéraire du temps.', FALSE, FALSE),
(2, 3, (SELECT id_humeur FROM humeur WHERE libelle = 'Solitude'), (SELECT id_mode_archivage FROM mode_archivage WHERE libelle = 'Archive libre'), 'À comparer avec mes propres notes.', FALSE, TRUE),
(3, 4, (SELECT id_humeur FROM humeur WHERE libelle = 'Étonnement'), (SELECT id_mode_archivage FROM mode_archivage WHERE libelle = 'Indexé'), 'Définition utile pour expliquer Palimpseste.', TRUE, FALSE);

INSERT INTO collection_theme (id_collection_fragment, id_theme) VALUES
(1, (SELECT id_theme FROM theme WHERE libelle = 'Philosophie')),
(1, (SELECT id_theme FROM theme WHERE libelle = 'Temps')),
(1, (SELECT id_theme FROM theme WHERE libelle = 'Changement')),
(2, (SELECT id_theme FROM theme WHERE libelle = 'Mémoire')),
(2, (SELECT id_theme FROM theme WHERE libelle = 'Discipline')),
(3, (SELECT id_theme FROM theme WHERE libelle = 'Littérature')),
(3, (SELECT id_theme FROM theme WHERE libelle = 'Temps')),
(4, (SELECT id_theme FROM theme WHERE libelle = 'Philosophie')),
(4, (SELECT id_theme FROM theme WHERE libelle = 'Solitude')),
(5, (SELECT id_theme FROM theme WHERE libelle = 'Technique')),
(5, (SELECT id_theme FROM theme WHERE libelle = 'Mémoire'));

INSERT INTO collection_mot_cle (id_collection_fragment, id_mot_cle) VALUES
(1, (SELECT id_mot_cle FROM mot_cle WHERE libelle = 'temps')),
(1, (SELECT id_mot_cle FROM mot_cle WHERE libelle = 'devenir')),
(1, (SELECT id_mot_cle FROM mot_cle WHERE libelle = 'changement')),
(2, (SELECT id_mot_cle FROM mot_cle WHERE libelle = 'réapparition')),
(2, (SELECT id_mot_cle FROM mot_cle WHERE libelle = 'fragment')),
(2, (SELECT id_mot_cle FROM mot_cle WHERE libelle = 'mémoire')),
(3, (SELECT id_mot_cle FROM mot_cle WHERE libelle = 'citation')),
(3, (SELECT id_mot_cle FROM mot_cle WHERE libelle = 'temps')),
(4, (SELECT id_mot_cle FROM mot_cle WHERE libelle = 'solitude')),
(4, (SELECT id_mot_cle FROM mot_cle WHERE libelle = 'lucidité')),
(5, (SELECT id_mot_cle FROM mot_cle WHERE libelle = 'archive')),
(5, (SELECT id_mot_cle FROM mot_cle WHERE libelle = 'fragment'));

INSERT INTO groupe_utilisateur (id_createur, nom, description)
VALUES (1, 'Lecteurs critiques', 'Groupe de test pour les demandes d’avis sur les fragments.');

INSERT INTO membre_groupe (id_groupe, id_utilisateur, role_groupe) VALUES
(1, 1, 'CREATEUR'),
(1, 2, 'MEMBRE'),
(1, 3, 'MEMBRE'),
(1, 4, 'MEMBRE');

INSERT INTO interaction_fragment (id_collection_fragment, type_interaction) VALUES
(1, 'APPARITION'),
(1, 'FAVORI'),
(1, 'PLUS_SOUVENT'),
(2, 'APPARITION'),
(2, 'PLUS_SOUVENT'),
(4, 'MASQUER'),
(5, 'OUVERTURE_DETAIL');
