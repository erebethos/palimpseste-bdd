# Vérification du 21 octobre 2026

Environnement : MariaDB **10.11.14**, base de démonstration recréée à partir de `Base de donnees.sql`. Ces résultats décrivent une exécution locale ; ils ne constituent pas un statut de CI automatique.

| Contrôle | Résultat observé |
|---|---|
| Installation complète sans option `--force` | Réussie |
| Tables / triggers / procédures | 24 / 5 / 12 |
| `compter_fragments_conserves(1, @total)` avant les tests | 2 |
| `Test Triggers et Procedures.sql` | 14 scénarios exécutés sans erreur SQL |
| Journal `erreur_trigger` après les scénarios | 0 ligne |
| `bonus_tests_erreurs.sql` | 5 refus SQLSTATE `45000`, conformes aux messages attendus |
| Demande sans cible ou avec deux cibles | 2 refus par le `CHECK` (`4025`) |
| Suppression ou changement d’ID d’une cible utilisateur/groupe encore référencée | 4 refus par clé étrangère (`1451`) |

## Correction nécessaire à l’installation

Les clés étrangères `fk_demande_avis_utilisateur_cible` et `fk_demande_avis_groupe_cible` utilisaient des actions `CASCADE` / `SET NULL` en combinaison avec le `CHECK` qui impose exactement une cible. MariaDB 10.11 refusait alors de créer la table (`1901`).

Les deux relations utilisent maintenant `ON UPDATE RESTRICT ON DELETE RESTRICT`. Une demande conserve sa cible ; supprimer ou renuméroter cette cible nécessite de traiter d’abord les demandes qui la référencent. Les autres actions référentielles restent inchangées.

Le problème de compatibilité est documenté dans le [ticket MariaDB MDEV-31769](https://jira.mariadb.org/browse/MDEV-31769).

## Reproduire les essais de cible

Dans une session connectée à `palimpseste`, sur la base de démonstration :

```sql
-- Chaque INSERT suivant doit échouer avec l’erreur 4025.
INSERT INTO demande_avis(id_fragment, id_demandeur, id_utilisateur_cible, id_groupe_cible)
VALUES (1, 1, NULL, NULL);
INSERT INTO demande_avis(id_fragment, id_demandeur, id_utilisateur_cible, id_groupe_cible)
VALUES (1, 1, 1, 1);

-- Cette cible temporaire ne peut être supprimée tant que sa demande existe.
START TRANSACTION;
INSERT INTO utilisateur(pseudo,email) VALUES ('regression','regression@example.com');
SET @cible = LAST_INSERT_ID();
INSERT INTO demande_avis(id_fragment,id_demandeur,id_utilisateur_cible) VALUES (1,1,@cible);
DELETE FROM utilisateur WHERE id_utilisateur=@cible; -- Erreur 1451 attendue.
ROLLBACK;
```

Exécuter les instructions une par une pour observer les refus, et terminer la transaction par `ROLLBACK`.
