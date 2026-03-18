# PROMPT CLAUDE CODE — GWANG MEU : Module Généalogie Complet
> **À copier-coller tel quel dans Claude Code (IntelliJ ou terminal)**
> Ce prompt implémente le `genealogy-module` complet : backend Java/Spring + Neo4j + Flutter + Claude AI

---

## ═══════════════════════════════════════════════════════════
## PROMPT PRINCIPAL — COPIEZ TOUT CE BLOC
## ═══════════════════════════════════════════════════════════

```
Tu travailles sur le projet GWANG MEU, une plateforme culturelle africaine.
Réfère-toi à ARCHITECTURE.md à la racine du projet pour le contexte global.

---

## MISSION
 regarde ce qui est deja fait à partir de ce document fait evoluer l'architecture afin d'avoir a la fin un arbre parfait, dynamique et structure
Implémente le `genealogy-module` complet selon les spécifications ci-dessous.
Ce module gère les arbres généalogiques avec :
- PostgreSQL (Supabase) pour les données structurées (identité, unions, dot)
- Neo4j AuraDB pour le graphe de relations (chemins, requêtes d'ancêtres, cousins)
- Claude AI (claude-sonnet-4-6) pour les suggestions de liens probables
- Flutter pour l'arbre interactif visuel

Commence TOUJOURS par créer les fichiers dans l'ordre suivant :
1. Migrations SQL (Flyway)
2. Enums Java
3. Entités PostgreSQL (JPA)
4. Entités Neo4j (Spring Data Neo4j)
5. Repositories
6. Domain Events
7. Services
8. Controllers REST
9. Flutter — Modèles Dart
10. Flutter — Service API
11. Flutter — Widget arbre interactif
12. Tests JUnit 5 + Testcontainers

---

## PARTIE 1 — MIGRATIONS FLYWAY (PostgreSQL / Supabase)

Crée les fichiers Flyway dans `backend/src/main/resources/db/migration/`.

### Fichier : V10__genealogy_enums.sql
```sql
-- Enums domaine généalogique
CREATE TYPE gender_enum AS ENUM ('MALE', 'FEMALE', 'OTHER');
CREATE TYPE person_status_enum AS ENUM ('CONFIRMED', 'PENDING', 'SUGGESTED_BY_AI');
CREATE TYPE privacy_enum AS ENUM ('PUBLIC', 'MEMBERS_ONLY', 'FAMILY_ONLY');
CREATE TYPE parent_role_enum AS ENUM ('FATHER', 'MOTHER');
CREATE TYPE parent_type_enum AS ENUM ('BIOLOGICAL', 'ADOPTIVE', 'STEP', 'FOSTER');
CREATE TYPE union_type_enum AS ENUM ('DOT', 'CIVIL', 'RELIGIOUS', 'TRADITIONAL', 'CONCUBINAGE');
CREATE TYPE end_reason_enum AS ENUM ('DEATH', 'DIVORCE', 'SEPARATION', 'ANNULMENT');
CREATE TYPE sibling_type_enum AS ENUM ('FULL', 'HALF_PATERNAL', 'HALF_MATERNAL', 'STEP');
CREATE TYPE relation_source_enum AS ENUM ('DECLARED', 'AI_SUGGESTED', 'IMPORTED', 'ADMIN');
CREATE TYPE ai_suggestion_status_enum AS ENUM ('PENDING', 'ACCEPTED', 'REJECTED', 'EXPIRED');
CREATE TYPE guard_type_enum AS ENUM ('GODPARENT', 'TUTOR', 'FOSTER_PARENT', 'CLAN_CHIEF');
```

### Fichier : V11__genealogy_persons.sql
```sql
CREATE TABLE persons (
    id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id           UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    village_id        UUID REFERENCES villages(id) ON DELETE SET NULL,

    -- Identité
    first_name        VARCHAR(100) NOT NULL,
    last_name         VARCHAR(100) NOT NULL,
    maiden_name       VARCHAR(100),
    gender            gender_enum NOT NULL,
    birth_date        DATE,
    birth_place       VARCHAR(200),
    death_date        DATE,

    -- Culture
    clan              VARCHAR(100),
    totem             VARCHAR(100),
    native_language   VARCHAR(50),
    religion          VARCHAR(80),
    profession        VARCHAR(120),
    biography         TEXT,
    photo_url         TEXT,

    -- Système
    privacy           privacy_enum NOT NULL DEFAULT 'FAMILY_ONLY',
    status            person_status_enum NOT NULL DEFAULT 'PENDING',
    neo4j_node_id     VARCHAR(100) UNIQUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by        UUID NOT NULL REFERENCES auth.users(id)
);

-- Index
CREATE INDEX idx_persons_village ON persons(village_id);
CREATE INDEX idx_persons_user ON persons(user_id);
CREATE INDEX idx_persons_clan ON persons(clan);
CREATE INDEX idx_persons_status ON persons(status);

-- RLS Supabase
ALTER TABLE persons ENABLE ROW LEVEL SECURITY;

-- Lecture : PUBLIC ou MEMBERS (si membre du village) ou FAMILY (si lié à la personne)
CREATE POLICY "persons_select" ON persons FOR SELECT
  USING (
    privacy = 'PUBLIC'
    OR (privacy = 'MEMBERS_ONLY' AND auth.uid() IS NOT NULL)
    OR (privacy = 'FAMILY_ONLY' AND auth.uid() = created_by)
  );

-- Insertion : utilisateurs authentifiés uniquement
CREATE POLICY "persons_insert" ON persons FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- Mise à jour : créateur ou admin/moderateur
CREATE POLICY "persons_update" ON persons FOR UPDATE
  USING (auth.uid() = created_by);
```

### Fichier : V12__genealogy_relations.sql
```sql
-- Table de filiation parent-enfant
CREATE TABLE parent_child (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id   UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    child_id    UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    parent_role parent_role_enum NOT NULL,
    parent_type parent_type_enum NOT NULL DEFAULT 'BIOLOGICAL',
    is_adopted  BOOLEAN NOT NULL DEFAULT FALSE,
    confidence  DECIMAL(3,2),           -- Score IA 0.00–1.00 si AI_SUGGESTED
    source      relation_source_enum NOT NULL DEFAULT 'DECLARED',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by  UUID NOT NULL REFERENCES auth.users(id),

    UNIQUE(parent_id, child_id)         -- Un seul lien par paire
);

-- Un enfant ne peut avoir qu'un FATHER et qu'une MOTHER biologiques
CREATE UNIQUE INDEX idx_parent_child_bio_father
  ON parent_child(child_id) WHERE parent_role = 'FATHER' AND parent_type = 'BIOLOGICAL';
CREATE UNIQUE INDEX idx_parent_child_bio_mother
  ON parent_child(child_id) WHERE parent_role = 'MOTHER' AND parent_type = 'BIOLOGICAL';

CREATE INDEX idx_parent_child_parent ON parent_child(parent_id);
CREATE INDEX idx_parent_child_child  ON parent_child(child_id);

