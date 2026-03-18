package com.gwangmeu.genealogy.events;

import java.util.UUID;

/**
 * Evenement publie quand une suggestion de lien genealogique est validee par un humain.
 * Consomme par le module ai/ pour affiner les suggestions futures.
 */
public record FamilyLinkValidatedEvent(UUID suggestionId) {}
