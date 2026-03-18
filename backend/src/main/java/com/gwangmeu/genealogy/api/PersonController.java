package com.gwangmeu.genealogy.api;

import com.gwangmeu.genealogy.application.GenealogyService;
import com.gwangmeu.genealogy.domain.Clan;
import com.gwangmeu.genealogy.domain.Person;
import com.gwangmeu.genealogy.domain.PersonClan;
import com.gwangmeu.genealogy.domain.PersonComment;
import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.genealogy.dto.*;
import com.gwangmeu.genealogy.infrastructure.ClanRepository;
import com.gwangmeu.genealogy.infrastructure.PersonClanRepository;
import com.gwangmeu.genealogy.infrastructure.PersonCommentRepository;
import com.gwangmeu.genealogy.infrastructure.PersonRepository;
import com.gwangmeu.genealogy.infrastructure.PersonVillageRepository;
import com.gwangmeu.shared.api.ApiResponse;
import com.gwangmeu.shared.security.CurrentUser;
import com.gwangmeu.shared.security.UserIdResolver;
import com.gwangmeu.user.User;
import com.gwangmeu.user.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Slf4j
@RestController
@RequestMapping("/api/v1/persons")
@RequiredArgsConstructor
public class PersonController {

    private final GenealogyService genealogyService;
    private final UserIdResolver userIdResolver;
    private final PersonRepository personRepository;
    private final PersonVillageRepository personVillageRepository;
    private final ClanRepository clanRepository;
    private final PersonClanRepository personClanRepository;
    private final PersonCommentRepository personCommentRepository;
    private final UserRepository userRepository;

    @PostMapping
    @Operation(summary = "Create a new person in the genealogy tree")
    public ResponseEntity<ApiResponse<PersonDTO>> createPerson(
            @Valid @RequestBody CreatePersonRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        PersonDTO person = genealogyService.createPerson(req, userId);
        return ResponseEntity.status(201).body(ApiResponse.created(person));
    }

