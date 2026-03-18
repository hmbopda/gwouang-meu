package com.gwangmeu.genealogy.dto;

import lombok.*;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PersonCommentDTO {
    private UUID id;
    private UUID personId;
    private UUID authorId;
    private String authorName;
    private String authorAvatarUrl;
    private String content;
    private UUID parentCommentId;
    private Instant createdAt;
}
