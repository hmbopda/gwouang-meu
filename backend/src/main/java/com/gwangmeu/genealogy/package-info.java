/**
 * genealogy-module — Arbres familiaux, suggestions IA, plan geo-familles.
 * Dependances : Neo4j AuraDB, Claude API (via ai-module).
 *
 * IMPORTANT : Validation humaine TOUJOURS obligatoire avant enregistrement Claude.
 *
 * Modele Neo4j :
 *   (:Person)-[:ENFANT_DE]->(:Person)
 *   (:Person)-[:MARIE_A]->(:Person)
 *   (:Person)-[:MEMBRE_DE]->(:Village)
 *   (:Person)-[:APPARTIENT_AU_CLAN]->(:Clan)
 *   (:Family)-[:LOCALISEE_A {lat, lng}]->(:Village)
 *
 * Expose : GenealogyService.
 * Evenements publies : FamilyLinkSuggestedEvent, FamilyLinkValidatedEvent.
 */
@org.springframework.modulith.ApplicationModule(displayName = "Genealogy Module")
package com.gwangmeu.genealogy;