-- Table des unions (mariage / dot)
CREATE TABLE unions (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    husband_id       UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    wife_id          UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    union_type       union_type_enum NOT NULL,
    union_order      SMALLINT NOT NULL DEFAULT 1,    -- 1=1ère épouse, 2=2ème...
    start_date       DATE,
    end_date         DATE,
    end_reason       end_reason_enum,
    is_active        BOOLEAN GENERATED ALWAYS AS (end_date IS NULL) STORED,

    -- Dot (bride price)
    is_dot_paid      BOOLEAN NOT NULL DEFAULT FALSE,
    dot_date         DATE,
    dot_paid_by      UUID REFERENCES persons(id) ON DELETE SET NULL,
    dot_description  TEXT,                           -- Biens donnés
    dot_witnesses    UUID[],                         -- Array de person IDs témoins

    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by       UUID NOT NULL REFERENCES auth.users(id)
);

CREATE INDEX idx_unions_husband ON unions(husband_id);
CREATE INDEX idx_unions_wife    ON unions(wife_id);
CREATE INDEX idx_unions_active  ON unions(is_active) WHERE is_active = TRUE;

-- Cache frères/sœurs (table dérivée, mise à jour par trigger)
CREATE TABLE siblings (
    person_a_id    UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    person_b_id    UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    sibling_type   sibling_type_enum NOT NULL,
    shared_parents SMALLINT NOT NULL DEFAULT 1,      -- 1=demi, 2=plein
    PRIMARY KEY(person_a_id, person_b_id),
    CHECK(person_a_id < person_b_id)                 -- évite doublons symétriques
);

-- Tutelle / Parrainage
CREATE TABLE guardianships (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guardian_id  UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    ward_id      UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    guard_type   guard_type_enum NOT NULL,
    start_date   DATE,
    end_date     DATE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Suggestions Claude AI
CREATE TABLE ai_genealogy_suggestions (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_a_id        UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    person_b_id        UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
    suggested_relation VARCHAR(50) NOT NULL,          -- ex: 'FATHER', 'COUSIN_1ST'
    confidence         DECIMAL(3,2) NOT NULL,
    reasons            JSONB,                         -- Tableau de strings expliquant la suggestion
    status             ai_suggestion_status_enum NOT NULL DEFAULT 'PENDING',
    reviewed_by        UUID REFERENCES auth.users(id),
    reviewed_at        TIMESTAMPTZ,
    expires_at         TIMESTAMPTZ DEFAULT NOW() + INTERVAL '90 days',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_sugg_status ON ai_genealogy_suggestions(status);
CREATE INDEX idx_ai_sugg_person_a ON ai_genealogy_suggestions(person_a_id);
```

### Fichier : V13__genealogy_sibling_trigger.sql
```sql
-- Trigger qui recalcule automatiquement la table siblings
-- quand un lien parent_child est inséré ou supprimé

CREATE OR REPLACE FUNCTION refresh_siblings()
RETURNS TRIGGER AS $$
DECLARE
    v_child_id UUID;
BEGIN
    v_child_id := CASE WHEN TG_OP = 'DELETE' THEN OLD.child_id ELSE NEW.child_id END;

    -- Supprime les anciens siblings de cet enfant
    DELETE FROM siblings WHERE person_a_id = v_child_id OR person_b_id = v_child_id;

    -- Recalcule : tous les enfants qui partagent au moins un parent avec v_child_id
    INSERT INTO siblings(person_a_id, person_b_id, sibling_type, shared_parents)
    SELECT
        LEAST(v_child_id, pc2.child_id),
        GREATEST(v_child_id, pc2.child_id),
        CASE COUNT(DISTINCT pc1.parent_id)
            WHEN 2 THEN 'FULL'::sibling_type_enum
            ELSE (
                SELECT CASE
                    WHEN pr.parent_role = 'FATHER' THEN 'HALF_PATERNAL'
                    ELSE 'HALF_MATERNAL'
                END
                FROM parent_child pr
                WHERE pr.child_id = v_child_id
                  AND pr.parent_id = pc1.parent_id
                LIMIT 1
            )::sibling_type_enum
        END,
        COUNT(DISTINCT pc1.parent_id)::SMALLINT
    FROM parent_child pc1
    JOIN parent_child pc2 ON pc1.parent_id = pc2.parent_id
    WHERE pc1.child_id = v_child_id
      AND pc2.child_id != v_child_id
    GROUP BY pc2.child_id
    ON CONFLICT (person_a_id, person_b_id) DO UPDATE
      SET sibling_type = EXCLUDED.sibling_type,
          shared_parents = EXCLUDED.shared_parents;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_refresh_siblings
AFTER INSERT OR DELETE ON parent_child
FOR EACH ROW EXECUTE FUNCTION refresh_siblings();
```

---

## PARTIE 2 — ENUMS JAVA

Crée ces enums dans `backend/src/main/java/com/gwangmeu/genealogy/domain/enums/` :

```java
// GenderEnum.java
package com.gwangmeu.genealogy.domain.enums;
public enum GenderEnum { MALE, FEMALE, OTHER }

// PersonStatusEnum.java
public enum PersonStatusEnum { CONFIRMED, PENDING, SUGGESTED_BY_AI }

// PrivacyEnum.java
public enum PrivacyEnum { PUBLIC, MEMBERS_ONLY, FAMILY_ONLY }

// ParentRoleEnum.java
public enum ParentRoleEnum { FATHER, MOTHER }

// ParentTypeEnum.java
public enum ParentTypeEnum { BIOLOGICAL, ADOPTIVE, STEP, FOSTER }

// UnionTypeEnum.java
public enum UnionTypeEnum { DOT, CIVIL, RELIGIOUS, TRADITIONAL, CONCUBINAGE }

// EndReasonEnum.java
public enum EndReasonEnum { DEATH, DIVORCE, SEPARATION, ANNULMENT }

// SiblingTypeEnum.java
public enum SiblingTypeEnum { FULL, HALF_PATERNAL, HALF_MATERNAL, STEP }

// RelationSourceEnum.java
public enum RelationSourceEnum { DECLARED, AI_SUGGESTED, IMPORTED, ADMIN }

// AiSuggestionStatusEnum.java
public enum AiSuggestionStatusEnum { PENDING, ACCEPTED, REJECTED, EXPIRED }

// GuardTypeEnum.java
public enum GuardTypeEnum { GODPARENT, TUTOR, FOSTER_PARENT, CLAN_CHIEF }
```

---

## PARTIE 3 — ENTITÉS JPA (PostgreSQL)

Package : `com.gwangmeu.genealogy.domain`

### Person.java
```java
@Entity
@Table(name = "persons")
@EntityListeners(AuditingEntityListener.class)
public class Person {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "village_id")
    private UUID villageId;

    // Identité
    @Column(name = "first_name", nullable = false, length = 100)
    private String firstName;

    @Column(name = "last_name", nullable = false, length = 100)
    private String lastName;

    @Column(name = "maiden_name", length = 100)
    private String maidenName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private GenderEnum gender;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "birth_place", length = 200)
    private String birthPlace;

    @Column(name = "death_date")
    private LocalDate deathDate;

    // Culture
    @Column(length = 100)
    private String clan;

    @Column(length = 100)
    private String totem;

    @Column(name = "native_language", length = 50)
    private String nativeLanguage;

    @Column(length = 80)
    private String religion;

    @Column(length = 120)
    private String profession;

    @Column(columnDefinition = "TEXT")
    private String biography;

    @Column(name = "photo_url", columnDefinition = "TEXT")
    private String photoUrl;

    // Système
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PrivacyEnum privacy = PrivacyEnum.FAMILY_ONLY;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private PersonStatusEnum status = PersonStatusEnum.PENDING;

    @Column(name = "neo4j_node_id", unique = true, length = 100)
    private String neo4jNodeId;

    @CreatedDate
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @LastModifiedDate
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "created_by", nullable = false, updatable = false)
    private UUID createdBy;

    // Computed
    @Transient
    public boolean isAlive() {
        return this.deathDate == null;
    }
}
```

### Union.java
Inclure tous les champs de la table `unions` (husbandId, wifeId, unionType, unionOrder, startDate, endDate, endReason, isDotPaid, dotDate, dotPaidBy, dotDescription, dotWitnesses en tant que `@Type(JsonType.class) List<UUID>`).

### ParentChild.java
Inclure : parentId, childId, parentRole, parentType, isAdopted, confidence, source.

### AiGenealogysuggestion.java
Inclure : personAId, personBId, suggestedRelation, confidence, reasons (JSONB via `@Type(JsonType.class) List<String>`), status, reviewedBy, reviewedAt, expiresAt.

---

## PARTIE 4 — ENTITÉ NEO4J

Package : `com.gwangmeu.genealogy.neo4j`

### PersonNode.java
```java
@Node("Person")
public class PersonNode {

