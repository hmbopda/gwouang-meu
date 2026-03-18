-- V7: Villages de test — 3 par pays (30 villages avec coordonnees GPS reelles)
-- Objectif : donnees de reference pour les tests PostGIS ST_DWithin et l'UI

-- ============================================================
-- CAMEROUN (CMR) — 3 villages Bassa, Beti, Bamileke
-- ============================================================
INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Edea',
    'Ville industrielle au bord de la Sanaga, berceau du peuple Bassa.',
    'CMR', 'Littoral', 'AF-CENTRAL', 3.7986, 10.1337,
    'Bassa', 85000, 1900, TRUE, c.id
FROM countries c WHERE c.code = 'CMR'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Bafoussam',
    'Capitale de la region de l Ouest, coeur du peuple Bamileke.',
    'CMR', 'Ouest', 'AF-CENTRAL', 5.4782, 10.4175,
    'Bamileke', 290000, 1925, TRUE, c.id
FROM countries c WHERE c.code = 'CMR'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Sangmelima',
    'Village historique Beti au coeur de la foret equatoriale du Sud.',
    'CMR', 'Sud', 'AF-CENTRAL', 2.9389, 11.9839,
    'Beti', 45000, 1895, TRUE, c.id
FROM countries c WHERE c.code = 'CMR'
ON CONFLICT DO NOTHING;

-- ============================================================
-- CONGO RDC (COD) — 3 villages Kongo, Luba, Mongo
-- ============================================================
INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Mbanza-Ngungu',
    'Cite historique Kongo, ancienne capitale du royaume Kongo.',
    'COD', 'Kongo-Central', 'AF-CENTRAL', -5.2579, 14.8588,
    'Kikongo', 120000, 1400, TRUE, c.id
FROM countries c WHERE c.code = 'COD'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Kamina',
    'Ville Luba au Katanga, connue pour sa musique et ses tissages.',
    'COD', 'Haut-Lomami', 'AF-CENTRAL', -8.7374, 25.0027,
    'Kiluba', 80000, 1910, TRUE, c.id
FROM countries c WHERE c.code = 'COD'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Boende',
    'Village Mongo au coeur de la cuvette congolaise.',
    'COD', 'Tshuapa', 'AF-CENTRAL', -0.2222, 20.8786,
    'Mongo', 35000, 1920, TRUE, c.id
FROM countries c WHERE c.code = 'COD'
ON CONFLICT DO NOTHING;

-- ============================================================
-- SENEGAL (SEN) — 3 villages Wolof, Mandingue, Diola
-- ============================================================
INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Kaolack',
    'Carrefour commercial Wolof, capitale de l arachide.',
    'SEN', 'Kaolack', 'AF-WEST', 14.1504, -16.0726,
    'Wolof', 180000, 1887, TRUE, c.id
FROM countries c WHERE c.code = 'SEN'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Kedougou',
    'Village Mandingue a l est, porte d entree vers le Fouta Djallon.',
    'SEN', 'Kedougou', 'AF-WEST', 12.5558, -12.1748,
    'Mandinka', 25000, 1200, TRUE, c.id
FROM countries c WHERE c.code = 'SEN'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Ziguinchor',
    'Capitale de la Casamance, territoire Diola au bord du fleuve.',
    'SEN', 'Ziguinchor', 'AF-WEST', 12.5681, -16.2719,
    'Diola', 65000, 1886, TRUE, c.id
FROM countries c WHERE c.code = 'SEN'
ON CONFLICT DO NOTHING;

-- ============================================================
-- COTE D IVOIRE (CIV) — 3 villages Baoule, Dioula, Bete
-- ============================================================
INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Bouake',
    'Deuxieme ville, coeur du peuple Baoule, centre textile.',
    'CIV', 'Vallee du Bandama', 'AF-WEST', 7.6892, -5.0325,
    'Baoule', 530000, 1898, TRUE, c.id
FROM countries c WHERE c.code = 'CIV'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Korhogo',
    'Capitale du Poro, village Dioula et Senoufo au nord.',
    'CIV', 'Savanes', 'AF-WEST', 9.4581, -5.6297,
    'Dioula', 220000, 1900, TRUE, c.id
FROM countries c WHERE c.code = 'CIV'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Gagnoa',
    'Terre Bete a l ouest, connue pour ses artisans et ses danseurs.',
    'CIV', 'Goh', 'AF-WEST', 6.1313, -5.9507,
    'Bete', 100000, 1922, TRUE, c.id
FROM countries c WHERE c.code = 'CIV'
ON CONFLICT DO NOTHING;

-- ============================================================
-- NIGERIA (NGA) — 3 villages Yoruba, Igbo, Hausa
-- ============================================================
INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Ile-Ife',
    'Cite sacree Yoruba, berceau mythologique de l humanite selon la tradition Yoruba.',
    'NGA', 'Osun State', 'AF-WEST', 7.4892, 4.5596,
    'Yoruba', 180000, 500, TRUE, c.id
FROM countries c WHERE c.code = 'NGA'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Awka',
    'Capitale de l etat d Anambra, coeur de la culture Igbo.',
    'NGA', 'Anambra State', 'AF-WEST', 6.2105, 7.0741,
    'Igbo', 301000, 1800, TRUE, c.id
FROM countries c WHERE c.code = 'NGA'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Katsina',
    'Cite historique Hausa-Fulani, ancienne capitale du califat de Sokoto.',
    'NGA', 'Katsina State', 'AF-WEST', 12.9886, 7.6006,
    'Hausa', 350000, 1400, TRUE, c.id
