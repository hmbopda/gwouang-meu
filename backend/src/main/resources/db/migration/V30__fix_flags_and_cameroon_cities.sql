-- V30: Fix flag emojis (direct UTF-8 instead of U& escapes) + seed ALL Cameroon cities/villages
-- The U&'\1F1E8\1F1F2' syntax from V6 doesn't render correctly in some JDBC drivers.
-- We overwrite with direct emoji characters.

-- ============================================================
-- 1. FIX FLAG EMOJIS FOR ALL 10 COUNTRIES
-- ============================================================
UPDATE countries SET flag_emoji = '🇨🇲' WHERE code = 'CMR';
UPDATE countries SET flag_emoji = '🇨🇩' WHERE code = 'COD';
UPDATE countries SET flag_emoji = '🇸🇳' WHERE code = 'SEN';
UPDATE countries SET flag_emoji = '🇨🇮' WHERE code = 'CIV';
UPDATE countries SET flag_emoji = '🇳🇬' WHERE code = 'NGA';
UPDATE countries SET flag_emoji = '🇬🇭' WHERE code = 'GHA';
UPDATE countries SET flag_emoji = '🇲🇱' WHERE code = 'MLI';
UPDATE countries SET flag_emoji = '🇧🇫' WHERE code = 'BFA';
UPDATE countries SET flag_emoji = '🇷🇼' WHERE code = 'RWA';
UPDATE countries SET flag_emoji = '🇹🇿' WHERE code = 'TZA';

-- ============================================================
-- 2. ALL CAMEROON CITIES & VILLAGES (~100 entries)
--    10 Regions, capitales regionales + chefs-lieux departementaux
--    + villes et villages importants
-- ============================================================

-- Helper: get CMR country_id once
DO $$
DECLARE
    cmr_id UUID;