    @GetMapping("/me")
    @Operation(summary = "Get the current user's genealogy person")
    public ResponseEntity<ApiResponse<PersonDTO>> getMyPerson(@CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getMyPerson(userId)));
    }

    @GetMapping("/lookup")
    @Operation(summary = "Search a person by email and/or phone (for deduplication before creation)")
    public ResponseEntity<ApiResponse<List<PersonDTO>>> lookupByContact(
            @RequestParam(required = false) String email,
            @RequestParam(required = false) String phone) {

        List<Person> persons = new ArrayList<>();
        Set<UUID> seenIds = new HashSet<>();

        // Search by email in persons table
        if (email != null && !email.isBlank()) {
            personRepository.findByEmailIgnoreCase(email.trim())
                    .ifPresent(p -> { if (seenIds.add(p.getId())) persons.add(p); });
        }

        // Search by phone in persons table
        if (phone != null && !phone.isBlank()) {
            personRepository.findByPhone(phone.trim())
                    .ifPresent(p -> { if (seenIds.add(p.getId())) persons.add(p); });
        }

        // Also search in users table and find linked persons
        if (email != null && !email.isBlank()) {
            userRepository.findByEmail(email.trim()).ifPresent(user ->
                personRepository.findByUserId(user.getId())
                        .ifPresent(p -> { if (seenIds.add(p.getId())) persons.add(p); })
            );
        }

        List<PersonDTO> dtos = persons.stream()
                .map(p -> GenealogyMapper.toDTO(p, personVillageRepository.findVillageIdsByPersonId(p.getId())))
                .toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @GetMapping("/search")
    @Operation(summary = "Search persons by clan and/or name (for parent suggestions)")
    public ResponseEntity<ApiResponse<List<PersonDTO>>> searchPersons(
            @RequestParam(required = false) String clan,
            @RequestParam(required = false, defaultValue = "") String q) {
        List<Person> persons;
        if (clan != null && !clan.isBlank()) {
            persons = q.isBlank()
                    ? personRepository.findByClan(clan)
                    : personRepository.searchByClanAndName(clan, q);
        } else {
            persons = List.of();
        }
        List<PersonDTO> dtos = persons.stream()
                .map(p -> GenealogyMapper.toDTO(p, personVillageRepository.findVillageIdsByPersonId(p.getId())))
                .toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @GetMapping("/village/{villageId}")
    @Operation(summary = "Get persons by village (paginated)")
    public ResponseEntity<ApiResponse<ApiResponse.PageData<PersonDTO>>> getPersonsByVillage(
            @PathVariable UUID villageId, Pageable pageable) {
        return ResponseEntity.ok(ApiResponse.paginated(genealogyService.getPersonsByVillage(villageId, pageable)));
    }

    @GetMapping("/village/{villageId}/clans")
    @Operation(summary = "Get clans (grandes familles) for a village with person count")
    public ResponseEntity<ApiResponse<List<ClanDTO>>> getClansByVillage(@PathVariable UUID villageId) {
        List<Clan> clans = clanRepository.findByVillageIdOrderByNameAsc(villageId);
        List<ClanDTO> dtos = clans.stream().map(c -> {
            long count = personClanRepository.findPersonIdsByClanId(c.getId()).size();
            return ClanDTO.builder()
                    .id(c.getId())
                    .name(c.getName())
                    .villageId(c.getVillageId())
                    .description(c.getDescription())
                    .personCount(count)
                    .build();
        }).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @GetMapping("/village/{villageId}/by-gender")
    @Operation(summary = "Get persons by village filtered by gender")
    public ResponseEntity<ApiResponse<List<PersonDTO>>> getPersonsByVillageAndGender(
            @PathVariable UUID villageId,
            @RequestParam String gender) {
        GenderEnum genderEnum = GenderEnum.valueOf(gender);
        List<Person> persons = personRepository.findByVillageIdAndGender(villageId, genderEnum);
        List<PersonDTO> dtos = persons.stream()
                .map(p -> GenealogyMapper.toDTO(p, personVillageRepository.findVillageIdsByPersonId(p.getId())))
                .toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @GetMapping("/clan/{clanId}/members")
    @Operation(summary = "Get persons by clan, optionally filtered by gender")
    public ResponseEntity<ApiResponse<List<PersonDTO>>> getPersonsByClan(
            @PathVariable UUID clanId,
            @RequestParam(required = false) String gender) {
        List<Person> persons;
        if (gender != null && !gender.isBlank()) {
            GenderEnum genderEnum = GenderEnum.valueOf(gender);
            persons = personRepository.findByClanIdAndGender(clanId, genderEnum);
        } else {
            persons = personRepository.findByClanId(clanId);
        }
        List<PersonDTO> dtos = persons.stream()
                .map(p -> GenealogyMapper.toDTO(p, personVillageRepository.findVillageIdsByPersonId(p.getId())))
                .toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PostMapping("/check-duplicate")
    @Operation(summary = "Check for potential duplicate persons before child creation")
    public ResponseEntity<ApiResponse<List<PersonDTO>>> checkDuplicate(
            @Valid @RequestBody DuplicateCheckRequest req) {
        List<PersonDTO> candidates = genealogyService.checkDuplicate(req);
        return ResponseEntity.ok(ApiResponse.ok(candidates));
    }

    @PostMapping("/{parentId}/children")
    @Operation(summary = "Create a child and link to parent atomically (with deduplication)")
    public ResponseEntity<ApiResponse<PersonDTO>> createChild(
            @PathVariable UUID parentId,
            @Valid @RequestBody CreateChildRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        PersonDTO child = genealogyService.createChild(parentId, req, userId);
        return ResponseEntity.status(201).body(ApiResponse.created(child));
    }

    @GetMapping("/{id:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}}")
    @Operation(summary = "Get a person by ID")
    public ResponseEntity<ApiResponse<PersonDTO>> getPersonById(@PathVariable UUID id) {
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.getPersonById(id)));
    }

    @PutMapping("/{id:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}}")
    @Operation(summary = "Update a person")
    public ResponseEntity<ApiResponse<PersonDTO>> updatePerson(
            @PathVariable UUID id,
            @RequestBody UpdatePersonRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        return ResponseEntity.ok(ApiResponse.ok(genealogyService.updatePerson(id, req, userId)));
    }

    @DeleteMapping("/{id:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}}")
    @Operation(summary = "Delete a person (creator or admin only)")
    public ResponseEntity<ApiResponse<Void>> deletePerson(
            @PathVariable UUID id,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        genealogyService.deletePerson(id, userId);
        return ResponseEntity.ok(ApiResponse.noContent());
    }

    // ── COMMENTAIRES SUR UNE FICHE PERSONNE ─────────────────

    @GetMapping("/{personId}/comments")
    @Operation(summary = "Get comments on a person's genealogy file")
    public ResponseEntity<ApiResponse<List<PersonCommentDTO>>> getPersonComments(
            @PathVariable UUID personId) {
        List<PersonComment> comments = personCommentRepository.findByPersonIdOrderByCreatedAtDesc(personId);
        List<PersonCommentDTO> dtos = comments.stream().map(this::toCommentDTO).toList();
        return ResponseEntity.ok(ApiResponse.ok(dtos));
    }

    @PostMapping("/{personId}/comments")
    @Operation(summary = "Add a comment/note on a person's genealogy file")
    public ResponseEntity<ApiResponse<PersonCommentDTO>> addPersonComment(
            @PathVariable UUID personId,
            @Valid @RequestBody CreatePersonCommentRequest req,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        PersonComment comment = PersonComment.builder()
                .personId(personId)
                .authorId(userId)
                .content(req.getContent())
                .parentCommentId(req.getParentCommentId())
                .build();
        PersonComment saved = personCommentRepository.save(comment);
        return ResponseEntity.status(201).body(ApiResponse.created(toCommentDTO(saved)));
    }

    @DeleteMapping("/{personId}/comments/{commentId}")
    @Operation(summary = "Delete own comment on a person's genealogy file")
    public ResponseEntity<ApiResponse<Void>> deletePersonComment(
            @PathVariable UUID personId,
            @PathVariable UUID commentId,
            @CurrentUser Jwt jwt) {
        UUID userId = userIdResolver.resolve(jwt);
        PersonComment comment = personCommentRepository.findById(commentId)
                .orElseThrow(() -> new IllegalArgumentException("Comment not found: " + commentId));
        if (!comment.getAuthorId().equals(userId)) {
            throw new IllegalStateException("Only the author can delete their comment");
        }
        personCommentRepository.delete(comment);
        return ResponseEntity.ok(ApiResponse.noContent());
    }

    private PersonCommentDTO toCommentDTO(PersonComment c) {
        User author = userRepository.findById(c.getAuthorId()).orElse(null);
        return PersonCommentDTO.builder()
                .id(c.getId())
                .personId(c.getPersonId())
                .authorId(c.getAuthorId())
                .authorName(author != null ? author.getDisplayName() : "Inconnu")
                .authorAvatarUrl(author != null ? author.getAvatarUrl() : null)
                .content(c.getContent())
                .parentCommentId(c.getParentCommentId())
                .createdAt(c.getCreatedAt())
                .build();
    }
}
