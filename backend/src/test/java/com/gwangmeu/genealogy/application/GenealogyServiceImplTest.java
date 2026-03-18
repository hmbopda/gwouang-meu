package com.gwangmeu.genealogy.application;

import com.gwangmeu.genealogy.domain.*;
import com.gwangmeu.genealogy.domain.enums.*;
import com.gwangmeu.shared.domain.enums.GenderEnum;
import com.gwangmeu.genealogy.dto.*;
import com.gwangmeu.genealogy.events.*;
import com.gwangmeu.genealogy.infrastructure.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("GenealogyServiceImpl — Tests unitaires")
class GenealogyServiceImplTest {

    @Mock private PersonRepository personRepository;
    @Mock private PersonVillageRepository personVillageRepository;
    @Mock private ParentChildRepository parentChildRepository;
    @Mock private UnionRepository unionRepository;
    @Mock private ChildAssociationRequestRepository childAssociationRequestRepository;
    @Mock private AiGenealogySuggestionRepository aiSuggestionRepository;
    @Mock private PersonNodeRepository personNodeRepository;
    @Mock private ApplicationEventPublisher eventPublisher;
    @Mock private GenealogyAiService genealogyAiService;

    @InjectMocks private GenealogyServiceImpl service;

    @Captor private ArgumentCaptor<ParentChild> parentChildCaptor;
    @Captor private ArgumentCaptor<ChildAssociationRequest> carCaptor;
    @Captor private ArgumentCaptor<Person> personCaptor;

    // ========================================================================
    // createChild
    // ========================================================================

    @Nested
    @DisplayName("createChild — Creation d'un enfant et lien parent-enfant")
    class CreateChildTests {

        @Test
        @DisplayName("Doit creer un enfant et lier au parent (FATHER pour parent MALE)")
        void shouldCreateChildAndLinkAsfather() {
            UUID parentId = UUID.randomUUID();
            UUID createdBy = UUID.randomUUID();

            Person parent = Person.builder().firstName("Kofi").lastName("Mbopda").gender(GenderEnum.MALE).createdBy(createdBy).build();
            parent.setId(parentId);

            CreateChildRequest req = CreateChildRequest.builder()
                    .firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE)
                    .birthDate(LocalDate.of(2020, 1, 1)).build();

            when(personRepository.findById(parentId)).thenReturn(Optional.of(parent));
            // email est null dans la requete → findDuplicate ne cherche pas par email
            when(personRepository.findByNameBirthDateAndGender("Ama", "Mbopda", LocalDate.of(2020, 1, 1), GenderEnum.FEMALE))
                    .thenReturn(List.of());
            when(personRepository.save(any(Person.class))).thenAnswer(inv -> {
                Person p = inv.getArgument(0);
                if (p.getId() == null) p.setId(UUID.randomUUID());
                return p;
            });
            when(parentChildRepository.save(any(ParentChild.class))).thenAnswer(inv -> inv.getArgument(0));
            when(personVillageRepository.findVillageIdsByPersonId(any())).thenReturn(List.of());

            PersonDTO result = service.createChild(parentId, req, createdBy);

            assertThat(result.getFirstName()).isEqualTo("Ama");
            assertThat(result.getLastName()).isEqualTo("Mbopda");

            verify(parentChildRepository).save(parentChildCaptor.capture());
            ParentChild link = parentChildCaptor.getValue();
            assertThat(link.getParentId()).isEqualTo(parentId);
            assertThat(link.getParentRole()).isEqualTo(ParentRoleEnum.FATHER);
            assertThat(link.getParentType()).isEqualTo(ParentTypeEnum.BIOLOGICAL);

            verify(eventPublisher, atLeast(1)).publishEvent(any(PersonCreatedEvent.class));
            verify(eventPublisher).publishEvent(any(ParentChildLinkedEvent.class));
        }

