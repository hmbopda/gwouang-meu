package com.gwangmeu.village.domain;

/**
 * Type d'entree patrimoniale generique d'un village.
 *
 * <ul>
 *   <li>{@link #TRADITION} — traditions / coutumes du village.</li>
 *   <li>{@link #SACRED_PLACE} — lieux sacres.</li>
 *   <li>{@link #CALENDAR} — reperes du calendrier traditionnel.</li>
 *   <li>{@link #EVENT} — evenements de la vie du village (date libre dans subtitle).</li>
 *   <li>{@link #ANNOUNCEMENT} — annonces / communiques a la communaute.</li>
 * </ul>
 */
public enum HeritageKind {
    TRADITION,
    SACRED_PLACE,
    CALENDAR,
    EVENT,
    ANNOUNCEMENT
}
