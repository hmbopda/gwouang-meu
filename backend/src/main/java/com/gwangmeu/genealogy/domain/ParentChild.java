package com.gwangmeu.genealogy.domain;

import com.gwangmeu.genealogy.domain.enums.ParentRoleEnum;
import com.gwangmeu.genealogy.domain.enums.ParentTypeEnum;
import com.gwangmeu.genealogy.domain.enums.RelationSourceEnum;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "parent_child")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ParentChild {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "parent_id", nullable = false)
    private UUID parentId;

    @Column(name = "child_id", nullable = false)
    private UUID childId;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "parent_role", nullable = false)
    private ParentRoleEnum parentRole;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(name = "parent_type", nullable = false)
    @Builder.Default
    private ParentTypeEnum parentType = ParentTypeEnum.BIOLOGICAL;

    @Column(name = "is_adopted", nullable = false)
    @Builder.Default
    private boolean isAdopted = false;

    @Column(precision = 3, scale = 2)
    private BigDecimal confidence;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    @Column(nullable = false)
    @Builder.Default
    private RelationSourceEnum source = RelationSourceEnum.DECLARED;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private Instant createdAt = Instant.now();

    @Column(name = "created_by", nullable = false)
    private UUID createdBy;
}
