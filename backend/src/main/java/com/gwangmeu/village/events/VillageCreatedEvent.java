package com.gwangmeu.village.events;

import com.gwangmeu.shared.events.DomainEvent;

import java.util.UUID;

/**
 * Publie quand un nouveau village est cree.
 * Consomme par : search-module (indexation), geo-module (hierarchie), notification-module.
 */
public class VillageCreatedEvent extends DomainEvent {

    private final UUID villageId;
    private final String villageName;
    private final String country;

    public VillageCreatedEvent(UUID villageId, String villageName, String country) {
        super("village.created");
        this.villageId = villageId;
        this.villageName = villageName;
        this.country = country;
    }

    public UUID getVillageId() { return villageId; }
    public String getVillageName() { return villageName; }
    public String getCountry() { return country; }
}
