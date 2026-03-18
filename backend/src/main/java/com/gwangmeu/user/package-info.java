/**
 * user-module — Profils, roles RBAC (6 roles), localisation, biographie culturelle.
 * Dependances : Supabase Auth, JWT.
 *
 * Expose : UserService (interface publique du module).
 * Evenements publies : UserCreatedEvent, UserUpdatedEvent.
 * Evenements consommes : —
 */
@org.springframework.modulith.ApplicationModule(displayName = "User Module")
package com.gwangmeu.user;
