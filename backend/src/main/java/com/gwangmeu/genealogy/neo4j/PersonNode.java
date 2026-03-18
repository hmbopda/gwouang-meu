package com.gwangmeu.genealogy.neo4j;

import lombok.*;
import org.springframework.data.neo4j.core.schema.*;

import java.util.ArrayList;
import java.util.List;

@Node("Person")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PersonNode {

    @Id
    @GeneratedValue
    private Long neoId;

    @Property("postgresId")
    private String postgresId;

    @Property("firstName")
    private String firstName;

    @Property("lastName")
    private String lastName;

    @Property("gender")
    private String gender;

    @Property("birthYear")
    private Integer birthYear;

    @Property("clan")
    private String clan;

    @Property("totem")
    private String totem;

    @Property("villageIds")
    private List<String> villageIds;

    @Property("isAlive")
    private Boolean isAlive;

    @Relationship(type = "PARENT_OF", direction = Relationship.Direction.OUTGOING)
    @Builder.Default
    private List<ParentOfRelationship> children = new ArrayList<>();

    @Relationship(type = "MARRIED_TO", direction = Relationship.Direction.OUTGOING)
    @Builder.Default
    private List<MarriedToRelationship> spouses = new ArrayList<>();
}
