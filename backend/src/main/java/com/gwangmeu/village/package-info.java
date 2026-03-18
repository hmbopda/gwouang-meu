/**
 * village-module — Pages villages, groupes, abonnements, hierarchie geographique.
 * Dependances : Follow/Join, Multi-pays.
 *
 * Expose : VillageService.
 * Evenements publies : VillageCreatedEvent, UserJoinedVillageEvent.
 * Evenements consommes : UserCreatedEvent (creation profil village).
 */
@org.springframework.modulith.ApplicationModule(displayName = "Village Module")
package com.gwangmeu.village;
