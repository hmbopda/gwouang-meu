package com.gwangmeu.genealogy.domain;

import jakarta.persistence.*;
import lombok.*;

import java.io.Serializable;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "person_clans")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@IdClass(PersonClan.PersonClanId.class)
public class PersonClan {

    @Id
    @Column(name = "person_id", nullable = false)
    private UUID personId;

    @Id
    @Column(name = "clan_id", nullable = false)
    private UUID clanId;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PersonClanId implements Serializable {
        private UUID personId;
        private UUID clanId;
    }
}
