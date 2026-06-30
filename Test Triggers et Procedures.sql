/*
    ============================================================
    Projet : Palimpseste
    Script : Test Triggers et Procedures.sql
    Version : SAFE
    ============================================================

    Cette version evite les recherches par libelle avec accents.
    Les tests utilisent les identifiants fixes des donnees de reference.

    Rappels des ids de reference utilises :
    type_fragment :
      1 Citation
      2 Idee personnelle
      3 Extrait web
      4 Note de lecture
      5 Pensee courte

    humeur :
      1 Lucidite
      4 Apaisement
      8 Discipline

    mode_archivage :
      1 Indexe
      3 A relire

    theme :
      5 Technique
      7 Memoire

    mot_cle :
      5 memoire
      12 fragment
*/

USE palimpseste;
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;

/* ============================================================
   TEST 1 : procedure simple
   Objectif : compter les fragments conserves par francois.
   ============================================================ */

CALL compter_fragments_conserves(1, @total_francois);

SELECT @total_francois AS total_fragments_conserves_francois;


/* ============================================================
   TEST 2 : trigger AFTER INSERT ON fragment -> mouvement CREATION
   Objectif : verifier qu'un INSERT dans fragment cree un mouvement.
   ============================================================ */

SELECT COUNT(*) AS nb_mouvements_avant
FROM mouvement_fragment;

INSERT INTO fragment (
    id_createur,
    id_type_fragment,
    id_auteur,
    texte,
    source_titre,
    source_url,
    visibilite
)
VALUES (
    1,
    5,
    NULL,
    'Fragment direct pour tester le trigger de creation.',
    'Test trigger',
    NULL,
    'PRIVE'
);

SET @id_fragment_direct = LAST_INSERT_ID();

SELECT @id_fragment_direct AS id_fragment_direct;

SELECT *
FROM mouvement_fragment
WHERE id_fragment = @id_fragment_direct;


/* ============================================================
   TEST 3 : trigger AFTER INSERT ON collection_fragment
   Objectif :
   - creer automatiquement une preference de reapparition ;
   - creer automatiquement un mouvement AJOUT_COLLECTION.
   ============================================================ */

INSERT INTO collection_fragment (
    id_utilisateur,
    id_fragment,
    id_humeur,
    id_mode_archivage,
    commentaire_personnel,
    favori,
    archive
)
VALUES (
    1,
    @id_fragment_direct,
    1,
    1,
    'Entree creee pour tester le trigger collection_fragment.',
    FALSE,
    FALSE
);

SET @id_collection_directe = LAST_INSERT_ID();

SELECT @id_collection_directe AS id_collection_directe;

SELECT *
FROM preference_reapparition
WHERE id_collection_fragment = @id_collection_directe;

SELECT *
FROM mouvement_fragment
WHERE id_fragment = @id_fragment_direct
ORDER BY id_mouvement;


/* ============================================================
   TEST 4 : trigger AFTER INSERT ON interaction_fragment
   Objectif :
   - APPARITION augmente nombre_apparitions ;
   - PLUS_SOUVENT augmente score_preference ;
   - MASQUER met est_masque_accueil a TRUE.
   ============================================================ */

SELECT *
FROM preference_reapparition
WHERE id_collection_fragment = @id_collection_directe;

INSERT INTO interaction_fragment (id_collection_fragment, type_interaction)
VALUES
    (@id_collection_directe, 'APPARITION'),
    (@id_collection_directe, 'PLUS_SOUVENT'),
    (@id_collection_directe, 'MASQUER');

SELECT *
FROM preference_reapparition
WHERE id_collection_fragment = @id_collection_directe;

SELECT *
FROM mouvement_fragment
WHERE id_fragment = @id_fragment_direct
ORDER BY id_mouvement;


/* ============================================================
   TEST 5 : procedure ajouter_fragment_complet
   Objectif :
   - creer un fragment ;
   - creer son entree de collection ;
   - declencher les triggers associes.
   ============================================================ */

CALL ajouter_fragment_complet(
    1,
    5,
    NULL,
    'Un bon systeme conserve les donnees et la raison de leur presence.',
    'Carnet personnel',
    NULL,
    'PARTAGE',
    8,
    3,
    'Fragment cree via procedure complete.',
    TRUE,
    FALSE,
    @id_fragment_cree,
    @id_collection_fragment_cree
);

SELECT @id_fragment_cree AS id_fragment_cree,
       @id_collection_fragment_cree AS id_collection_fragment_cree;

SELECT *
FROM fragment
WHERE id_fragment = @id_fragment_cree;

SELECT *
FROM collection_fragment
WHERE id_collection_fragment = @id_collection_fragment_cree;


/* ============================================================
   TEST 6 : procedures ajouter_theme_a_entree et ajouter_mot_cle_a_entree
   Objectif : ajouter themes et mots-cles a l'entree creee.
   ============================================================ */

CALL ajouter_theme_a_entree(@id_collection_fragment_cree, 5);
CALL ajouter_theme_a_entree(@id_collection_fragment_cree, 7);

CALL ajouter_mot_cle_a_entree(@id_collection_fragment_cree, 12);
CALL ajouter_mot_cle_a_entree(@id_collection_fragment_cree, 5);

