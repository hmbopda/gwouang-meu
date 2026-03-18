package com.gwangmeu.genealogy.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.UUID;

@Data
public class CreatePersonCommentRequest {

    @NotBlank
    @Size(max = 2000)
    private String content;

    private UUID parentCommentId;
}