    @Id
    @GeneratedValue
    private Long neoId;

    // Miroir de l'UUID PostgreSQL
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

    @Property("villageId")
    private String villageId;

    @Property("isAlive")
    private Boolean isAlive;

    // Relations sortantes
    @Relationship(type = "PARENT_OF", direction = Relationship.Direction.OUTGOING)
    private List<ParentOfRelationship> children = new ArrayList<>();

    @Relationship(type = "MARRIED_TO", direction = Relationship.Direction.OUTGOING)
    private List<MarriedToRelationship> spouses = new ArrayList<>();
}
```

### ParentOfRelationship.java (relation avec propriétés)
```java
@RelationshipProperties
public class ParentOfRelationship {

    @RelationshipId
    private Long id;

    @TargetNode
    private PersonNode child;

    private String role;       // "FATHER" | "MOTHER"
    private String type;       // "BIOLOGICAL" | "ADOPTIVE" | "STEP" | "FOSTER"
    private Boolean isAdopted;
    private Double confidence; // Score IA si AI_SUGGESTED
}
```

### MarriedToRelationship.java (relation avec propriétés)
```java
@RelationshipProperties
public class MarriedToRelationship {

    @RelationshipId
    private Long id;

    @TargetNode
    private PersonNode wife;

    private String unionId;     // UUID de la table unions PostgreSQL
    private Boolean isDotPaid;
    private Integer order;      // 1=1ère épouse, 2=2ème...
    private Boolean isActive;
    private String unionType;
}
```

---

## PARTIE 5 — REPOSITORIES

### PersonRepository.java (JPA)
```java
@Repository
public interface PersonRepository extends JpaRepository<Person, UUID> {
    List<Person> findByVillageId(UUID villageId);
    List<Person> findByVillageIdAndClan(UUID villageId, String clan);
    List<Person> findByCreatedBy(UUID userId);
    Optional<Person> findByNeo4jNodeId(String neo4jNodeId);
    Page<Person> findByVillageIdAndStatus(UUID villageId, PersonStatusEnum status, Pageable pageable);
}
```

### ParentChildRepository.java (JPA)
```java
@Repository
public interface ParentChildRepository extends JpaRepository<ParentChild, UUID> {
    List<ParentChild> findByParentId(UUID parentId);
    List<ParentChild> findByChildId(UUID childId);
    Optional<ParentChild> findByChildIdAndParentRole(UUID childId, ParentRoleEnum role);
    boolean existsByParentIdAndChildId(UUID parentId, UUID childId);
}
```

### UnionRepository.java (JPA)
```java
@Repository
public interface UnionRepository extends JpaRepository<Union, UUID> {
    List<Union> findByHusbandId(UUID husbandId);
    List<Union> findByWifeId(UUID wifeId);

    @Query("SELECT u FROM Union u WHERE u.husbandId = :husbandId AND u.endDate IS NULL")
    List<Union> findActiveUnionsByHusband(UUID husbandId);

    @Query("SELECT COUNT(u) FROM Union u WHERE u.husbandId = :husbandId AND u.endDate IS NULL")
    long countActiveWivesByHusband(UUID husbandId);
}
```

### PersonNodeRepository.java (Neo4j)
```java
@Repository
public interface PersonNodeRepository extends Neo4jRepository<PersonNode, Long> {

    Optional<PersonNode> findByPostgresId(String postgresId);

    // Parents directs (nœuds qui ont une relation PARENT_OF vers cette personne)
    @Query("""
        MATCH (parent:Person)-[:PARENT_OF]->(child:Person {postgresId: $postgresId})
        RETURN parent
    """)
    List<PersonNode> findParents(String postgresId);

    // Enfants directs
    @Query("""
        MATCH (parent:Person {postgresId: $postgresId})-[:PARENT_OF]->(child:Person)
        RETURN child
    """)
    List<PersonNode> findChildren(String postgresId);

    // Frères/sœurs (parent commun)
    @Query("""
        MATCH (parent:Person)-[:PARENT_OF]->(p:Person {postgresId: $postgresId})
        MATCH (parent)-[:PARENT_OF]->(sibling:Person)
        WHERE sibling.postgresId <> $postgresId
        RETURN DISTINCT sibling
    """)
    List<PersonNode> findSiblings(String postgresId);

    // Grand-parents (profondeur 2)
    @Query("""
        MATCH (gp:Person)-[:PARENT_OF*2]->(p:Person {postgresId: $postgresId})
        RETURN gp
    """)
    List<PersonNode> findGrandparents(String postgresId);

    // Cousins au 1er degré (grand-parent commun)
    @Query("""
        MATCH (a:Person {postgresId: $postgresId})<-[:PARENT_OF*2]-(gp:Person)-[:PARENT_OF*2]->(cousin:Person)
        WHERE cousin.postgresId <> $postgresId
        RETURN DISTINCT cousin, gp AS commonAncestor
    """)
    List<PersonNode> findFirstCousins(String postgresId);

    // Tous ancêtres jusqu'à profondeur N
    @Query("""
        MATCH path = (ancestor:Person)-[:PARENT_OF*1..$depth]->(p:Person {postgresId: $postgresId})
        RETURN ancestor, length(path) AS generation
        ORDER BY generation
    """)
    List<PersonNode> findAncestors(String postgresId, int depth);

