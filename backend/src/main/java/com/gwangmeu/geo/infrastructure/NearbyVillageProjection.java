package com.gwangmeu.geo.infrastructure;

import java.util.UUID;

/**
 * Projection Spring Data pour la requete native PostGIS ST_DWithin.
 * Retourne les champs village + la distance calculee en metres.
 */
public interface NearbyVillageProjection {
    UUID   getId();
    String getName();
    String getCountry();
    String getRegion();
    Double getLatitude();
    Double getLongitude();
    String getCoverImageUrl();
    String getPrimaryDialect();
    Integer getPopulationEstimate();
    /** Distance en metres depuis le point de reference. */
    Double getDistanceMeters();
}
