# Macros dbt

Ce répertoire contient les macros dbt pour ce projet.

## Qu'est-ce qu'une macro dbt ?

Une macro dbt est un morceau de code réutilisable, similaire à une fonction dans un langage de programmation comme Python. Elles sont écrites en **Jinja** (le langage de template de dbt) et permettent de :
-   Factoriser du code SQL pour ne pas le répéter.
-   Ajouter des logiques complexes qui ne sont pas possibles en SQL simple.
-   Surcharger le comportement par défaut de dbt.

---

## Macro : `generate_schema_name.sql`

Cette macro surcharge le comportement par défaut de dbt pour la génération des noms de schémas dans Snowflake.

### Le problème qu'elle résout

Par défaut, dbt concatene le schéma défini dans le profil (`profiles.yml`) avec celui que spécifié pour un modèle (`dbt_project.yml`).

**Exemple du comportement par défaut :**
-   Schéma du profil (`target.schema`) : `STAGING`
-   Schéma personnalisé pour les modèles "gold" (`+schema`) : `ANALYTICS`
-   **Résultat sans la macro :** dbt crée un schéma nommé `STAGING_ANALYTICS`. 

### La solution apportée par la macro

Cette macro force dbt à suivre une logique simple :

1.  **Si un schéma personnalisé est défini** pour un modèle (ex: `+schema: ANALYTICS` dans `dbt_project.yml`), **utiliser uniquement ce nom de schéma**.
2.  **Sinon**, utiliser le schéma par défaut défini dans le profil (`target.schema`, qui est `STAGING` dans notre cas).

Grâce à cette macro, les modèles sont bien créés dans les schémas `STAGING` et `ANALYTICS` de manière distincte, sans créer de schémas non désirés.