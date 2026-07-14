package com.gwangmeu.admin;

import jakarta.validation.constraints.NotBlank;

/** Corps de PATCH /admin/users/{id}/role. */
public record UpdateRoleRequest(@NotBlank String role) {}