    // Tous descendants
    @Query("""
        MATCH path = (p:Person {postgresId: $postgresId})-[:PARENT_OF*1..$depth]->(descendant:Person)
        RETURN descendant, length(path) AS generation
        ORDER BY generation
    """)
    List<PersonNode> findDescendants(String postgresId, int depth);

    // Épouses actives
    @Query("""
        MATCH (h:Person {postgresId: $husbandId, gender: 'MALE'})
              -[r:MARRIED_TO {isActive: true}]->(wife:Person)
        RETURN wife, r.order AS order, r.isDotPaid AS dotPaid
        ORDER BY r.order
    """)
    List<PersonNode> findActiveWives(String husbandId);

    // Arbre complet (ancêtres + descendants) pour affichage Flutter
    @Query("""
        CALL {
            MATCH path = (anc:Person)-[:PARENT_OF*]->(p:Person {postgresId: $postgresId})
            RETURN nodes(path) AS treeNodes, relationships(path) AS treeRels
        UNION ALL
            MATCH path = (p:Person {postgresId: $postgresId})-[:PARENT_OF*]->(desc:Person)
            RETURN nodes(path) AS treeNodes, relationships(path) AS treeRels
        }
        RETURN treeNodes, treeRels
    """)
    List<Map<String, Object>> findFullTree(String postgresId);

    // Candidats IA : même clan, sans lien connu (pour suggestions Claude)
    @Query("""
        MATCH (a:Person {clan: $clan}), (b:Person {clan: $clan})
        WHERE a.postgresId <> b.postgresId
          AND NOT (a)-[:PARENT_OF|MARRIED_TO*1..4]-(b)
        RETURN a, b LIMIT 20
    """)
    List<PersonNode> findUnconnectedClanMembers(String clan);
}
```

---

## PARTIE 6 — DOMAIN EVENTS

Package : `com.gwangmeu.genealogy.events`

Crée ces classes extends `DomainEvent` (shared-kernel) :

```java
// PersonCreatedEvent.java
public record PersonCreatedEvent(UUID personId, UUID villageId, UUID createdBy) {}

// PersonUpdatedEvent.java
public record PersonUpdatedEvent(UUID personId, UUID villageId) {}

// ParentChildLinkedEvent.java
public record ParentChildLinkedEvent(UUID parentId, UUID childId, ParentRoleEnum role, RelationSourceEnum source) {}

// UnionCreatedEvent.java
public record UnionCreatedEvent(UUID husbandId, UUID wifeId, UUID unionId, boolean isDotPaid) {}

// UnionDotPaidEvent.java
public record UnionDotPaidEvent(UUID unionId, UUID husbandId, UUID wifeId, UUID paidBy) {}

// AiSuggestionAcceptedEvent.java
public record AiSuggestionAcceptedEvent(UUID suggestionId, UUID personAId, UUID personBId, String relation) {}
```

Ces events seront écoutés par :
- `notification-module` → notifier les membres concernés
- `search-module` → réindexer la personne dans Meilisearch
- `feed-module` → créer un post "Nouvelle connexion généalogique" si public

---

## PARTIE 7 — SERVICES

### GenealogyService.java

Implémente ces méthodes (une par une, avec Javadoc) :

```java
@Service
@Transactional
public class GenealogyService {

    // ── PERSONS ────────────────────────────────────────────────────
    PersonDTO createPerson(CreatePersonRequest req, UUID createdBy);
    PersonDTO updatePerson(UUID personId, UpdatePersonRequest req, UUID requestedBy);
    PersonDTO getPersonById(UUID personId);
    Page<PersonDTO> getPersonsByVillage(UUID villageId, Pageable pageable);
    void deletePerson(UUID personId, UUID requestedBy);

    // ── FILIATION ──────────────────────────────────────────────────
    ParentChildDTO linkParentChild(UUID parentId, UUID childId, ParentRoleEnum role, ParentTypeEnum type, UUID createdBy);
    // Règle : un enfant ne peut avoir qu'un seul père et une seule mère biologiques
    // Si doublé : lever IllegalStateException avec message clair
    void unlinkParentChild(UUID parentId, UUID childId, UUID requestedBy);

    // ── UNIONS ─────────────────────────────────────────────────────
    UnionDTO createUnion(CreateUnionRequest req, UUID createdBy);
    UnionDTO updateDotStatus(UUID unionId, UpdateDotRequest req, UUID requestedBy);
    void endUnion(UUID unionId, EndUnionRequest req, UUID requestedBy);
    List<UnionDTO> getUnionsByPerson(UUID personId);

    // ── ARBRE ──────────────────────────────────────────────────────
    FamilyTreeDTO getFullTree(UUID personId);
    // Retourne : la personne centrale + ses parents, grand-parents (max 4 gen),
    // ses enfants, ses frères/sœurs, ses cousins 1er degré, ses épouses

    List<PersonDTO> getParents(UUID personId);
    List<PersonDTO> getChildren(UUID personId);
    List<PersonDTO> getSiblings(UUID personId);
    List<PersonDTO> getGrandparents(UUID personId);
    List<PersonDTO> getFirstCousins(UUID personId);
    List<UnionDTO> getActiveSpouses(UUID personId);

    // ── CLAUDE AI ──────────────────────────────────────────────────
    List<AiSuggestionDTO> generateAiSuggestions(UUID personId);
    // Appelle ClaudeAiClient avec le contexte du clan + arbre partiel
    // Stocke les résultats dans ai_genealogy_suggestions avec status=PENDING

    AiSuggestionDTO reviewAiSuggestion(UUID suggestionId, boolean accepted, UUID reviewedBy);
    // Si accepted=true : crée le lien correspondant (ParentChild ou Union)
    // Publie AiSuggestionAcceptedEvent
}
```

### Neo4jSyncService.java

```java
@Service
public class Neo4jSyncService {

    // Écoute PersonCreatedEvent → crée le nœud Neo4j + met à jour persons.neo4j_node_id
    @EventListener
    void onPersonCreated(PersonCreatedEvent event);

    // Écoute ParentChildLinkedEvent → crée la relation PARENT_OF dans Neo4j
    @EventListener
    void onParentChildLinked(ParentChildLinkedEvent event);

    // Écoute UnionCreatedEvent → crée la relation MARRIED_TO dans Neo4j
    @EventListener
    void onUnionCreated(UnionCreatedEvent event);

    // Sync complète d'une personne PostgreSQL → Neo4j (pour import/migration)
    void fullSyncPerson(UUID personId);
}
```

### GenealogyAiService.java

```java
@Service
public class GenealogyAiService {

    private final ClaudeAiClient claudeAiClient;  // shared-kernel

