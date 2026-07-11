package com.gwangmeu.village.domain;

/**
 * Permissions delegables a un membre de village via un {@link VillageMemberRole}.
 * Stockees en base sous forme de liste CSV (colonne permissions VARCHAR).
 */
public enum VillagePermission {
    VALIDATE_MEMBERS,
    MODERATE_POSTS,
    VALIDATE_CULTURE,
    VALIDATE_SUCCESSION,
    MANAGE_ROLES,
    EDIT_VILLAGE
}
