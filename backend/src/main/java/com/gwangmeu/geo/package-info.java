/**
 * geo-module — Continent→Pays→Region→Village, groupes transversaux dialectes/cuisine.
 * Dependances : PostGIS (Supabase), cultural_link.
 *
 * Expose : GeoService.
 * Evenements publies : —
 * Evenements consommes : VillageCreatedEvent (mise a jour hierarchie).
 */
@org.springframework.modulith.ApplicationModule(displayName = "Geo Module")
package com.gwangmeu.geo;
