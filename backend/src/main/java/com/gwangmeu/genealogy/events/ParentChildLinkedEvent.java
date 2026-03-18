package com.gwangmeu.genealogy.events;

import com.gwangmeu.genealogy.domain.enums.ParentRoleEnum;
import com.gwangmeu.genealogy.domain.enums.ParentTypeEnum;
import com.gwangmeu.genealogy.domain.enums.RelationSourceEnum;

import java.util.UUID;

public record ParentChildLinkedEvent(UUID parentId, UUID childId, ParentRoleEnum role, ParentTypeEnum type, RelationSourceEnum source) {}
