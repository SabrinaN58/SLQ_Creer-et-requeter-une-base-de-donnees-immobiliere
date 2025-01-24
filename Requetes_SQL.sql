select * from commune ;

ALTER TABLE vente RENAME COLUMN date_mutation TO date;


-- Le nombre total d'appartements vendus au 1er semestre 2020
SELECT count(id_bien) as nbr_appartements 
FROM bien
WHERE type_local = "appartement";


-- Le nombre de ventes d'appartement par région pour le 1er semestre 2020
SELECT  c.nom_region, count(b.id_bien) as nbr_ventes
FROM commune c
JOIN bien b
ON c.id_codedep_codecommune = b.id_codedep_codecommune
WHERE type_local = "Appartement"
GROUP BY c.nom_region
ORDER BY nbr_ventes DESC;


-- Proportion des ventes d'appartements par le nombre de pièces

WITH ventes_par_nbrpieces as (
SELECT total_piece, count(id_bien) as nbr_ventes_app,
SUM(count(id_bien)) OVER() AS total_ventes
FROM bien 
WHERE type_local = "Appartement"
GROUP BY total_piece)
SELECT total_piece, ROUND((nbr_ventes_app/total_ventes*100),3) as proportion_ventes_par_nbrpieces
FROM ventes_par_nbrpieces
ORDER BY total_piece;


-- Liste des 10 départements où le prix du mètre carré est le plus élevé

SELECT  c.code_departement, ROUND(AVG(v.valeur / b.surface_carrez),2) as prix_m2_dep
FROM commune c
JOIN bien b
ON c.id_codedep_codecommune = b.id_codedep_codecommune
JOIN vente v
ON b.id_bien = v.id_bien 
GROUP BY c.code_departement
ORDER BY prix_m2_dep DESC
LIMIT 10;


-- Prix moyen du mètre carré d'une maison en ile-de-france


	SELECT round(AVG(v.valeur / b.surface_carrez),2) AS prix_m2_maison_idf
	FROM commune c
	JOIN bien b
	ON c.id_codedep_codecommune = b.id_codedep_codecommune
	JOIN vente v
	ON b.id_bien = v.id_bien 
	WHERE b.type_local = "Maison" AND c.nom_region = "Ile-De-France";


-- Liste des 10 appartements les plus chers avec la région et le nombre de mètre carré

SELECT b.id_bien, c.nom_region, b.surface_carrez, v.valeur
FROM commune c
JOIN bien b
ON c.id_codedep_codecommune = b.id_codedep_codecommune
JOIN vente v
ON b.id_bien = v.id_bien 
WHERE type_local = "Appartement"
ORDER BY v.valeur DESC
LIMIT 10;


-- Taux évolution du nombre de vente entre le 1er trimestre et le 2nd trimestre 2020

WITH ventes_trim1 AS
	(SELECT COUNT(b.id_bien) AS nbr_ventes1
	FROM bien b
	JOIN VENTE V
	ON b.id_bien = v.id_bien
	WHERE date_mutation BETWEEN "2020-01-02" AND "2020-03-31"),
ventes_trim2 AS
	(SELECT COUNT(b.id_bien) AS nbr_ventes2
	FROM bien b
	JOIN vente v
	ON b.id_bien = v.id_bien
	WHERE date_mutation BETWEEN "2020-04-01" AND "2020-06-30")
SELECT ROUND(((ventes_trim2.nbr_ventes2 - ventes_trim1.nbr_ventes1) / ventes_trim1.nbr_ventes1)*100,2) as evolution_ventes
FROM ventes_trim1, ventes_trim2;

-- Le classement des régions par rapport au prix du mètre carré des appartements de plus de 4 pièces

WITH region_classement_prix_m2 AS
(SELECT c.nom_region, AVG(v.valeur / b.surface_carrez) AS prix_m2
FROM commune c
JOIN bien b
ON c.id_codedep_codecommune = b.id_codedep_codecommune
JOIN vente v
ON b.id_bien = v.id_bien
WHERE b.type_local = "Appartement" AND b.total_piece > 4
GROUP BY c.nom_region)
SELECT nom_region, ROUND(prix_m2,2) AS prix_m2_region,
RANK() OVER( ORDER BY prix_m2 DESC) AS classement_region
FROM region_classement_prix_m2;


-- Liste des communes ayant eu au moins 50 ventes au 1er trimestre

SELECT c.nom_commune, v.date_mutation, COUNT(b.id_bien) as nbr_ventes
FROM commune c
JOIN bien b
ON c.id_codedep_codecommune = b.id_codedep_codecommune
JOIN vente v
ON b.id_bien = v.id_bien
WHERE v.date_mutation between "2020-01-02" AND "2020-03-31"
GROUP BY c.nom_commune, v.date_mutation
HAVING nbr_ventes >= 50
ORDER BY nbr_ventes;

SELECT c.nom_commune, COUNT(b.id_bien) AS nbr_ventes 
FROM commune c
JOIN bien b
ON c.id_codedep_codecommune = b.id_codedep_codecommune
JOIN vente v
ON b.id_bien = v.id_bien
WHERE date between "2020-01-02" AND "2020-03-31"
GROUP BY c.nom_commune
HAVING nbr_ventes >= 50
ORDER BY nbr_ventes;


-- Difference en pourcentage du prix au metre carré entre un appartement de 2 pièces et un appartement de 3 pièces

WITH appart2 AS
(SELECT AVG(v.valeur / b.surface_carrez) AS prix_m2_2pieces
FROM commune c
INNER JOIN bien b
ON c.id_codedep_codecommune = b.id_codedep_codecommune
INNER JOIN vente v
ON b.id_bien = v.id_bien
WHERE b.type_local = "Appartement" AND b.total_piece = 2),
appart3 AS
(SELECT AVG(v.valeur / b.surface_carrez)  AS prix_m2_3pieces
FROM commune c
JOIN bien b
ON c.id_codedep_codecommune = b.id_codedep_codecommune
JOIN vente v
ON b.id_bien = v.id_bien
WHERE b.type_local = "Appartement" AND b.total_piece = 3)
SELECT ROUND(((appart3.prix_m2_3pieces - appart2.prix_m2_2pieces) / appart2.prix_m2_2pieces) * 100,2) AS pourcentage_diff
FROM appart2, appart3;


-- Moyenne des valeurs foncière pour le top 3 des communes
WITH avg_valeur_dep AS
(SELECT c.code_departement, c.nom_commune, ROUND(AVG(v.valeur),2) AS avg_valeur
FROM commune c
JOIN bien b
ON c.id_codedep_codecommune = b.id_codedep_codecommune
JOIN vente v
ON b.id_bien = v.id_bien
WHERE code_departement in (06,13,33,59,69)
GROUP BY c.code_departement, c.nom_commune),
classement_dep AS
(SELECT *, RANK() OVER(PARTITION BY code_departement ORDER BY avg_valeur DESC) AS classement_commune
FROM avg_valeur_dep)
SELECT * FROM classement_dep
WHERE classement_commune <=3;



-- les 20 communes avec le plus de transactions pour 1000 habitants pour les communes qui dépassent les 10000 habitants

WITH commune_transaction AS
(SELECT c.nom_commune, COUNT(b.id_bien) as nbr_transaction, c.population
FROM commune c
INNER JOIN bien b
ON c.id_codedep_codecommune = b.id_codedep_codecommune
WHERE c.population > 10000
GROUP BY c.nom_commune, c.population)
SELECT nom_commune, ROUND((nbr_transaction / population)*1000) AS transaction_1000_hab
FROM commune_transaction
ORDER BY transaction_1000_hab DESC
LIMIT 20