    /**
     * Analyse l'arbre partiel d'une personne et suggère des liens manquants.
     *
     * Stratégie :
     * 1. Récupérer tous les membres du même clan dans le même village (Neo4j)
     * 2. Filtrer ceux sans lien connu avec la personne (Neo4j)
     * 3. Construire le contexte JSON : {person, knownRelatives, candidates}
     * 4. Appeler Claude avec le prompt ci-dessous
     * 5. Parser la réponse JSON → List<AiSuggestionDTO>
     * 6. Sauvegarder dans ai_genealogy_suggestions
     */
    public List<AiSuggestionDTO> suggestLinks(UUID personId) {
        // Prompt à utiliser :
        String systemPrompt = """
            Tu es un expert en généalogie africaine spécialisé dans les structures familiales
            des peuples d'Afrique centrale et occidentale.
            
            Analyse l'arbre généalogique partiel fourni et identifie les liens familiaux
            probables entre la personne centrale et les candidats.
            
            Règles :
            - Un enfant a EXACTEMENT 2 parents biologiques (père + mère)
            - Un homme peut avoir plusieurs épouses (polygamie possible, encode avec WIFE_1, WIFE_2...)
            - Utilise le clan, le totem, le village, les dates et les noms pour inférer les liens
            - Ne jamais affirmer avec certitude : toujours un score de confiance
            - Score < 0.3 : ne pas suggérer
            - Retourne UNIQUEMENT du JSON valide, aucun texte avant ni après
            
            Format de sortie JSON :
            {
              "suggestions": [
                {
                  "person_a_id": "uuid",
                  "person_b_id": "uuid",
                  "suggested_relation": "FATHER|MOTHER|CHILD|SIBLING|WIFE",
                  "confidence": 0.0-1.0,
                  "reasons": ["raison 1", "raison 2"]
                }
              ]
            }
        """;

        // Context user message construit depuis :
        // - La fiche PostgreSQL de la personne
        // - Les parents/enfants déjà connus (Neo4j)
        // - Les membres du clan sans lien (Neo4j query)
    }
}
```

---

## PARTIE 8 — CONTROLLERS REST

Package : `com.gwangmeu.genealogy.api`

### PersonController.java
```
Base URL : /api/v1/persons

POST   /api/v1/persons                          → createPerson
GET    /api/v1/persons/{id}                     → getPersonById
PUT    /api/v1/persons/{id}                     → updatePerson
DELETE /api/v1/persons/{id}                     → deletePerson (ROLE_ADMIN ou créateur)
GET    /api/v1/persons/village/{villageId}      → getPersonsByVillage
```

### GenealogyController.java
```
Base URL : /api/v1/genealogy

GET    /api/v1/genealogy/tree/{personId}        → getFullTree (pour Flutter)
POST   /api/v1/genealogy/link/parent-child      → linkParentChild
DELETE /api/v1/genealogy/link/parent-child      → unlinkParentChild
GET    /api/v1/genealogy/{personId}/parents     → getParents
GET    /api/v1/genealogy/{personId}/children    → getChildren
GET    /api/v1/genealogy/{personId}/siblings    → getSiblings
GET    /api/v1/genealogy/{personId}/grandparents → getGrandparents
GET    /api/v1/genealogy/{personId}/cousins     → getFirstCousins
GET    /api/v1/genealogy/{personId}/spouses     → getActiveSpouses
```

### UnionController.java
```
Base URL : /api/v1/unions

POST   /api/v1/unions                           → createUnion
PUT    /api/v1/unions/{id}/dot                  → updateDotStatus
PUT    /api/v1/unions/{id}/end                  → endUnion
GET    /api/v1/unions/person/{personId}         → getUnionsByPerson
```

### AiGenealogyController.java
```
Base URL : /api/v1/genealogy/ai

POST   /api/v1/genealogy/ai/suggest/{personId}  → generateAiSuggestions (ROLE_MEMBRE)
GET    /api/v1/genealogy/ai/suggestions/{personId} → pending suggestions for person
PUT    /api/v1/genealogy/ai/suggestions/{id}/review → reviewAiSuggestion (accept/reject)
```

Tous les controllers doivent :
- Avoir `@PreAuthorize` approprié selon le rôle
- Retourner `ResponseEntity<ApiResponse<T>>` (wrapper générique shared-kernel)
- Avoir Swagger/OpenAPI `@Operation` + `@ApiResponse` annotations
- Logger les actions importantes via SLF4J

---

## PARTIE 9 — DTOs

Package : `com.gwangmeu.genealogy.dto`

Crée ces DTOs avec Lombok `@Data @Builder @NoArgsConstructor @AllArgsConstructor` :

```java
// PersonDTO — retourné par l'API
PersonDTO {
  UUID id; String firstName; String lastName; String maidenName;
  GenderEnum gender; LocalDate birthDate; String birthPlace;
  boolean isAlive; String clan; String totem; String nativeLanguage;
  String photoUrl; PrivacyEnum privacy; PersonStatusEnum status;
  UUID userId; UUID villageId; Instant createdAt;
}

// FamilyTreeDTO — arbre complet retourné par GET /tree/{personId}
FamilyTreeDTO {
  PersonDTO subject;
  List<PersonDTO> father;        // max 1
  List<PersonDTO> mother;        // max 1
  List<PersonDTO> paternalGP;   // max 2 (père du père, mère du père)
  List<PersonDTO> maternalGP;   // max 2 (père de la mère, mère de la mère)
  List<PersonDTO> siblings;
  List<PersonDTO> children;
  List<UnionDTO> unions;         // avec épouses
  List<PersonDTO> cousins;
  List<AiSuggestionDTO> pendingSuggestions;
}

// UnionDTO — retourné par l'API
UnionDTO {
  UUID id; UUID husbandId; UUID wifeId;
  PersonDTO husband; PersonDTO wife;
  UnionTypeEnum unionType; int unionOrder;
  LocalDate startDate; LocalDate endDate;
  boolean isActive; EndReasonEnum endReason;
  boolean isDotPaid; LocalDate dotDate; UUID dotPaidBy; String dotDescription;
}

// AiSuggestionDTO
AiSuggestionDTO {
  UUID id; UUID personAId; UUID personBId;
  PersonDTO personA; PersonDTO personB;
  String suggestedRelation; double confidence;
  List<String> reasons; AiSuggestionStatusEnum status;
  Instant createdAt; Instant expiresAt;
}

// CreatePersonRequest — pour POST /persons
CreatePersonRequest {
  @NotBlank String firstName;
  @NotBlank String lastName;
  String maidenName;
  @NotNull GenderEnum gender;
  LocalDate birthDate;
  String birthPlace;
  String clan; String totem; String nativeLanguage;
  String biography;
  UUID villageId;
  PrivacyEnum privacy;
}

// CreateUnionRequest — pour POST /unions
CreateUnionRequest {
  @NotNull UUID husbandId;
  @NotNull UUID wifeId;
  @NotNull UnionTypeEnum unionType;
  LocalDate startDate;
  boolean isDotPaid;
  LocalDate dotDate;
  UUID dotPaidBy;
  String dotDescription;
  List<UUID> dotWitnesses;
}
```

---

## PARTIE 10 — FLUTTER : MODÈLES DART

Crée dans `mobile/lib/features/genealogy/data/models/` :

```dart
// person.dart
@freezed
class Person with _$Person {
  const factory Person({
    required String id,
    String? userId,
    String? villageId,
    required String firstName,
    required String lastName,
    String? maidenName,
    required String gender,    // 'MALE' | 'FEMALE' | 'OTHER'
    DateTime? birthDate,
    String? birthPlace,
    DateTime? deathDate,
    String? clan,
    String? totem,
    String? nativeLanguage,
    String? photoUrl,
    required String privacy,
    required String status,
    DateTime? createdAt,
  }) = _Person;

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