        @Test
        @DisplayName("Doit assigner le role MOTHER si le parent est FEMALE")
        void shouldAssignMotherRoleForFemaleParent() {
            UUID parentId = UUID.randomUUID();
            UUID createdBy = UUID.randomUUID();

            Person parent = Person.builder().firstName("Ama").lastName("Ngon").gender(GenderEnum.FEMALE).createdBy(createdBy).build();
            parent.setId(parentId);

            CreateChildRequest req = CreateChildRequest.builder()
                    .firstName("Junior").lastName("Ngon").gender(GenderEnum.MALE)
                    .birthDate(LocalDate.of(2021, 6, 15)).build();

            when(personRepository.findById(parentId)).thenReturn(Optional.of(parent));
            when(personRepository.findByNameBirthDateAndGender("Junior", "Ngon", LocalDate.of(2021, 6, 15), GenderEnum.MALE))
                    .thenReturn(List.of());
            when(personRepository.save(any(Person.class))).thenAnswer(inv -> {
                Person p = inv.getArgument(0);
                if (p.getId() == null) p.setId(UUID.randomUUID());
                return p;
            });
            when(parentChildRepository.save(any(ParentChild.class))).thenAnswer(inv -> inv.getArgument(0));
            when(personVillageRepository.findVillageIdsByPersonId(any())).thenReturn(List.of());

            service.createChild(parentId, req, createdBy);

            verify(parentChildRepository).save(parentChildCaptor.capture());
            assertThat(parentChildCaptor.getValue().getParentRole()).isEqualTo(ParentRoleEnum.MOTHER);
        }

        @Test
        @DisplayName("Doit utiliser une personne existante si existingPersonId est fourni")
        void shouldUseExistingPersonWhenExistingPersonIdProvided() {
            UUID parentId = UUID.randomUUID();
            UUID existingId = UUID.randomUUID();
            UUID createdBy = UUID.randomUUID();

            Person parent = Person.builder().firstName("Kofi").lastName("Mbopda").gender(GenderEnum.MALE).createdBy(createdBy).build();
            parent.setId(parentId);

            Person existing = Person.builder().firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE).createdBy(createdBy).build();
            existing.setId(existingId);