SELECT *
FROM collection_theme
WHERE id_collection_fragment = @id_collection_fragment_cree;

SELECT *
FROM collection_mot_cle
WHERE id_collection_fragment = @id_collection_fragment_cree;


/* ============================================================
   TEST 7 : procedure modifier_fragment
   Objectif :
   - modifier le fragment ;
   - ajouter une ligne dans historique_fragment ;
   - ajouter un mouvement MODIFICATION.
   ============================================================ */

CALL modifier_fragment(
    @id_fragment_cree,
    1,
    'Un bon systeme conserve les donnees, mais aussi la raison de leur presence.',
    'PUBLIC'
);

SELECT id_fragment, texte, visibilite
FROM fragment
WHERE id_fragment = @id_fragment_cree;

SELECT *
FROM historique_fragment
WHERE id_fragment = @id_fragment_cree
ORDER BY id_historique DESC;

SELECT *
FROM mouvement_fragment
WHERE id_fragment = @id_fragment_cree
ORDER BY id_mouvement;


/* ============================================================
   TEST 8 : procedure soumettre_fragment_pour_avis_utilisateur
   Objectif :
   - creer une demande d'avis ;
   - creer un destinataire ;
   - declencher le mouvement DEMANDE_AVIS.
   ============================================================ */

CALL soumettre_fragment_pour_avis_utilisateur(
    @id_fragment_cree,
    1,
    3,
    'Judith, peux-tu donner ton avis sur ce fragment ?',
    @id_demande_utilisateur
);

SELECT *
FROM demande_avis
WHERE id_demande = @id_demande_utilisateur;

SELECT *
FROM destinataire_demande_avis
WHERE id_demande = @id_demande_utilisateur;

SELECT *
FROM mouvement_fragment
WHERE id_fragment = @id_fragment_cree
ORDER BY id_mouvement;


/* ============================================================
   TEST 9 : procedure enregistrer_avis_fragment
   Objectif :
   - inserer un avis ;
   - passer le destinataire a REPONDU ;
   - passer la demande a TRAITEE ;
   - declencher le mouvement AVIS_RECU.
   ============================================================ */

CALL enregistrer_avis_fragment(
    @id_demande_utilisateur,
    @id_fragment_cree,
    3,
    'INTERESSANT',
    5,
    'Fragment clair et exploitable.'
);

SELECT *
FROM avis_fragment
WHERE id_demande = @id_demande_utilisateur;

SELECT *
FROM destinataire_demande_avis
WHERE id_demande = @id_demande_utilisateur;

SELECT *
FROM demande_avis
WHERE id_demande = @id_demande_utilisateur;


/* ============================================================
   TEST 10 : procedure soumettre_fragment_pour_avis_groupe
   Objectif :
   - creer une demande de groupe ;
   - utiliser le curseur pour creer les destinataires.
   ============================================================ */

CALL soumettre_fragment_pour_avis_groupe(
    @id_fragment_cree,
    1,
    1,
    'Avis collectif demande sur ce fragment.',
    @id_demande_groupe
);

SELECT *
FROM demande_avis
WHERE id_demande = @id_demande_groupe;

SELECT *
FROM destinataire_demande_avis
WHERE id_demande = @id_demande_groupe
ORDER BY id_utilisateur;


/* ============================================================
   TEST 11 : reponses partielles sur demande de groupe
   Objectif :
   - deux destinataires repondent ;
   - un destinataire reste EN_ATTENTE ;
   - la demande reste EN_COURS.
   ============================================================ */

CALL enregistrer_avis_fragment(
    @id_demande_groupe,
    @id_fragment_cree,
    2,
    'PERTINENT',
    4,
    'Bonne idee, fragment exploitable.'
);

CALL enregistrer_avis_fragment(
    @id_demande_groupe,
    @id_fragment_cree,
    3,
    'INTERESSANT',
    5,
    'La formulation soutient bien le projet.'
);

SELECT *
FROM destinataire_demande_avis
WHERE id_demande = @id_demande_groupe
ORDER BY id_utilisateur;

SELECT *
FROM demande_avis
WHERE id_demande = @id_demande_groupe;


/* ============================================================
   TEST 12 : procedures de bilan avec curseurs
   Objectif : generer les bilans.
   ============================================================ */

CALL generer_bilan_utilisateurs();
CALL generer_bilan_groupes();
CALL generer_bilan_publications_utilisateurs();

SELECT *
FROM bilan_utilisateur
ORDER BY id_bilan DESC;

SELECT *
FROM bilan_groupe
ORDER BY id_bilan_groupe DESC;

SELECT *
FROM bilan_publication_utilisateur
ORDER BY id_bilan_publication DESC;


/* ============================================================
   TEST 13 : procedure avec requete preparee
   Objectif : rechercher les fragments contenant un terme.
   ============================================================ */

CALL rechercher_fragments_preparee('fragment');


/* ============================================================
   TEST 14 : table erreur_trigger
   Objectif : verifier la table de journalisation des erreurs triggers.
   Elle reste vide si aucun trigger n'a rencontre d'erreur.
   ============================================================ */

SELECT *
FROM erreur_trigger;
