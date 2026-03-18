package com.gwangmeu.genealogy.dto;

import lombok.*;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClanDTO {
    private UUID id;
    private String name;
    private UUID villageId;
    private String description;
    private long personCount;
}