FROM countries c WHERE c.code = 'NGA'
ON CONFLICT DO NOTHING;

-- ============================================================
-- GHANA (GHA) — 3 villages Akan, Ewe, Dagomba
-- ============================================================
INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Kumasi',
    'Ancienne capitale de l empire Ashanti, riche en or et en tradition.',
    'GHA', 'Ashanti Region', 'AF-WEST', 6.6885, -1.6244,
    'Akan/Twi', 2000000, 1680, TRUE, c.id
FROM countries c WHERE c.code = 'GHA'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Ho',
    'Capital de la region Volta, terre Ewe connue pour le kente.',
    'GHA', 'Volta Region', 'AF-WEST', 6.6012, 0.4706,
    'Ewe', 75000, 1850, TRUE, c.id
FROM countries c WHERE c.code = 'GHA'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Tamale',
    'Capitale du Nord, coeur de la culture Dagomba et Gonja.',
    'GHA', 'Northern Region', 'AF-WEST', 9.4016, -0.8394,
    'Dagbani', 360000, 1600, TRUE, c.id
FROM countries c WHERE c.code = 'GHA'
ON CONFLICT DO NOTHING;

-- ============================================================
-- MALI (MLI) — 3 villages Bambara, Dogon, Peul
-- ============================================================
INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Segou',
    'Ancienne capitale de l empire Bambara, sur le Niger.',
    'MLI', 'Segou', 'AF-WEST', 13.4317, -6.2676,
    'Bambara', 130000, 1712, TRUE, c.id
FROM countries c WHERE c.code = 'MLI'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Bandiagara',
    'Escarpement Dogon, site UNESCO, village des masques et des greniers.',
    'MLI', 'Mopti', 'AF-WEST', 14.3502, -3.6117,
    'Dogon', 14000, 1000, TRUE, c.id
FROM countries c WHERE c.code = 'MLI'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Mopti',
    'Venise du Mali, carrefour Peul, Songhai et Bozo.',
    'MLI', 'Mopti', 'AF-WEST', 14.4943, -4.1978,
    'Peul/Fulfulde', 114000, 1200, TRUE, c.id
FROM countries c WHERE c.code = 'MLI'
ON CONFLICT DO NOTHING;

-- ============================================================
-- BURKINA FASO (BFA) — 3 villages Mossi, Bissa, Lobi
-- ============================================================
INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Koudougou',
    'Troisieme ville, capitale des Mossi de l Ouest.',
    'BFA', 'Centre-Ouest', 'AF-WEST', 12.2499, -2.3632,
    'Moore', 120000, 1600, TRUE, c.id
FROM countries c WHERE c.code = 'BFA'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Garango',
    'Village Bissa, connu pour ses artisans tisserands.',
    'BFA', 'Centre-Est', 'AF-WEST', 11.7908, -0.5469,
    'Bissa', 22000, 1800, TRUE, c.id
FROM countries c WHERE c.code = 'BFA'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Gaoua',
    'Capitale du Poni, territoire Lobi et Gan.',
    'BFA', 'Sud-Ouest', 'AF-WEST', 10.2996, -3.1776,
    'Lobi', 35000, 1900, TRUE, c.id
FROM countries c WHERE c.code = 'BFA'
ON CONFLICT DO NOTHING;

-- ============================================================
-- RWANDA (RWA) — 3 villages Kinyarwanda
-- ============================================================
INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Musanze',
    'Ancienne Ruhengeri, porte des Gorilles et des volcans.',
    'RWA', 'Northern Province', 'AF-EAST', -1.4993, 29.6339,
    'Kinyarwanda', 98000, 1900, TRUE, c.id
FROM countries c WHERE c.code = 'RWA'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Butare',
    'Huye, capitale intellectuelle du Rwanda, site de l universite nationale.',
    'RWA', 'Southern Province', 'AF-EAST', -2.5969, 29.7394,
    'Kinyarwanda', 89000, 1930, TRUE, c.id
FROM countries c WHERE c.code = 'RWA'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Rwamagana',
    'Chef-lieu de la Province de l Est, sur les bords du lac Muhazi.',
    'RWA', 'Eastern Province', 'AF-EAST', -1.9491, 30.4358,
    'Kinyarwanda', 55000, 1910, TRUE, c.id
FROM countries c WHERE c.code = 'RWA'
ON CONFLICT DO NOTHING;

-- ============================================================
-- TANZANIE (TZA) — 3 villages Swahili, Chaga, Makonde
-- ============================================================
INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Bagamoyo',
    'Ancienne capitale du Sultanat de Zanzibar, port historique Swahili.',
    'TZA', 'Coast Region', 'AF-EAST', -6.4400, 38.9070,
    'Kiswahili', 75000, 800, TRUE, c.id
FROM countries c WHERE c.code = 'TZA'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Moshi',
    'Pied du Kilimandjaro, territoire Chaga renomme pour son cafe.',
    'TZA', 'Kilimanjaro Region', 'AF-EAST', -3.3528, 37.3397,
    'Kichaga', 185000, 1600, TRUE, c.id
FROM countries c WHERE c.code = 'TZA'
ON CONFLICT DO NOTHING;

INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude,
                      primary_dialect, population_estimate, founded_year, is_verified, country_id)
SELECT
    'Masasi',
    'Village Makonde au Ruvuma, connu pour ses sculptures en ebene.',
    'TZA', 'Mtwara Region', 'AF-EAST', -10.7257, 38.8097,
    'Kimakonde', 65000, 1700, TRUE, c.id
FROM countries c WHERE c.code = 'TZA'
ON CONFLICT DO NOTHING;
