package com.gwangmeu.genealogy.infrastructure;

import com.gwangmeu.genealogy.neo4j.PersonNode;
import org.springframework.data.neo4j.repository.Neo4jRepository;
import org.springframework.data.neo4j.repository.query.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PersonNodeRepository extends Neo4jRepository<PersonNode, Long> {

    Optional<PersonNode> findByPostgresId(String postgresId);

    @Query("""
        MATCH (parent:Person)-[:PARENT_OF]->(child:Person {postgresId: $postgresId})
        RETURN parent
    """)
    List<PersonNode> findParents(@Param("postgresId") String postgresId);

    @Query("""
        MATCH (parent:Person {postgresId: $postgresId})-[:PARENT_OF]->(child:Person)
        RETURN child
    """)
    List<PersonNode> findChildren(@Param("postgresId") String postgresId);

    @Query("""
        MATCH (parent:Person)-[:PARENT_OF]->(p:Person {postgresId: $postgresId})
        MATCH (parent)-[:PARENT_OF]->(sibling:Person)
        WHERE sibling.postgresId <> $postgresId
        RETURN DISTINCT sibling
    """)
    List<PersonNode> findSiblings(@Param("postgresId") String postgresId);

    @Query("""
        MATCH (gp:Person)-[:PARENT_OF*2]->(p:Person {postgresId: $postgresId})
        RETURN gp
    """)
    List<PersonNode> findGrandparents(@Param("postgresId") String postgresId);

    @Query("""
        MATCH (a:Person {postgresId: $postgresId})<-[:PARENT_OF*2]-(gp:Person)-[:PARENT_OF*2]->(cousin:Person)
        WHERE cousin.postgresId <> $postgresId
        RETURN DISTINCT cousin
    """)
    List<PersonNode> findFirstCousins(@Param("postgresId") String postgresId);

    @Query("""
        MATCH path = (ancestor:Person)-[:PARENT_OF*1..$depth]->(p:Person {postgresId: $postgresId})
        RETURN ancestor, length(path) AS generation
        ORDER BY generation
    """)
    List<PersonNode> findAncestors(@Param("postgresId") String postgresId, @Param("depth") int depth);

    @Query("""
        MATCH (ancestor:Person)-[:PARENT_OF*1..20]->(p:Person {postgresId: $postgresId})
        RETURN DISTINCT ancestor.postgresId
    """)
    List<String> findAncestorPostgresIds(@Param("postgresId") String postgresId);

    @Query("""
        MATCH path = (p:Person {postgresId: $postgresId})-[:PARENT_OF*1..$depth]->(descendant:Person)
        RETURN descendant, length(path) AS generation
        ORDER BY generation
    """)
    List<PersonNode> findDescendants(@Param("postgresId") String postgresId, @Param("depth") int depth);

    @Query("""
        MATCH (h:Person {postgresId: $husbandId})
              -[r:MARRIED_TO {isActive: true}]->(wife:Person)
        RETURN wife, r.order AS order, r.isDotPaid AS dotPaid
        ORDER BY r.order
    """)
    List<PersonNode> findActiveWives(@Param("husbandId") String husbandId);

    @Query("""
        MATCH (p:Person {postgresId: $postgresId})
        CALL {
            WITH p
            MATCH (ancestor:Person)-[:PARENT_OF*1..20]->(p)
            RETURN ancestor AS member
        UNION
            WITH p
            MATCH (p)-[:PARENT_OF*1..20]->(descendant:Person)
            RETURN descendant AS member
        UNION
            WITH p
            RETURN p AS member
        }
        RETURN DISTINCT member
    """)
    List<PersonNode> findFullTreeMembers(@Param("postgresId") String postgresId);

    @Query("""
        MATCH (a:Person {clan: $clan}), (b:Person {clan: $clan})
        WHERE a.postgresId <> b.postgresId
          AND NOT (a)-[:PARENT_OF|MARRIED_TO*1..4]-(b)
        RETURN a, b LIMIT 20
    """)
    List<PersonNode> findUnconnectedClanMembers(@Param("clan") String clan);
}