  // Helper
}

// union.dart
@freezed
class Union with _$Union {
  const factory Union({
    required String id,
    required String husbandId,
    required String wifeId,
    Person? husband,
    Person? wife,
    required String unionType,
    required int unionOrder,
    DateTime? startDate,
    DateTime? endDate,
    required bool isActive,
    required bool isDotPaid,
    DateTime? dotDate,
    String? dotPaidBy,
    String? dotDescription,
  }) = _Union;

  factory Union.fromJson(Map<String, dynamic> json) => _$UnionFromJson(json);
}

// family_tree.dart
@freezed
class FamilyTree with _$FamilyTree {
  const factory FamilyTree({
    required Person subject,
    @Default([]) List<Person> fathers,
    @Default([]) List<Person> mothers,
    @Default([]) List<Person> paternalGrandparents,
    @Default([]) List<Person> maternalGrandparents,
    @Default([]) List<Person> siblings,
    @Default([]) List<Person> children,
    @Default([]) List<Union> unions,
    @Default([]) List<Person> cousins,
    @Default([]) List<AiSuggestion> pendingSuggestions,
  }) = _FamilyTree;

  factory FamilyTree.fromJson(Map<String, dynamic> json) => _$FamilyTreeFromJson(json);
}

// ai_suggestion.dart
@freezed
class AiSuggestion with _$AiSuggestion {
  const factory AiSuggestion({
    required String id,
    required String personAId,
    required String personBId,
    Person? personA,
    Person? personB,
    required String suggestedRelation,
    required double confidence,
    @Default([]) List<String> reasons,
    required String status,
    DateTime? createdAt,
  }) = _AiSuggestion;

  factory AiSuggestion.fromJson(Map<String, dynamic> json) => _$AiSuggestionFromJson(json);
}
```

---

## PARTIE 11 — FLUTTER : SERVICE API

Crée dans `mobile/lib/features/genealogy/data/services/genealogy_api_service.dart` :

```dart
@riverpod
class GenealogyApiService extends _$GenealogyApiService {

  late final Dio _dio;  // injecté via Riverpod, inclut JWT interceptor

  // Arbre complet
  Future<FamilyTree> getFullTree(String personId) async {
    final response = await _dio.get('/api/v1/genealogy/tree/$personId');
    return FamilyTree.fromJson(response.data['data']);
  }

  // Créer une personne
  Future<Person> createPerson(CreatePersonRequest req) async {
    final response = await _dio.post('/api/v1/persons', data: req.toJson());
    return Person.fromJson(response.data['data']);
  }

  // Lier parent-enfant
  Future<void> linkParentChild({
    required String parentId,
    required String childId,
    required String role,  // 'FATHER' | 'MOTHER'
    String type = 'BIOLOGICAL',
  }) async {
    await _dio.post('/api/v1/genealogy/link/parent-child', data: {
      'parentId': parentId, 'childId': childId,
      'role': role, 'type': type,
    });
  }

  // Créer une union
  Future<Union> createUnion(CreateUnionRequest req) async {
    final response = await _dio.post('/api/v1/unions', data: req.toJson());
    return Union.fromJson(response.data['data']);
  }

  // Mettre à jour le statut de la dot
  Future<Union> updateDotStatus(String unionId, {
    required bool isDotPaid,
    DateTime? dotDate,
    String? dotPaidBy,
    String? dotDescription,
  }) async {
    final response = await _dio.put('/api/v1/unions/$unionId/dot', data: {
      'isDotPaid': isDotPaid, 'dotDate': dotDate?.toIso8601String(),
      'dotPaidBy': dotPaidBy, 'dotDescription': dotDescription,
    });
    return Union.fromJson(response.data['data']);
  }

  // Générer des suggestions IA
  Future<List<AiSuggestion>> generateAiSuggestions(String personId) async {
    final response = await _dio.post('/api/v1/genealogy/ai/suggest/$personId');
    return (response.data['data'] as List)
        .map((e) => AiSuggestion.fromJson(e)).toList();
  }

  // Valider/rejeter une suggestion IA
  Future<AiSuggestion> reviewSuggestion(String suggestionId, bool accepted) async {
    final response = await _dio.put(
      '/api/v1/genealogy/ai/suggestions/$suggestionId/review',
      data: {'accepted': accepted},
    );
    return AiSuggestion.fromJson(response.data['data']);
  }
}
```

---

## PARTIE 12 — FLUTTER : WIDGET ARBRE INTERACTIF

Crée dans `mobile/lib/features/genealogy/presentation/widgets/family_tree_widget.dart` :

Utilise le package `flutter_graph_view: ^2.1.0`.

```dart
class FamilyTreeWidget extends ConsumerStatefulWidget {
  final String personId;
  const FamilyTreeWidget({required this.personId});
  // ...
}

class _FamilyTreeWidgetState extends ConsumerState<FamilyTreeWidget> {

  // Palette GWANG MEU
  static const Color gold   = Color(0xFFC8A020);
  static const Color male   = Color(0xFF2A4A6A);
  static const Color female = Color(0xFF5A2A4A);
  static const Color aiNode = Color(0xFF0D2A0D);
  static const Color dead   = Color(0xFF2A2A2A);

  // Convertit FamilyTree en List<Node> pour flutter_graph_view
  List<Node> _buildNodes(FamilyTree tree) {
    final nodes = <Node>[];
    // Subject
    nodes.add(Node(
      id: tree.subject.id,
      label: '${tree.subject.firstName}\n${tree.subject.lastName}',
      color: gold,
      size: 32,
      data: tree.subject,
    ));
    // Parents
    for (final p in [...tree.fathers, ...tree.mothers]) {
      nodes.add(Node(
        id: p.id,
        label: '${p.firstName}\n${p.lastName}',
        color: p.gender == 'MALE' ? male : female,
        size: 26,
        data: p,
      ));
    }
    // ... (idem pour siblings, children, cousins, grands-parents)

    // Suggestions IA : nœuds en pointillés
    for (final s in tree.pendingSuggestions) {
      final other = s.personA?.id == tree.subject.id ? s.personB : s.personA;
      if (other != null) {
        nodes.add(Node(
          id: other.id + '_ai',
          label: '${other.firstName}?\n(IA ${(s.confidence * 100).toStringAsFixed(0)}%)',
          color: aiNode,
          size: 20,
          strokeColor: const Color(0xFF3DAA6E),
          strokeWidth: 1.5,
          strokeDash: true,  // if supported
          data: s,
        ));
      }
    }
    return nodes;
  }

