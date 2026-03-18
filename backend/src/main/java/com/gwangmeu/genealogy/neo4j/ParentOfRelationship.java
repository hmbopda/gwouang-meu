package com.gwangmeu.genealogy.neo4j;

import lombok.*;
import org.springframework.data.neo4j.core.schema.RelationshipId;
import org.springframework.data.neo4j.core.schema.RelationshipProperties;
import org.springframework.data.neo4j.core.schema.TargetNode;

@RelationshipProperties
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ParentOfRelationship {

    @RelationshipId
    private Long id;

    @TargetNode
    private PersonNode child;

    private String role;       // "FATHER" | "MOTHER"
    private String type;       // "BIOLOGICAL" | "ADOPTIVE" | "STEP" | "FOSTER"
    private Boolean isAdopted;
    private Double confidence;
}
