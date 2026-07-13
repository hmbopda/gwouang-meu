package com.gwangmeu.village.domain;

/**
 * Type d'entree patrimoniale generique d'un village.
 *
 * <ul>
 *   <li>{@link #TRADITION} — traditions / coutumes du village.</li>
 *   <li>{@link #SACRED_PLACE} — lieux sacres.</li>
 *   <li>{@link #CALENDAR} — reperes du calendrier traditionnel.</li>
 * </ul>
 */
public enum HeritageKind {
    TRADITION,
    SACRED_PLACE,
    CALENDAR
}