  // Convertit FamilyTree en List<Edge> pour flutter_graph_view
  List<Edge> _buildEdges(FamilyTree tree) { /* ... */ }

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(familyTreeProvider(widget.personId));
    return treeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: gold)),
      error: (e, s) => Center(child: Text('Erreur: $e')),
      data: (tree) => Column(
        children: [
          // Toolbar : filtres (Complet / Ascendants / Descendants / Unions)
          _TreeToolbar(onViewChanged: (v) => setState(() => _currentView = v)),
          // Légende
          _TreeLegend(),
          // Graphe
          Expanded(
            child: GraphView(
              nodes: _buildNodes(tree),
              edges: _buildEdges(tree),
              algorithm: SugiyamaAlgorithm(
                SugiyamaConfiguration()
                  ..nodeSeparation = 60
                  ..levelSeparation = 80,
              ),
              paint: Paint()..color = Colors.white.withOpacity(0.1),
              builder: (Node node) => _NodeWidget(node: node, onTap: _showNodeDetails),
            ),
          ),
          // Panel suggestions IA (si present)
          if (tree.pendingSuggestions.isNotEmpty)
            _AiSuggestionsPanel(
              suggestions: tree.pendingSuggestions,
              onReview: (id, accepted) => ref
                .read(genealogyApiServiceProvider.notifier)
                .reviewSuggestion(id, accepted),
            ),
        ],
      ),
    );
  }
}
```

---

## PARTIE 13 — TESTS JUNIT 5 + TESTCONTAINERS

Crée dans `backend/src/test/java/com/gwangmeu/genealogy/` :

### GenealogyServiceTest.java
```java
@SpringBootTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Testcontainers
class GenealogyServiceTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgis/postgis:16-3.4");

    @Container
    static Neo4jContainer<?> neo4j = new Neo4jContainer<>("neo4j:5")
        .withAdminPassword("testpassword");

    // Tests obligatoires :

    @Test void shouldCreatePersonWithMinimalData() { }
    @Test void shouldLinkFatherToChild() { }
    @Test void shouldLinkMotherToChild() { }
    @Test void shouldRejectDuplicateBiologicalFather() { }  // IllegalStateException attendue
    @Test void shouldCreateUnionWithDotInfo() { }
    @Test void shouldMarkDotAsPaid() { }
    @Test void shouldCalculateSiblingsFromSharedParents() { }
    @Test void shouldReturnFullTree() { }
    @Test void shouldSyncToNeo4jOnPersonCreate() { }
    @Test void shouldSyncToNeo4jOnParentChildLink() { }
    @Test void shouldFindGrandparentsViaNeo4j() { }
    @Test void shouldFindFirstCousinsViaNeo4j() { }
    @Test void shouldStoreAiSuggestion() { }
    @Test void shouldAcceptAiSuggestionAndCreateLink() { }
    @Test void shouldRejectAiSuggestionAndNotCreateLink() { }
}
```

---

## CONTRAINTES IMPÉRATIVES

1. **Jamais d'appel direct entre modules** — utilise ApplicationEventPublisher pour notifier
   - `notification-module` des nouvelles connexions
   - `search-module` pour réindexer
   - `feed-module` pour créer un post social (si person.privacy = PUBLIC)

2. **Neo4j sync asynchrone** — la sync PostgreSQL → Neo4j se fait via `@Async` pour ne pas bloquer le thread HTTP

3. **Validation humaine obligatoire** — les suggestions IA (`ai_genealogy_suggestions`) ne créent JAMAIS un lien directement. Statut initial = PENDING. Seul l'utilisateur (reviewer) peut passer à ACCEPTED et déclencher la création du lien.

4. **RLS Supabase** — Rappel des politiques déjà définies dans les migrations :
   - `persons` : lecture selon `privacy` (PUBLIC/MEMBERS/FAMILY)
   - `unions` : lecture par les 2 membres de l'union ou admin
   - `parent_child` : lecture publique, écriture par créateur ou admin

5. **Règle polygamie** — `UnionService.createUnion()` doit :
   - Vérifier que `husbandId` pointe vers une personne de gender=MALE
   - Calculer automatiquement `union_order` = `MAX(union_order) + 1` pour ce mari
   - Permettre plusieurs unions actives pour le même mari (polygamie)
   - Mais une femme ne peut avoir qu'une seule union active à la fois

6. **Tests** : couverture minimum 80% sur `GenealogyService` et `Neo4jSyncService`

7. **Logs** : utiliser `@Slf4j` Lombok. Logger INFO pour chaque création/modification, WARN pour les tentatives de doublons, ERROR pour les échecs Neo4j (avec fallback gracieux)

8. **Variables d'environnement** — utiliser celles définies dans ARCHITECTURE.md :
   - Neo4j : NEO4J_URI, NEO4J_USERNAME, NEO4J_PASSWORD
   - Claude : ANTHROPIC_API_KEY

---

## ORDRE D'EXÉCUTION RECOMMANDÉ

Implémente dans cet ordre exact, un fichier à la fois. Après chaque fichier, demande confirmation avant de passer au suivant :

1. `V10__genealogy_enums.sql`
2. `V11__genealogy_persons.sql`
3. `V12__genealogy_relations.sql`
4. `V13__genealogy_sibling_trigger.sql`
5. Enums Java (tous)
6. `Person.java` + `PersonRepository.java`
7. `ParentChild.java` + `ParentChildRepository.java`
8. `Union.java` + `UnionRepository.java`
9. `AiGenealogysuggestion.java` + repository
10. `PersonNode.java` + `ParentOfRelationship.java` + `MarriedToRelationship.java`
11. `PersonNodeRepository.java`
12. Domain Events (tous les records)
13. DTOs (tous)
14. `GenealogyService.java` (méthodes CRUD)
15. `UnionService.java` (avec règle polygamie)
16. `Neo4jSyncService.java` (avec @EventListener)
17. `GenealogyAiService.java` (avec appel Claude)
18. `PersonController.java`
19. `GenealogyController.java`
20. `UnionController.java`
21. `AiGenealogyController.java`
22. Flutter Dart models (Person, Union, FamilyTree, AiSuggestion)
23. Flutter GenealogyApiService
24. Flutter FamilyTreeWidget
25. Tests JUnit 5

---

Commence par la tâche 1. Génère le code complet et fonctionnel, sans omettre aucun import.
```

---

## ═══════════════════════════════════════════════════════════
## PROMPTS DE SUIVI (après le prompt principal)
## ═══════════════════════════════════════════════════════════

Une fois le prompt principal exécuté, utilise ces prompts de suivi
pour des ajouts ou ajustements spécifiques.

---

### SUIVI 1 — Ajouter la page Profil Généalogie Flutter