BEGIN
    SELECT id INTO cmr_id FROM countries WHERE code = 'CMR';
    IF cmr_id IS NULL THEN
        RAISE NOTICE 'Country CMR not found, skipping village inserts';
        RETURN;
    END IF;

    -- ── REGION CENTRE ──
    INSERT INTO villages (name, description, country, region, continent_code, latitude, longitude, primary_dialect, population_estimate, is_verified, country_id)
    VALUES
    ('Yaounde', 'Capitale politique du Cameroun, centre administratif et universitaire.', 'CMR', 'Centre', 'AF-CENTRAL', 3.8480, 11.5021, 'Ewondo', 4100000, TRUE, cmr_id),
    ('Mbalmayo', 'Chef-lieu du departement du Nyong-et-So''o, ville cacaoyere.', 'CMR', 'Centre', 'AF-CENTRAL', 3.5167, 11.5000, 'Ewondo', 80000, TRUE, cmr_id),
    ('Obala', 'Chef-lieu du departement de la Lekie, carrefour routier.', 'CMR', 'Centre', 'AF-CENTRAL', 4.1667, 11.5333, 'Eton', 35000, TRUE, cmr_id),
    ('Nanga-Eboko', 'Chef-lieu du departement de la Haute-Sanaga.', 'CMR', 'Centre', 'AF-CENTRAL', 4.6833, 12.3667, 'Yebekolo', 25000, TRUE, cmr_id),
    ('Akonolinga', 'Chef-lieu du departement du Nyong-et-Mfoumou.', 'CMR', 'Centre', 'AF-CENTRAL', 3.7667, 12.2500, 'Mvele', 20000, TRUE, cmr_id),
    ('Monatele', 'Chef-lieu du departement de la Lekie, terre Eton.', 'CMR', 'Centre', 'AF-CENTRAL', 4.2500, 11.2000, 'Eton', 15000, TRUE, cmr_id),
    ('Bafia', 'Chef-lieu du departement du Mban, peuple Bafia.', 'CMR', 'Centre', 'AF-CENTRAL', 4.7500, 11.2333, 'Rikpa', 70000, TRUE, cmr_id),
    ('Ntui', 'Chef-lieu du departement du Mbam-et-Kim.', 'CMR', 'Centre', 'AF-CENTRAL', 4.4500, 11.6167, 'Tikar', 15000, TRUE, cmr_id),
    ('Mfou', 'Chef-lieu du departement de la Mefou-et-Afamba.', 'CMR', 'Centre', 'AF-CENTRAL', 3.7167, 11.6333, 'Ewondo', 20000, TRUE, cmr_id),
    ('Soa', 'Ville universitaire proche de Yaounde.', 'CMR', 'Centre', 'AF-CENTRAL', 3.9667, 11.5833, 'Ewondo', 30000, TRUE, cmr_id),
    ('Eseka', 'Chef-lieu du departement du Nyong-et-Kelle.', 'CMR', 'Centre', 'AF-CENTRAL', 3.6500, 10.7667, 'Bassa', 25000, TRUE, cmr_id),
    ('Okola', 'Ville de la Lekie, terre Eton.', 'CMR', 'Centre', 'AF-CENTRAL', 4.0167, 11.3833, 'Eton', 10000, TRUE, cmr_id),
    ('Esse', 'Chef-lieu de l''arrondissement d''Esse, departement de la Mefou-et-Afamba.', 'CMR', 'Centre', 'AF-CENTRAL', 3.8333, 11.8333, 'Ewondo', 8000, TRUE, cmr_id),
    ('Evodoula', 'Chef-lieu du departement de la Lekie.', 'CMR', 'Centre', 'AF-CENTRAL', 4.0833, 11.2000, 'Eton', 10000, TRUE, cmr_id),
    ('Ngoumou', 'Ville du departement de la Mefou-et-Akono.', 'CMR', 'Centre', 'AF-CENTRAL', 3.5833, 11.3833, 'Ewondo', 8000, TRUE, cmr_id),

    -- ── REGION LITTORAL ──
    ('Douala', 'Capital economique du Cameroun, premier port d''Afrique centrale.', 'CMR', 'Littoral', 'AF-CENTRAL', 4.0511, 9.7679, 'Duala', 3800000, TRUE, cmr_id),
    ('Nkongsamba', 'Troisieme ville, ancienne capitale du Mungo.', 'CMR', 'Littoral', 'AF-CENTRAL', 4.9547, 9.9404, 'Mbo', 130000, TRUE, cmr_id),
    ('Loum', 'Ville du departement du Moungo, bassin bananier.', 'CMR', 'Littoral', 'AF-CENTRAL', 4.7167, 9.7333, 'Mbo', 50000, TRUE, cmr_id),
    ('Manjo', 'Ville du departement du Moungo.', 'CMR', 'Littoral', 'AF-CENTRAL', 4.8333, 9.8167, 'Mbo', 20000, TRUE, cmr_id),
    ('Mbanga', 'Ville du departement du Moungo, carrefour ferroviaire.', 'CMR', 'Littoral', 'AF-CENTRAL', 4.5000, 9.5667, 'Duala', 30000, TRUE, cmr_id),
    ('Dizangue', 'Chef-lieu du departement de la Sanaga-Maritime.', 'CMR', 'Littoral', 'AF-CENTRAL', 3.7667, 9.9833, 'Bassa', 15000, TRUE, cmr_id),
    ('Penja', 'Ville reputee pour son poivre blanc, patrimoine culinaire.', 'CMR', 'Littoral', 'AF-CENTRAL', 4.6333, 9.6833, 'Mbo', 35000, TRUE, cmr_id),
    ('Bonaberi', 'Quartier historique de Douala, rive droite du Wouri.', 'CMR', 'Littoral', 'AF-CENTRAL', 4.0700, 9.6900, 'Duala', 200000, TRUE, cmr_id),

    -- ── REGION OUEST ──
    ('Dschang', 'Ville universitaire, climat frais des hauts plateaux.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.4500, 10.0667, 'Fe''efe''e', 110000, TRUE, cmr_id),
    ('Mbouda', 'Chef-lieu du departement des Bamboutos.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.6333, 10.2500, 'Ngiembon', 65000, TRUE, cmr_id),
    ('Bandjoun', 'Chefferie traditionnelle Bamileke majeure.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.3833, 10.4167, 'Ghomala', 45000, TRUE, cmr_id),
    ('Foumban', 'Capitale du royaume Bamoun, musee royal, artisanat.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.7167, 10.8833, 'Bamoun', 95000, TRUE, cmr_id),
    ('Bangangte', 'Chef-lieu du departement du Nde.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.1500, 10.5333, 'Medumba', 65000, TRUE, cmr_id),
    ('Bafang', 'Chef-lieu du departement du Haut-Nkam.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.1500, 10.1833, 'Fe''efe''e', 45000, TRUE, cmr_id),
    ('Foumbot', 'Ville du departement du Noun, agriculture maraichere.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.5167, 10.6333, 'Bamoun', 40000, TRUE, cmr_id),
    ('Bazou', 'Village Bamileke du departement du Nde.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.0667, 10.4667, 'Medumba', 15000, TRUE, cmr_id),
    ('Bana', 'Village Bamileke du departement du Haut-Nkam.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.1333, 10.0667, 'Fe''efe''e', 12000, TRUE, cmr_id),
    ('Baham', 'Chefferie traditionnelle Bamileke du departement des Hauts-Plateaux.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.3333, 10.3500, 'Ghomala', 20000, TRUE, cmr_id),
    ('Batie', 'Chef-lieu du departement des Hauts-Plateaux.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.2833, 10.3000, 'Yemba', 25000, TRUE, cmr_id),
    ('Penka-Michel', 'Commune Bamileke du departement de la Menoua.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.4833, 10.0500, 'Fe''efe''e', 15000, TRUE, cmr_id),
    ('Banganfoumbi', 'Village Bamileke du departement du Nde.', 'CMR', 'Ouest', 'AF-CENTRAL', 5.1167, 10.5000, 'Medumba', 8000, TRUE, cmr_id),

    -- ── REGION NORD-OUEST ──
    ('Bamenda', 'Capital de la region du Nord-Ouest, coeur anglophone.', 'CMR', 'Nord-Ouest', 'AF-CENTRAL', 5.9597, 10.1597, 'Pidgin/Ngemba', 400000, TRUE, cmr_id),
    ('Kumbo', 'Chef-lieu du departement du Bui, chefferie Nso.', 'CMR', 'Nord-Ouest', 'AF-CENTRAL', 6.2000, 10.6833, 'Lamnso', 80000, TRUE, cmr_id),
    ('Wum', 'Chef-lieu du departement du Menchum.', 'CMR', 'Nord-Ouest', 'AF-CENTRAL', 6.3833, 10.0667, 'Aghem', 35000, TRUE, cmr_id),
    ('Nkambe', 'Chef-lieu du departement du Donga-Mantung.', 'CMR', 'Nord-Ouest', 'AF-CENTRAL', 6.5833, 10.6667, 'Yamba', 30000, TRUE, cmr_id),
    ('Ndop', 'Chef-lieu du departement du Ngo-Ketunjia, riziculture.', 'CMR', 'Nord-Ouest', 'AF-CENTRAL', 5.9667, 10.4000, 'Bamunka', 40000, TRUE, cmr_id),
    ('Fundong', 'Chef-lieu du departement du Boyo.', 'CMR', 'Nord-Ouest', 'AF-CENTRAL', 6.2500, 10.2667, 'Kom', 25000, TRUE, cmr_id),
    ('Bali', 'Chefferie Bali-Nyonga du departement du Mezam.', 'CMR', 'Nord-Ouest', 'AF-CENTRAL', 5.8833, 10.0167, 'Mungaka', 20000, TRUE, cmr_id),
    ('Bafut', 'Chefferie traditionnelle Bafut, patrimoine culturel.', 'CMR', 'Nord-Ouest', 'AF-CENTRAL', 6.0833, 10.1000, 'Bafut', 25000, TRUE, cmr_id),
    ('Mbengwi', 'Chef-lieu du departement du Momo.', 'CMR', 'Nord-Ouest', 'AF-CENTRAL', 6.0167, 9.8833, 'Meta', 20000, TRUE, cmr_id),
    ('Jakiri', 'Ville du departement du Bui.', 'CMR', 'Nord-Ouest', 'AF-CENTRAL', 6.1000, 10.6500, 'Lamnso', 15000, TRUE, cmr_id),

    -- ── REGION SUD-OUEST ──
    ('Buea', 'Capital de la region du Sud-Ouest, pied du mont Cameroun.', 'CMR', 'Sud-Ouest', 'AF-CENTRAL', 4.1597, 9.2333, 'Bakweri', 90000, TRUE, cmr_id),
    ('Limbe', 'Ville cotiere, ancienne Victoria, plages de sable noir.', 'CMR', 'Sud-Ouest', 'AF-CENTRAL', 4.0167, 9.2167, 'Bakweri', 85000, TRUE, cmr_id),
    ('Kumba', 'Plus grande ville du Sud-Ouest, centre commercial.', 'CMR', 'Sud-Ouest', 'AF-CENTRAL', 4.6333, 9.4500, 'Bakossi', 150000, TRUE, cmr_id),
    ('Mamfe', 'Chef-lieu du departement du Manyu, pres du Nigeria.', 'CMR', 'Sud-Ouest', 'AF-CENTRAL', 5.7667, 9.3167, 'Ejagham', 35000, TRUE, cmr_id),
    ('Tiko', 'Ville portuaire et agricole du departement du Fako.', 'CMR', 'Sud-Ouest', 'AF-CENTRAL', 4.0750, 9.3583, 'Pidgin', 50000, TRUE, cmr_id),
    ('Mudemba', 'Chef-lieu du departement du Ndian.', 'CMR', 'Sud-Ouest', 'AF-CENTRAL', 4.9500, 9.0333, 'Oroko', 15000, TRUE, cmr_id),
    ('Mundemba', 'Ville du departement du Ndian, pres du parc de Korup.', 'CMR', 'Sud-Ouest', 'AF-CENTRAL', 4.9667, 8.8833, 'Oroko', 10000, TRUE, cmr_id),
    ('Fontem', 'Chef-lieu du departement du Lebialem.', 'CMR', 'Sud-Ouest', 'AF-CENTRAL', 5.4833, 9.8833, 'Bangwa', 15000, TRUE, cmr_id),
    ('Tombel', 'Chef-lieu du departement du Kupe-Muanenguba.', 'CMR', 'Sud-Ouest', 'AF-CENTRAL', 4.7500, 9.6667, 'Bakossi', 20000, TRUE, cmr_id),
    ('Ekondo-Titi', 'Ville du departement du Ndian.', 'CMR', 'Sud-Ouest', 'AF-CENTRAL', 4.6500, 8.9833, 'Oroko', 12000, TRUE, cmr_id),

    -- ── REGION SUD ──
    ('Ebolowa', 'Capital de la region du Sud, terre Boulou.', 'CMR', 'Sud', 'AF-CENTRAL', 2.9000, 11.1500, 'Boulou', 90000, TRUE, cmr_id),
    ('Kribi', 'Station balneaire, port en eau profonde.', 'CMR', 'Sud', 'AF-CENTRAL', 2.9500, 9.9167, 'Batanga', 60000, TRUE, cmr_id),
    ('Ambam', 'Chef-lieu du departement de la Vallee-du-Ntem, frontiere Gabon.', 'CMR', 'Sud', 'AF-CENTRAL', 2.3833, 11.2833, 'Ntumu', 25000, TRUE, cmr_id),
    ('Lolodorf', 'Chef-lieu du departement de l''Ocean.', 'CMR', 'Sud', 'AF-CENTRAL', 3.2333, 10.7333, 'Bassa/Ngoumba', 12000, TRUE, cmr_id),
    ('Campo', 'Ville frontiere avec la Guinee equatoriale, parc national.', 'CMR', 'Sud', 'AF-CENTRAL', 2.3667, 9.8333, 'Mvae', 8000, TRUE, cmr_id),
    ('Mvangan', 'Chef-lieu du departement du Dja-et-Lobo.', 'CMR', 'Sud', 'AF-CENTRAL', 2.7500, 11.5500, 'Boulou', 10000, TRUE, cmr_id),
    ('Akom-II', 'Ville du departement de l''Ocean.', 'CMR', 'Sud', 'AF-CENTRAL', 2.7833, 10.5833, 'Boulou', 8000, TRUE, cmr_id),
    ('Djoum', 'Chef-lieu du departement du Dja-et-Lobo.', 'CMR', 'Sud', 'AF-CENTRAL', 2.6667, 12.6667, 'Boulou', 12000, TRUE, cmr_id),
    ('Mintom', 'Village du departement du Dja-et-Lobo, foret dense.', 'CMR', 'Sud', 'AF-CENTRAL', 2.4167, 13.0000, 'Baka', 5000, TRUE, cmr_id),

    -- ── REGION EST ──
    ('Bertoua', 'Capital de la region de l''Est, carrefour vers la Centrafrique.', 'CMR', 'Est', 'AF-CENTRAL', 4.5833, 13.6833, 'Gbaya', 120000, TRUE, cmr_id),
    ('Batouri', 'Chef-lieu du departement de la Kadey.', 'CMR', 'Est', 'AF-CENTRAL', 4.4333, 14.3667, 'Gbaya', 40000, TRUE, cmr_id),
    ('Yokadouma', 'Chef-lieu du departement de la Boumba-et-Ngoko.', 'CMR', 'Est', 'AF-CENTRAL', 3.5167, 15.0500, 'Baka', 25000, TRUE, cmr_id),
    ('Abong-Mbang', 'Chef-lieu du departement du Haut-Nyong.', 'CMR', 'Est', 'AF-CENTRAL', 3.9833, 13.1833, 'Maka', 20000, TRUE, cmr_id),
    ('Lomie', 'Chef-lieu du departement du Haut-Nyong, terre Baka.', 'CMR', 'Est', 'AF-CENTRAL', 3.1500, 13.6167, 'Baka', 12000, TRUE, cmr_id),
    ('Moloundou', 'Ville du departement de la Boumba-et-Ngoko, frontiere Congo.', 'CMR', 'Est', 'AF-CENTRAL', 2.0500, 15.2167, 'Baka', 8000, TRUE, cmr_id),
    ('Garoua-Boulai', 'Chef-lieu du departement du Lom-et-Djerem, frontiere Centrafrique.', 'CMR', 'Est', 'AF-CENTRAL', 5.8833, 14.5500, 'Gbaya', 30000, TRUE, cmr_id),
    ('Belabo', 'Ville ferroviaire du departement du Lom-et-Djerem.', 'CMR', 'Est', 'AF-CENTRAL', 4.9333, 13.3000, 'Gbaya', 15000, TRUE, cmr_id),
    ('Doume', 'Chef-lieu de l''arrondissement de Doume, departement du Haut-Nyong.', 'CMR', 'Est', 'AF-CENTRAL', 4.2333, 13.4500, 'Maka', 10000, TRUE, cmr_id),
    ('Kentzou', 'Village frontiere du departement de la Kadey.', 'CMR', 'Est', 'AF-CENTRAL', 4.1167, 14.6833, 'Gbaya', 5000, TRUE, cmr_id),

    -- ── REGION ADAMAOUA ──
    ('Ngaoundere', 'Capital de la region de l''Adamaoua, porte du Grand Nord.', 'CMR', 'Adamaoua', 'AF-CENTRAL', 7.3167, 13.5833, 'Fulfude', 250000, TRUE, cmr_id),
    ('Meiganga', 'Chef-lieu du departement du Mbere.', 'CMR', 'Adamaoua', 'AF-CENTRAL', 6.5167, 14.2833, 'Gbaya', 45000, TRUE, cmr_id),
    ('Tibati', 'Chef-lieu du departement du Djerem.', 'CMR', 'Adamaoua', 'AF-CENTRAL', 6.4667, 12.6333, 'Fulfude', 30000, TRUE, cmr_id),
    ('Banyo', 'Chef-lieu du departement du Mayo-Banyo.', 'CMR', 'Adamaoua', 'AF-CENTRAL', 6.7500, 11.8167, 'Fulfude', 25000, TRUE, cmr_id),
    ('Tignere', 'Chef-lieu du departement du Faro-et-Deo.', 'CMR', 'Adamaoua', 'AF-CENTRAL', 7.3667, 12.6500, 'Fulfude', 15000, TRUE, cmr_id),
    ('Djohong', 'Chef-lieu du departement du Mbere.', 'CMR', 'Adamaoua', 'AF-CENTRAL', 6.8333, 14.7000, 'Gbaya', 10000, TRUE, cmr_id),
    ('Dir', 'Village du departement du Faro-et-Deo.', 'CMR', 'Adamaoua', 'AF-CENTRAL', 7.5333, 13.0667, 'Fulfude', 5000, TRUE, cmr_id),

    -- ── REGION NORD ──
    ('Garoua', 'Capital de la region du Nord, ville de la Benoue.', 'CMR', 'Nord', 'AF-CENTRAL', 9.3000, 13.3833, 'Fulfude', 300000, TRUE, cmr_id),
    ('Guider', 'Chef-lieu du departement du Mayo-Louti.', 'CMR', 'Nord', 'AF-CENTRAL', 9.9333, 13.9500, 'Guiziga', 70000, TRUE, cmr_id),
    ('Tchollire', 'Chef-lieu du departement du Mayo-Rey.', 'CMR', 'Nord', 'AF-CENTRAL', 8.4000, 14.1667, 'Fulfude', 15000, TRUE, cmr_id),
    ('Poli', 'Chef-lieu du departement du Faro.', 'CMR', 'Nord', 'AF-CENTRAL', 8.4833, 13.2500, 'Fulfude', 12000, TRUE, cmr_id),
    ('Pitoa', 'Ville du departement de la Benoue.', 'CMR', 'Nord', 'AF-CENTRAL', 9.3833, 13.5333, 'Fulfude', 20000, TRUE, cmr_id),
    ('Figuil', 'Chef-lieu du departement du Mayo-Louti.', 'CMR', 'Nord', 'AF-CENTRAL', 9.7500, 13.9667, 'Guiziga', 15000, TRUE, cmr_id),
    ('Rey-Bouba', 'Lamidat historique du departement du Mayo-Rey.', 'CMR', 'Nord', 'AF-CENTRAL', 8.6667, 14.1833, 'Fulfude', 10000, TRUE, cmr_id),
    ('Lagdo', 'Ville du barrage hydroelectrique sur la Benoue.', 'CMR', 'Nord', 'AF-CENTRAL', 9.0500, 13.7333, 'Fulfude', 8000, TRUE, cmr_id),

    -- ── REGION EXTREME-NORD ──
    ('Maroua', 'Capital de la region de l''Extreme-Nord, artisanat et culture.', 'CMR', 'Extreme-Nord', 'AF-CENTRAL', 10.5910, 14.3159, 'Fulfude', 320000, TRUE, cmr_id),
    ('Kousseri', 'Ville frontiere avec le Tchad, departement du Logone-et-Chari.', 'CMR', 'Extreme-Nord', 'AF-CENTRAL', 12.0833, 15.0333, 'Arabe Shuwa', 90000, TRUE, cmr_id),
    ('Mokolo', 'Chef-lieu du departement du Mayo-Tsanaga.', 'CMR', 'Extreme-Nord', 'AF-CENTRAL', 10.7333, 13.8000, 'Mafa', 35000, TRUE, cmr_id),
    ('Mora', 'Chef-lieu du departement du Mayo-Sava.', 'CMR', 'Extreme-Nord', 'AF-CENTRAL', 11.0500, 14.1500, 'Wandala', 30000, TRUE, cmr_id),
    ('Yagoua', 'Chef-lieu du departement du Mayo-Danay, peche et riziculture.', 'CMR', 'Extreme-Nord', 'AF-CENTRAL', 10.3500, 15.2333, 'Massa', 40000, TRUE, cmr_id),
    ('Kaele', 'Chef-lieu du departement du Mayo-Kani.', 'CMR', 'Extreme-Nord', 'AF-CENTRAL', 10.1000, 14.4500, 'Mundang', 35000, TRUE, cmr_id),
    ('Moulvoudaye', 'Ville du departement du Mayo-Kani.', 'CMR', 'Extreme-Nord', 'AF-CENTRAL', 10.3833, 14.8167, 'Guiziga', 15000, TRUE, cmr_id),
    ('Waza', 'Ville du parc national de Waza, reserve animaliere.', 'CMR', 'Extreme-Nord', 'AF-CENTRAL', 11.4000, 14.5333, 'Kotoko', 10000, TRUE, cmr_id),
    ('Meri', 'Ville du departement du Diamare.', 'CMR', 'Extreme-Nord', 'AF-CENTRAL', 10.7500, 14.1167, 'Mofu', 25000, TRUE, cmr_id),
    ('Mindif', 'Ville du departement du Mayo-Kani.', 'CMR', 'Extreme-Nord', 'AF-CENTRAL', 10.4167, 14.4333, 'Mundang', 15000, TRUE, cmr_id)
    ON CONFLICT DO NOTHING;

END $$;
