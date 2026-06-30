-- ============================================================
-- TESTS SIMPLES D'ERREURS - PALIMPSESTE
-- À lancer un test à la fois, car certains CALL échouent volontairement.
-- ============================================================

-- Quelques identifiants utiles
SELECT id_utilisateur INTO @id_francois
FROM utilisateur
WHERE pseudo = 'francois';

SELECT id_utilisateur INTO @id_dominique
FROM utilisateur
WHERE pseudo = 'dominique';

SELECT id_fragment INTO @id_fragment_francois
FROM fragment
WHERE id_createur = @id_francois
LIMIT 1;

SELECT id_type_fragment INTO @id_type_fragment
FROM type_fragment
LIMIT 1;


-- ============================================================
-- 1. Erreur : tentative de modification par un non-créateur
-- Attendu : Modification refusée : seul le créateur du fragment peut le modifier.
-- ============================================================

CALL modifier_fragment(
    @id_fragment_francois,
    @id_dominique,
    'Tentative de modification non autorisée',
    'PUBLIC'
);


-- ============================================================
-- 2. Erreur : texte vide lors d'une modification
-- Attendu : Modification refusée : le texte ne peut pas être vide.
-- ============================================================

CALL modifier_fragment(
    @id_fragment_francois,
    @id_francois,
    '     ',
    'PUBLIC'
);


-- ============================================================
-- 3. Erreur : visibilité invalide lors d'une modification
-- Attendu : Modification refusée : visibilité invalide.
-- ============================================================

CALL modifier_fragment(
    @id_fragment_francois,
    @id_francois,
    'Texte valide mais visibilité invalide',
    'INCONNUE'
);


-- ============================================================
-- 4. Erreur : texte vide lors de la création complète d'un fragment
-- Attendu : Création impossible : le texte ne peut pas être vide.
-- ============================================================

CALL ajouter_fragment_complet(
    @id_francois,
    @id_type_fragment,
    NULL,
    '     ',
    NULL,
    NULL,
    'PRIVE',
    NULL,
    NULL,
    'Test erreur texte vide',
    FALSE,
    FALSE,
    @id_fragment_cree,
    @id_collection_fragment_cree
);


-- ============================================================
-- 5. Erreur : visibilité invalide lors de la création complète
-- Attendu : Création impossible : visibilité invalide.
-- ============================================================

CALL ajouter_fragment_complet(
    @id_francois,
    @id_type_fragment,
    NULL,
    'Texte valide',
    NULL,
    NULL,
    'VISIBLE',
    NULL,
    NULL,
    'Test erreur visibilité',
    FALSE,
    FALSE,
    @id_fragment_cree,
    @id_collection_fragment_cree
);