```
Dans le genealogy-module Flutter, crée la page complète `GenealogyProfilePage`
dans `mobile/lib/features/genealogy/presentation/pages/genealogy_profile_page.dart`.

Cette page doit afficher :
1. En-tête : photo de la personne, nom complet, clan + totem, badge statut (CONFIRMED / PENDING / IA)
2. Onglet "Arbre" : le widget FamilyTreeWidget déjà créé
3. Onglet "Épouses" : liste des unions avec pour chaque épouse :
   - Photo + nom
   - Type d'union (DOT / CIVIL / TRADITIONNEL…)
   - Badge vert "Dot payée" si isDotPaid=true + détail (par qui, quand)
   - Badge orange "Dot non payée" sinon
   - Date de début, statut (Active / Terminée + raison)
4. Onglet "Suggestions IA" : liste des AiSuggestion PENDING avec :
   - Score de confiance en barre de progression colorée (< 0.5 rouge, 0.5-0.75 orange, > 0.75 vert)
   - Raisons listées
   - Boutons "✓ Confirmer" / "✗ Rejeter"
5. FAB (Floating Action Button) doré avec icône "+" : ouvre un BottomSheet pour ajouter un lien
   (nouveau parent, nouvel enfant, nouvelle union)

Utilise le design system GWANG MEU : couleurs gold #C8A020, fond #0A0A0A, typo Fraunces + Plus Jakarta Sans.
Gère les états loading / error / empty avec des widgets appropriés.
```

---

### SUIVI 2 — Endpoint export GEDCOM

```
Dans GenealogyController, ajoute un endpoint d'export :

GET /api/v1/genealogy/tree/{personId}/export?format=GEDCOM

Le format GEDCOM 5.5.1 est le standard international de généalogie.

Implémente GedcomExportService.java qui :
1. Récupère l'arbre complet via Neo4j (jusqu'à 6 générations)
2. Génère un fichier .ged valide (UTF-8) avec :
   - Header GEDCOM 5.5.1
   - Records INDI (Individual) pour chaque Person
   - Records FAM (Family) pour chaque union + enfants
   - Records NOTE pour les informations culturelles (clan, totem, bio)
3. Retourne un ResponseEntity<Resource> avec Content-Disposition: attachment; filename="arbre_{personId}.ged"

Test : GedcomExportServiceTest avec un arbre de 3 générations.
```

---

### SUIVI 3 — Import depuis photo (Claude Vision)

```
Ajoute dans GenealogyAiService une méthode d'analyse d'arbre depuis photo :

POST /api/v1/genealogy/ai/analyze-photo

L'utilisateur upload une photo d'un arbre généalogique papier ou d'un document.
Claude Vision (claude-sonnet-4-6 avec vision) extrait les noms, dates et liens visibles.

Implémente :
1. Endpoint avec @RequestParam("photo") MultipartFile photo
2. Upload vers Cloudflare R2 (via shared-kernel MediaService)
3. Appel Claude API avec le message image en base64 + prompt :
   "Analyse cette image d'arbre généalogique africain. 
    Extrais tous les noms, dates et relations visibles.
    Retourne JSON : { persons: [...], relations: [...] }
    Pour chaque personne : {name, gender_guess, birth_year_guess, role_in_tree}
    Pour chaque relation : {from_name, to_name, type: PARENT|SPOUSE|SIBLING}"
4. Parse la réponse JSON
5. Crée les Person et les AiGenealogysuggestion correspondantes (toutes avec status=PENDING)
6. Retourne un rapport : {personsCreated: N, suggestionsCreated: N, message: "..."}

Important : toutes les données extraites sont des SUGGESTIONS (status=PENDING).
L'utilisateur doit valider chacune individuellement.
```

---

### SUIVI 4 — Widget mini-arbre pour le fil d'actualité

```
Crée un widget Flutter compact `MiniTreeWidget` pour afficher dans le feed social.

`mobile/lib/features/genealogy/presentation/widgets/mini_tree_widget.dart`

Ce widget affiche :
- La personne centrale (cercle doré avec initiales)
- Ses parents directs (gauche) reliés par une ligne
- Ses enfants (droite) reliés par une ligne
- Un bouton "Voir l'arbre complet" → navigation vers GenealogyProfilePage
- Taille compacte : height=160px, s'adapte à la largeur du feed

Paramètres :
  final String personId;
  final bool showActions;  // true dans le feed, false dans les cartes d'aperçu

Utilise CustomPainter pour dessiner les lignes et les cercles.
Palette GWANG MEU obligatoire.
```

---

## ═══════════════════════════════════════════════════════════
## AIDE-MÉMOIRE : COMMANDES CLAUDE CODE
## ═══════════════════════════════════════════════════════════

```bash
# Dans le terminal IntelliJ avec Claude Code installé :

# Lancer Claude Code dans le projet
claude

# Vérifier que les migrations sont bien appliquées
# (après avoir lancé le backend avec le profil local)
./mvnw flyway:info

# Lancer les tests du module généalogie uniquement
./mvnw test -pl backend -Dtest="*Genealogy*"

# Vérifier la connexion Neo4j AuraDB
# Ouvrir : https://browser.neo4j.io/
# Connecter avec : bolt+s://xxxxx.databases.neo4j.io

# Vérifier Supabase
# Ouvrir : https://supabase.com/dashboard/project/objlxdxzpqhrekpqxgab
# Table Editor → vérifier tables persons, unions, parent_child

# Variables d'environnement requises dans .env (backend/)
NEO4J_URI=bolt+s://XXXXX.databases.neo4j.io
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=XXXXXXXX
ANTHROPIC_API_KEY=sk-ant-XXXXXX
SUPABASE_URL=https://objlxdxzpqhrekpqxgab.supabase.co
SUPABASE_SERVICE_KEY=XXXXXXXXXX
```

---

## ═══════════════════════════════════════════════════════════
## DÉPENDANCES MAVEN À AJOUTER (pom.xml backend)
## ═══════════════════════════════════════════════════════════

```xml
<!-- Spring Data Neo4j -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-neo4j</artifactId>
</dependency>

<!-- Pour JSON dans PostgreSQL (JSONB) -->
<dependency>
    <groupId>io.hypersistence</groupId>
    <artifactId>hypersistence-utils-hibernate-63</artifactId>
    <version>3.7.0</version>
</dependency>

<!-- Anthropic SDK Java (si pas déjà présent) -->
<dependency>
    <groupId>com.anthropic</groupId>
    <artifactId>sdk</artifactId>
    <version>0.8.0</version>
</dependency>

<!-- Testcontainers Neo4j -->
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>neo4j</artifactId>
    <scope>test</scope>
</dependency>
```

---

## ═══════════════════════════════════════════════════════════
## DÉPENDANCES FLUTTER À AJOUTER (pubspec.yaml)
## ═══════════════════════════════════════════════════════════

```yaml
dependencies:
  flutter_graph_view: ^2.1.0    # Arbre interactif
  freezed_annotation: ^2.4.4    # Modèles immuables
  json_annotation: ^4.9.0       # JSON sérialisation

dev_dependencies:
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0

# Après ajout, lancer :
# flutter pub get
# flutter pub run build_runner build --delete-conflicting-outputs
```

---

*Prompt généré pour GWANG MEU — Langues · Culture · Futur*
*Architecture V3 — Mars 2026*
*Module : genealogy-module (Phase 3)*