            CreateChildRequest req = CreateChildRequest.builder()
                    .firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE)
                    .existingPersonId(existingId).build();

            when(personRepository.findById(parentId)).thenReturn(Optional.of(parent));
            when(personRepository.findById(existingId)).thenReturn(Optional.of(existing));
            when(parentChildRepository.existsByParentIdAndChildId(parentId, existingId)).thenReturn(false);
            when(parentChildRepository.save(any(ParentChild.class))).thenAnswer(inv -> inv.getArgument(0));
            when(personVillageRepository.findVillageIdsByPersonId(existingId)).thenReturn(List.of());

            PersonDTO result = service.createChild(parentId, req, createdBy);

            assertThat(result.getId()).isEqualTo(existingId);
            // Pas de creation de nouvelle personne
            verify(personRepository, never()).save(any(Person.class));
            verify(parentChildRepository).save(parentChildCaptor.capture());
            assertThat(parentChildCaptor.getValue().getChildId()).isEqualTo(existingId);
        }

        @Test
        @DisplayName("Doit retourner l'existant si enfant deja lie (existingPersonId)")
        void shouldReturnExistingIfAlreadyLinkedByExistingPersonId() {
            UUID parentId = UUID.randomUUID();
            UUID existingId = UUID.randomUUID();
            UUID createdBy = UUID.randomUUID();

            Person parent = Person.builder().firstName("Kofi").lastName("Mbopda").gender(GenderEnum.MALE).createdBy(createdBy).build();
            parent.setId(parentId);

            Person existing = Person.builder().firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE).createdBy(createdBy).build();
            existing.setId(existingId);

            CreateChildRequest req = CreateChildRequest.builder()
                    .firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE)
                    .existingPersonId(existingId).build();

            when(personRepository.findById(parentId)).thenReturn(Optional.of(parent));
            when(personRepository.findById(existingId)).thenReturn(Optional.of(existing));
            when(parentChildRepository.existsByParentIdAndChildId(parentId, existingId)).thenReturn(true);
            when(personVillageRepository.findVillageIdsByPersonId(existingId)).thenReturn(List.of());

            PersonDTO result = service.createChild(parentId, req, createdBy);

            assertThat(result.getId()).isEqualTo(existingId);
            verify(parentChildRepository, never()).save(any(ParentChild.class));
        }

        @Test
        @DisplayName("Doit creer une demande d'association si coParentPersonId est fourni")
        void shouldCreateAssociationRequestWhenCoParentProvided() {
            UUID parentId = UUID.randomUUID();
            UUID coParentId = UUID.randomUUID();
            UUID createdBy = UUID.randomUUID();

            Person parent = Person.builder().firstName("Kofi").lastName("Mbopda").gender(GenderEnum.MALE).createdBy(createdBy).build();
            parent.setId(parentId);

            Person coParent = Person.builder().firstName("Ama").lastName("Ngon").gender(GenderEnum.FEMALE).createdBy(UUID.randomUUID()).build();
            coParent.setId(coParentId);

            CreateChildRequest req = CreateChildRequest.builder()
                    .firstName("Junior").lastName("Mbopda").gender(GenderEnum.MALE)
                    .coParentPersonId(coParentId).build();

            when(personRepository.findById(parentId)).thenReturn(Optional.of(parent));
            when(personRepository.findById(coParentId)).thenReturn(Optional.of(coParent));
            // email et birthDate null → findDuplicate ne fait aucun appel repo
            when(personRepository.save(any(Person.class))).thenAnswer(inv -> {
                Person p = inv.getArgument(0);
                if (p.getId() == null) p.setId(UUID.randomUUID());
                return p;
            });
            when(parentChildRepository.save(any(ParentChild.class))).thenAnswer(inv -> inv.getArgument(0));
            when(parentChildRepository.existsByParentIdAndChildId(eq(coParentId), any())).thenReturn(false);
            when(childAssociationRequestRepository.findByChildIdAndTargetParentId(any(), eq(coParentId))).thenReturn(Optional.empty());
            when(childAssociationRequestRepository.save(any(ChildAssociationRequest.class))).thenAnswer(inv -> {
                ChildAssociationRequest r = inv.getArgument(0);
                if (r.getId() == null) r.setId(UUID.randomUUID());
                return r;
            });
            when(personVillageRepository.findVillageIdsByPersonId(any())).thenReturn(List.of());

            service.createChild(parentId, req, createdBy);

            verify(childAssociationRequestRepository).save(carCaptor.capture());
            ChildAssociationRequest saved = carCaptor.getValue();
            assertThat(saved.getRequesterId()).isEqualTo(parentId);
            assertThat(saved.getTargetParentId()).isEqualTo(coParentId);
            assertThat(saved.getStatus()).isEqualTo(AssociationRequestStatus.PENDING);

            verify(eventPublisher).publishEvent(any(ChildAssociationRequestedEvent.class));
        }

        @Test
        @DisplayName("Ne doit pas creer de demande si le lien co-parent existe deja")
        void shouldNotCreateRequestIfCoParentLinkAlreadyExists() {
            UUID parentId = UUID.randomUUID();
            UUID coParentId = UUID.randomUUID();
            UUID createdBy = UUID.randomUUID();

            Person parent = Person.builder().firstName("Kofi").lastName("Mbopda").gender(GenderEnum.MALE).createdBy(createdBy).build();
            parent.setId(parentId);

            Person coParent = Person.builder().firstName("Ama").lastName("Ngon").gender(GenderEnum.FEMALE).createdBy(UUID.randomUUID()).build();
            coParent.setId(coParentId);

            CreateChildRequest req = CreateChildRequest.builder()
                    .firstName("Junior").lastName("Mbopda").gender(GenderEnum.MALE)
                    .coParentPersonId(coParentId).build();

            when(personRepository.findById(parentId)).thenReturn(Optional.of(parent));
            when(personRepository.findById(coParentId)).thenReturn(Optional.of(coParent));
            // email et birthDate null → findDuplicate ne fait aucun appel repo
            when(personRepository.save(any(Person.class))).thenAnswer(inv -> {
                Person p = inv.getArgument(0);
                if (p.getId() == null) p.setId(UUID.randomUUID());
                return p;
            });
            when(parentChildRepository.save(any(ParentChild.class))).thenAnswer(inv -> inv.getArgument(0));
            when(parentChildRepository.existsByParentIdAndChildId(eq(coParentId), any())).thenReturn(true);
            when(personVillageRepository.findVillageIdsByPersonId(any())).thenReturn(List.of());

            service.createChild(parentId, req, createdBy);

            verify(childAssociationRequestRepository, never()).save(any(ChildAssociationRequest.class));
            verify(eventPublisher, never()).publishEvent(any(ChildAssociationRequestedEvent.class));
        }

        @Test
        @DisplayName("Doit detecter un doublon par deduplication automatique et reutiliser la personne")
        void shouldDetectDuplicateByAutoDedup() {
            UUID parentId = UUID.randomUUID();
            UUID existingId = UUID.randomUUID();
            UUID createdBy = UUID.randomUUID();

            Person parent = Person.builder().firstName("Kofi").lastName("Mbopda").gender(GenderEnum.MALE).createdBy(createdBy).build();
            parent.setId(parentId);

            Person existing = Person.builder().firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE)
                    .birthDate(LocalDate.of(2020, 1, 1)).createdBy(UUID.randomUUID()).build();
            existing.setId(existingId);

            CreateChildRequest req = CreateChildRequest.builder()
                    .firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE)
                    .birthDate(LocalDate.of(2020, 1, 1)).build();

            when(personRepository.findById(parentId)).thenReturn(Optional.of(parent));
            // email null → findDuplicate cherche uniquement par nom+date+genre
            when(personRepository.findByNameBirthDateAndGender("Ama", "Mbopda", LocalDate.of(2020, 1, 1), GenderEnum.FEMALE))
                    .thenReturn(List.of(existing));
            when(parentChildRepository.existsByParentIdAndChildId(parentId, existingId)).thenReturn(false);
            when(parentChildRepository.save(any(ParentChild.class))).thenAnswer(inv -> inv.getArgument(0));
            when(personVillageRepository.findVillageIdsByPersonId(existingId)).thenReturn(List.of());

            PersonDTO result = service.createChild(parentId, req, createdBy);

            assertThat(result.getId()).isEqualTo(existingId);
            // Ne doit pas creer de nouvelle personne
            verify(personRepository, never()).save(any(Person.class));
        }
    }

    // ========================================================================
    // checkDuplicate
    // ========================================================================

    @Nested
    @DisplayName("checkDuplicate — Verification de doublons avant creation")
    class CheckDuplicateTests {

        @Test
        @DisplayName("Doit trouver un doublon par email")
        void shouldFindDuplicateByEmail() {
            UUID existingId = UUID.randomUUID();
            Person existing = Person.builder().firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE)
                    .email("ama@test.com").createdBy(UUID.randomUUID()).build();
            existing.setId(existingId);

            DuplicateCheckRequest req = DuplicateCheckRequest.builder()
                    .firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE)
                    .email("ama@test.com").build();

            when(personRepository.findByEmailIgnoreCase("ama@test.com")).thenReturn(Optional.of(existing));
            when(personVillageRepository.findVillageIdsByPersonId(existingId)).thenReturn(List.of());

            List<PersonDTO> result = service.checkDuplicate(req);

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getId()).isEqualTo(existingId);
        }

        @Test
        @DisplayName("Doit trouver un doublon par nom + prenom + date naissance + genre")
        void shouldFindDuplicateByNameBirthDateAndGender() {
            UUID existingId = UUID.randomUUID();
            Person existing = Person.builder().firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE)
                    .birthDate(LocalDate.of(2020, 1, 1)).createdBy(UUID.randomUUID()).build();
            existing.setId(existingId);

            DuplicateCheckRequest req = DuplicateCheckRequest.builder()
                    .firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE)
                    .birthDate(LocalDate.of(2020, 1, 1)).build();

            when(personRepository.findByNameBirthDateAndGender("Ama", "Mbopda", LocalDate.of(2020, 1, 1), GenderEnum.FEMALE))
                    .thenReturn(List.of(existing));
            when(personVillageRepository.findVillageIdsByPersonId(existingId)).thenReturn(List.of());

            List<PersonDTO> result = service.checkDuplicate(req);

            assertThat(result).hasSize(1);
            assertThat(result.get(0).getId()).isEqualTo(existingId);
        }

        @Test
        @DisplayName("Doit retourner une liste vide si aucun doublon")
        void shouldReturnEmptyIfNoDuplicate() {
            DuplicateCheckRequest req = DuplicateCheckRequest.builder()
                    .firstName("Unique").lastName("Name").gender(GenderEnum.MALE)
                    .birthDate(LocalDate.of(2000, 1, 1)).build();

            when(personRepository.findByNameBirthDateAndGender("Unique", "Name", LocalDate.of(2000, 1, 1), GenderEnum.MALE))
                    .thenReturn(List.of());

            List<PersonDTO> result = service.checkDuplicate(req);

            assertThat(result).isEmpty();
        }

        @Test
        @DisplayName("Ne doit pas retourner de doublons si email et birthDate sont null")
        void shouldReturnEmptyWhenNoEmailAndNoBirthDate() {
            DuplicateCheckRequest req = DuplicateCheckRequest.builder()
                    .firstName("Test").lastName("Person").gender(GenderEnum.MALE).build();

            List<PersonDTO> result = service.checkDuplicate(req);

            assertThat(result).isEmpty();
            verify(personRepository, never()).findByNameBirthDateAndGender(any(), any(), any(), any());
        }

        @Test
        @DisplayName("Doit deduper les resultats email + nom/date")
        void shouldDeduplicateEmailAndNameResults() {
            UUID existingId = UUID.randomUUID();
            Person existing = Person.builder().firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE)
                    .email("ama@test.com").birthDate(LocalDate.of(2020, 1, 1)).createdBy(UUID.randomUUID()).build();
            existing.setId(existingId);

            DuplicateCheckRequest req = DuplicateCheckRequest.builder()
                    .firstName("Ama").lastName("Mbopda").gender(GenderEnum.FEMALE)
                    .email("ama@test.com").birthDate(LocalDate.of(2020, 1, 1)).build();

            when(personRepository.findByEmailIgnoreCase("ama@test.com")).thenReturn(Optional.of(existing));
            when(personRepository.findByNameBirthDateAndGender("Ama", "Mbopda", LocalDate.of(2020, 1, 1), GenderEnum.FEMALE))
                    .thenReturn(List.of(existing));
            when(personVillageRepository.findVillageIdsByPersonId(existingId)).thenReturn(List.of());

            List<PersonDTO> result = service.checkDuplicate(req);

            // Meme personne trouvee par les 2 criteres — ne doit apparaitre qu'une fois
            assertThat(result).hasSize(1);
        }
    }

    // ========================================================================
    // acceptChildAssociation
    // ========================================================================

    @Nested
    @DisplayName("acceptChildAssociation — Acceptation d'une demande d'association")
    class AcceptChildAssociationTests {

        @Test
        @DisplayName("Doit creer le lien parent-enfant et passer le statut a ACCEPTED")
        void shouldCreateLinkAndAcceptRequest() {
            UUID requestId = UUID.randomUUID();
            UUID responderId = UUID.randomUUID();
            UUID childId = UUID.randomUUID();
            UUID requesterId = UUID.randomUUID();
            UUID targetParentId = UUID.randomUUID();

            ChildAssociationRequest request = ChildAssociationRequest.builder()
                    .childId(childId).requesterId(requesterId).targetParentId(targetParentId)
                    .status(AssociationRequestStatus.PENDING).build();
            request.setId(requestId);

            Person targetParent = Person.builder().firstName("Ama").lastName("Ngon").gender(GenderEnum.FEMALE)
                    .userId(responderId).createdBy(UUID.randomUUID()).build();
            targetParent.setId(targetParentId);

            Person child = Person.builder().firstName("Junior").lastName("Mbopda").gender(GenderEnum.MALE)
                    .createdBy(UUID.randomUUID()).build();
            child.setId(childId);

            when(childAssociationRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
            when(personRepository.findById(targetParentId)).thenReturn(Optional.of(targetParent));
            when(personRepository.findById(childId)).thenReturn(Optional.of(child));
            when(parentChildRepository.existsByParentIdAndChildId(targetParentId, childId)).thenReturn(false);
            when(parentChildRepository.save(any(ParentChild.class))).thenAnswer(inv -> inv.getArgument(0));
            when(childAssociationRequestRepository.save(any(ChildAssociationRequest.class))).thenAnswer(inv -> inv.getArgument(0));

            service.acceptChildAssociation(requestId, responderId);

            verify(parentChildRepository).save(parentChildCaptor.capture());
            ParentChild link = parentChildCaptor.getValue();
            assertThat(link.getParentId()).isEqualTo(targetParentId);
            assertThat(link.getChildId()).isEqualTo(childId);
            assertThat(link.getParentRole()).isEqualTo(ParentRoleEnum.MOTHER);
            assertThat(link.getParentType()).isEqualTo(ParentTypeEnum.BIOLOGICAL);

            assertThat(request.getStatus()).isEqualTo(AssociationRequestStatus.ACCEPTED);
            assertThat(request.getRespondedAt()).isNotNull();

            verify(eventPublisher).publishEvent(any(ParentChildLinkedEvent.class));
            verify(eventPublisher).publishEvent(any(ChildAssociationRespondedEvent.class));
        }

        @Test
        @DisplayName("Doit rejeter si la demande n'est pas PENDING")
        void shouldRejectIfRequestNotPending() {
            UUID requestId = UUID.randomUUID();
            UUID responderId = UUID.randomUUID();

            ChildAssociationRequest request = ChildAssociationRequest.builder()
                    .childId(UUID.randomUUID()).requesterId(UUID.randomUUID()).targetParentId(UUID.randomUUID())
                    .status(AssociationRequestStatus.ACCEPTED).build();
            request.setId(requestId);

            when(childAssociationRequestRepository.findById(requestId)).thenReturn(Optional.of(request));

            assertThatThrownBy(() -> service.acceptChildAssociation(requestId, responderId))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("deja ete traitee");
        }

        @Test
        @DisplayName("Doit rejeter si le responderId ne correspond pas au userId du co-parent")
        void shouldRejectIfNotTargetParentUser() {
            UUID requestId = UUID.randomUUID();
            UUID responderId = UUID.randomUUID();
            UUID targetParentId = UUID.randomUUID();

            ChildAssociationRequest request = ChildAssociationRequest.builder()
                    .childId(UUID.randomUUID()).requesterId(UUID.randomUUID()).targetParentId(targetParentId)
                    .status(AssociationRequestStatus.PENDING).build();
            request.setId(requestId);

            Person targetParent = Person.builder().firstName("Ama").lastName("Ngon").gender(GenderEnum.FEMALE)
                    .userId(UUID.randomUUID()) // different userId
                    .createdBy(UUID.randomUUID()).build();
            targetParent.setId(targetParentId);

            when(childAssociationRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
            when(personRepository.findById(targetParentId)).thenReturn(Optional.of(targetParent));

            assertThatThrownBy(() -> service.acceptChildAssociation(requestId, responderId))
                    .isInstanceOf(SecurityException.class)
                    .hasMessageContaining("autorise");
        }

        @Test
        @DisplayName("Doit rejeter si le co-parent n'a pas de userId")
        void shouldRejectIfTargetParentHasNoUserId() {
            UUID requestId = UUID.randomUUID();
            UUID responderId = UUID.randomUUID();
            UUID targetParentId = UUID.randomUUID();

            ChildAssociationRequest request = ChildAssociationRequest.builder()
                    .childId(UUID.randomUUID()).requesterId(UUID.randomUUID()).targetParentId(targetParentId)
                    .status(AssociationRequestStatus.PENDING).build();
            request.setId(requestId);

            Person targetParent = Person.builder().firstName("Ama").lastName("Ngon").gender(GenderEnum.FEMALE)
                    .userId(null)
                    .createdBy(UUID.randomUUID()).build();
            targetParent.setId(targetParentId);

            when(childAssociationRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
            when(personRepository.findById(targetParentId)).thenReturn(Optional.of(targetParent));

            assertThatThrownBy(() -> service.acceptChildAssociation(requestId, responderId))
                    .isInstanceOf(SecurityException.class);
        }

        @Test
        @DisplayName("Ne doit pas creer de doublon si le lien existe deja")
        void shouldNotCreateDuplicateLink() {
            UUID requestId = UUID.randomUUID();
            UUID responderId = UUID.randomUUID();
            UUID childId = UUID.randomUUID();
            UUID targetParentId = UUID.randomUUID();

            ChildAssociationRequest request = ChildAssociationRequest.builder()
                    .childId(childId).requesterId(UUID.randomUUID()).targetParentId(targetParentId)
                    .status(AssociationRequestStatus.PENDING).build();
            request.setId(requestId);

            Person targetParent = Person.builder().firstName("Ama").lastName("Ngon").gender(GenderEnum.FEMALE)
                    .userId(responderId).createdBy(UUID.randomUUID()).build();
            targetParent.setId(targetParentId);

            Person child = Person.builder().firstName("Junior").lastName("Mbopda").gender(GenderEnum.MALE)
                    .createdBy(UUID.randomUUID()).build();
            child.setId(childId);

            when(childAssociationRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
            when(personRepository.findById(targetParentId)).thenReturn(Optional.of(targetParent));
            when(personRepository.findById(childId)).thenReturn(Optional.of(child));
            when(parentChildRepository.existsByParentIdAndChildId(targetParentId, childId)).thenReturn(true);
            when(childAssociationRequestRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            service.acceptChildAssociation(requestId, responderId);

            // Lien existant = pas de nouveau save sur parentChildRepository
            verify(parentChildRepository, never()).save(any(ParentChild.class));
            // Mais la demande doit quand meme passer a ACCEPTED
            assertThat(request.getStatus()).isEqualTo(AssociationRequestStatus.ACCEPTED);
        }

        @Test
        @DisplayName("Doit lever une exception si la demande n'existe pas")
        void shouldThrowIfRequestNotFound() {
            UUID requestId = UUID.randomUUID();
            when(childAssociationRequestRepository.findById(requestId)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.acceptChildAssociation(requestId, UUID.randomUUID()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("non trouvee");
        }
    }

    // ========================================================================
    // rejectChildAssociation
    // ========================================================================

    @Nested
    @DisplayName("rejectChildAssociation — Refus d'une demande d'association")
    class RejectChildAssociationTests {

        @Test
        @DisplayName("Doit passer le statut a REJECTED et publier l'event")
        void shouldRejectAndPublishEvent() {
            UUID requestId = UUID.randomUUID();
            UUID responderId = UUID.randomUUID();
            UUID targetParentId = UUID.randomUUID();

            ChildAssociationRequest request = ChildAssociationRequest.builder()
                    .childId(UUID.randomUUID()).requesterId(UUID.randomUUID()).targetParentId(targetParentId)
                    .status(AssociationRequestStatus.PENDING).build();
            request.setId(requestId);

            Person targetParent = Person.builder().firstName("Ama").lastName("Ngon").gender(GenderEnum.FEMALE)
                    .userId(responderId).createdBy(UUID.randomUUID()).build();
            targetParent.setId(targetParentId);

            when(childAssociationRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
            when(personRepository.findById(targetParentId)).thenReturn(Optional.of(targetParent));
            when(childAssociationRequestRepository.save(any())).thenAnswer(inv -> inv.getArgument(0));

            service.rejectChildAssociation(requestId, responderId);

            assertThat(request.getStatus()).isEqualTo(AssociationRequestStatus.REJECTED);
            assertThat(request.getRespondedAt()).isNotNull();

            // Aucun lien parent-enfant ne doit etre cree
            verify(parentChildRepository, never()).save(any(ParentChild.class));

            verify(eventPublisher).publishEvent(any(ChildAssociationRespondedEvent.class));
        }

        @Test
        @DisplayName("Doit rejeter si la demande n'est pas PENDING")
        void shouldRejectIfNotPending() {
            UUID requestId = UUID.randomUUID();

            ChildAssociationRequest request = ChildAssociationRequest.builder()
                    .childId(UUID.randomUUID()).requesterId(UUID.randomUUID()).targetParentId(UUID.randomUUID())
                    .status(AssociationRequestStatus.REJECTED).build();
            request.setId(requestId);

            when(childAssociationRequestRepository.findById(requestId)).thenReturn(Optional.of(request));

            assertThatThrownBy(() -> service.rejectChildAssociation(requestId, UUID.randomUUID()))
                    .isInstanceOf(IllegalStateException.class)
                    .hasMessageContaining("deja ete traitee");
        }

        @Test
        @DisplayName("Doit rejeter si le responderId ne correspond pas")
        void shouldRejectIfWrongResponder() {
            UUID requestId = UUID.randomUUID();
            UUID responderId = UUID.randomUUID();
            UUID targetParentId = UUID.randomUUID();

            ChildAssociationRequest request = ChildAssociationRequest.builder()
                    .childId(UUID.randomUUID()).requesterId(UUID.randomUUID()).targetParentId(targetParentId)
                    .status(AssociationRequestStatus.PENDING).build();
            request.setId(requestId);

            Person targetParent = Person.builder().firstName("Ama").lastName("Ngon").gender(GenderEnum.FEMALE)
                    .userId(UUID.randomUUID()) // different userId
                    .createdBy(UUID.randomUUID()).build();
            targetParent.setId(targetParentId);

            when(childAssociationRequestRepository.findById(requestId)).thenReturn(Optional.of(request));
            when(personRepository.findById(targetParentId)).thenReturn(Optional.of(targetParent));

            assertThatThrownBy(() -> service.rejectChildAssociation(requestId, responderId))
                    .isInstanceOf(SecurityException.class)
                    .hasMessageContaining("autorise");
        }

        @Test
        @DisplayName("Doit lever une exception si la demande n'existe pas")
        void shouldThrowIfRequestNotFound() {
            UUID requestId = UUID.randomUUID();
            when(childAssociationRequestRepository.findById(requestId)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> service.rejectChildAssociation(requestId, UUID.randomUUID()))
                    .isInstanceOf(IllegalArgumentException.class)
                    .hasMessageContaining("non trouvee");
        }
    }
}
