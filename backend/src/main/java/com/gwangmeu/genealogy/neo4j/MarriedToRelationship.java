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
public class MarriedToRelationship {

    @RelationshipId
    private Long id;

    @TargetNode
    private PersonNode wife;

    private String unionId;
    private Boolean isDotPaid;
    private Integer order;
    private Boolean isActive;
    private String unionType;
}
