import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gwangmeu/features/genealogy/services/genealogy_api_service.dart';

import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

void main() {
  late MockApiClient mockApi;
  late GenealogyApiService service;

  setUp(() {
    mockApi = MockApiClient();
    service = GenealogyApiService(mockApi);
  });

  group('GenealogyApiService', () {
    // ── getMyPerson ─────────────────────────────────────────

    test('getMyPerson retourne une PersonGenealogy', () async {
      when(() => mockApi.get('/api/v1/persons/me'))
          .thenAnswer((_) async => {'data': personJson});

      final person = await service.getMyPerson();

      expect(person.id, 'pe-001');
      expect(person.firstName, 'Jean');
      verify(() => mockApi.get('/api/v1/persons/me')).called(1);
    });

    // ── getFullTree ─────────────────────────────────────────

    test('getFullTree retourne un FamilyTree', () async {
      when(() => mockApi.get('/api/v1/genealogy/tree/pe-001'))
          .thenAnswer((_) async => {'data': familyTreeJson});

      final tree = await service.getFullTree('pe-001');

      expect(tree.subject.id, 'pe-001');
      expect(tree.father, hasLength(1));
      expect(tree.mother, hasLength(1));
      expect(tree.children, hasLength(1));
      verify(() => mockApi.get('/api/v1/genealogy/tree/pe-001')).called(1);
    });

    // ── createPerson ────────────────────────────────────────

    test('createPerson appelle POST et retourne une personne', () async {
      final data = {'firstName': 'Paul', 'lastName': 'Njoh', 'gender': 'MALE'};
      when(() => mockApi.post('/api/v1/persons', data: data))
          .thenAnswer((_) async => {'data': personMinimalJson});

      final person = await service.createPerson(data);

      expect(person.firstName, 'Marie'); // personMinimalJson
      verify(() => mockApi.post('/api/v1/persons', data: data)).called(1);
    });

    // ── getPersonById ───────────────────────────────────────

    test('getPersonById retourne la bonne personne', () async {
      when(() => mockApi.get('/api/v1/persons/pe-001'))
          .thenAnswer((_) async => {'data': personJson});

      final person = await service.getPersonById('pe-001');

      expect(person.id, 'pe-001');
      expect(person.firstName, 'Jean');
    });

    // ── updatePerson ────────────────────────────────────────

    test('updatePerson appelle PUT et retourne la personne mise a jour',
        () async {
      final data = {'firstName': 'Jean-Paul'};
      when(() => mockApi.put('/api/v1/persons/pe-001', data: data))
          .thenAnswer((_) async => {'data': personJson});

      final person = await service.updatePerson('pe-001', data);

      expect(person.id, 'pe-001');
      verify(() => mockApi.put('/api/v1/persons/pe-001', data: data)).called(1);
    });

    // ── deletePerson ────────────────────────────────────────

    test('deletePerson appelle DELETE', () async {
      when(() => mockApi.delete('/api/v1/persons/pe-001'))
          .thenAnswer((_) async {});

      await service.deletePerson('pe-001');

      verify(() => mockApi.delete('/api/v1/persons/pe-001')).called(1);
    });

    // ── searchPersonsByClan ─────────────────────────────────

    test('searchPersonsByClan retourne une liste', () async {
      when(() => mockApi.get(
            '/api/v1/persons/search',
            queryParameters: {'clan': 'Bakoko', 'q': 'Jean'},
          )).thenAnswer((_) async => {
            'data': [personJson]
          });

      final persons =
          await service.searchPersonsByClan('Bakoko', query: 'Jean');

      expect(persons, hasLength(1));
      expect(persons.first.clan, 'Bakoko');
    });

    test('searchPersonsByClan sans query', () async {
      when(() => mockApi.get(
            '/api/v1/persons/search',
            queryParameters: {'clan': 'Bakoko', 'q': ''},
          )).thenAnswer((_) async => {
            'data': [personJson, personMinimalJson]
          });

      final persons = await service.searchPersonsByClan('Bakoko');

      expect(persons, hasLength(2));
    });

    // ── getClansByVillage ───────────────────────────────────

    test('getClansByVillage retourne une liste de clans', () async {
      when(() => mockApi.get('/api/v1/persons/village/v-001/clans'))
          .thenAnswer((_) async => {
                'data': [clanJson]
              });

      final clans = await service.getClansByVillage('v-001');

      expect(clans, hasLength(1));
      expect(clans.first.name, 'Bakoko');
    });

    // ── createChild ─────────────────────────────────────────

    test('createChild envoie les bons parametres', () async {
      when(() => mockApi.post(
            '/api/v1/persons/pe-001/children',
            data: {
              'firstName': 'Amara',
              'lastName': 'Kouassi',
              'gender': 'MALE',
              'birthDate': '2024-06-15',
              'clan': 'Bakoko',
              'parentType': 'BIOLOGICAL',
            },
          )).thenAnswer((_) async => {'data': personChildJson});

      final child = await service.createChild(
        parentId: 'pe-001',
        firstName: 'Amara',
        lastName: 'Kouassi',
        gender: 'MALE',
        birthDate: '2024-06-15',
        clan: 'Bakoko',
      );

      expect(child.firstName, 'Amara');
    });

    test('createChild avec co-parent', () async {
      when(() => mockApi.post(
            '/api/v1/persons/pe-001/children',
            data: {
              'firstName': 'Amara',
              'lastName': 'Kouassi',
              'gender': 'MALE',
              'parentType': 'BIOLOGICAL',
              'coParentPersonId': 'pe-003',
            },
          )).thenAnswer((_) async => {'data': personChildJson});

      final child = await service.createChild(
        parentId: 'pe-001',
        firstName: 'Amara',
        lastName: 'Kouassi',
        gender: 'MALE',
        coParentPersonId: 'pe-003',
      );

      expect(child.firstName, 'Amara');
    });

    // ── checkDuplicate ──────────────────────────────────────

    test('checkDuplicate retourne une liste de doublons', () async {
      when(() => mockApi.post('/api/v1/persons/check-duplicate', data: {
            'firstName': 'Jean',
            'lastName': 'Kouassi',
            'gender': 'MALE',
          })).thenAnswer((_) async => {
            'data': [personJson]
          });

      final duplicates = await service.checkDuplicate(
        firstName: 'Jean',
        lastName: 'Kouassi',
        gender: 'MALE',
      );

      expect(duplicates, hasLength(1));
    });

    test('checkDuplicate retourne liste vide si pas de doublon', () async {
      when(() => mockApi.post('/api/v1/persons/check-duplicate', data: {
            'firstName': 'Xyz',
            'lastName': 'Abc',
            'gender': 'MALE',
          })).thenAnswer((_) async => {'data': <Map<String, dynamic>>[]});

      final duplicates = await service.checkDuplicate(
        firstName: 'Xyz',
        lastName: 'Abc',
        gender: 'MALE',
      );

      expect(duplicates, isEmpty);
    });

    // ── linkParentChild ─────────────────────────────────────

    test('linkParentChild appelle POST avec les bons parametres', () async {
      when(() => mockApi.post('/api/v1/genealogy/link/parent-child', data: {
            'parentId': 'pe-010',
            'childId': 'pe-001',
            'role': 'FATHER',
            'type': 'BIOLOGICAL',
          })).thenAnswer((_) async => <String, dynamic>{});

      await service.linkParentChild(
        parentId: 'pe-010',
        childId: 'pe-001',
        role: 'FATHER',
      );

      verify(() => mockApi.post('/api/v1/genealogy/link/parent-child',
          data: any(named: 'data'))).called(1);
    });

    // ── unlinkParentChild ───────────────────────────────────

    test('unlinkParentChild appelle DELETE', () async {
      when(() => mockApi.delete(
              '/api/v1/genealogy/link/parent-child?parentId=pe-010&childId=pe-001'))
          .thenAnswer((_) async {});

      await service.unlinkParentChild('pe-010', 'pe-001');

      verify(() => mockApi.delete(any())).called(1);
    });

    // ── getParents ──────────────────────────────────────────

    test('getParents retourne les parents', () async {
      when(() => mockApi.get('/api/v1/genealogy/pe-001/parents'))
          .thenAnswer((_) async => {
                'data': [personMinimalJson]
              });

      final parents = await service.getParents('pe-001');

      expect(parents, hasLength(1));
      expect(parents.first.firstName, 'Marie');
    });

    // ── getChildren ─────────────────────────────────────────

    test('getChildren retourne les enfants', () async {
      when(() => mockApi.get('/api/v1/genealogy/pe-001/children'))
          .thenAnswer((_) async => {
                'data': [personChildJson]
              });

      final children = await service.getChildren('pe-001');

      expect(children, hasLength(1));
      expect(children.first.firstName, 'Amara');
    });

    // ── getSiblings ─────────────────────────────────────────

    test('getSiblings retourne la fratrie', () async {
      when(() => mockApi.get('/api/v1/genealogy/pe-001/siblings'))
          .thenAnswer((_) async => {
                'data': [personMinimalJson]
              });

      final siblings = await service.getSiblings('pe-001');

      expect(siblings, hasLength(1));
    });

    // ── Unions ──────────────────────────────────────────────

    test('createUnion appelle POST et retourne une union', () async {
      final data = {'husbandId': 'pe-001', 'wifeId': 'pe-003'};
      when(() => mockApi.post('/api/v1/unions', data: data))
          .thenAnswer((_) async => {'data': unionJson});

      final union = await service.createUnion(data);

      expect(union.husbandId, 'pe-001');
      expect(union.isActive, true);
    });

    test('getUnionsByPerson retourne les unions', () async {
      when(() => mockApi.get('/api/v1/unions/person/pe-001'))
          .thenAnswer((_) async => {
                'data': [unionJson]
              });

      final unions = await service.getUnionsByPerson('pe-001');

      expect(unions, hasLength(1));
    });

    // ── Modification enfant ─────────────────────────────────

    test('requestChildModification appelle POST', () async {
      final changes = {'firstName': 'Amara-Kwame'};
      when(() => mockApi.post(
            '/api/v1/genealogy/persons/pe-002/modification-request',
            data: changes,
          )).thenAnswer((_) async => <String, dynamic>{});

      await service.requestChildModification('pe-002', changes);

      verify(() => mockApi.post(
            '/api/v1/genealogy/persons/pe-002/modification-request',
            data: changes,
          )).called(1);
    });

    test('acceptModificationRequest appelle POST', () async {
      when(() => mockApi.post(
              '/api/v1/genealogy/modification-requests/req-001/accept'))
          .thenAnswer((_) async => <String, dynamic>{});

      await service.acceptModificationRequest('req-001');

      verify(() => mockApi
              .post('/api/v1/genealogy/modification-requests/req-001/accept'))
          .called(1);
    });

    test('rejectModificationRequest appelle POST', () async {
      when(() => mockApi.post(
              '/api/v1/genealogy/modification-requests/req-001/reject'))
          .thenAnswer((_) async => <String, dynamic>{});

      await service.rejectModificationRequest('req-001');

      verify(() => mockApi
              .post('/api/v1/genealogy/modification-requests/req-001/reject'))
          .called(1);
    });

    // ── Child Association ───────────────────────────────────

    test('acceptChildAssociation appelle POST', () async {
      when(() => mockApi
              .post('/api/v1/genealogy/child-associations/req-001/accept'))
          .thenAnswer((_) async => <String, dynamic>{});

      await service.acceptChildAssociation('req-001');

      verify(() => mockApi
              .post('/api/v1/genealogy/child-associations/req-001/accept'))
          .called(1);
    });

    test('rejectChildAssociation appelle POST', () async {
      when(() => mockApi
              .post('/api/v1/genealogy/child-associations/req-001/reject'))
          .thenAnswer((_) async => <String, dynamic>{});

      await service.rejectChildAssociation('req-001');

      verify(() => mockApi
              .post('/api/v1/genealogy/child-associations/req-001/reject'))
          .called(1);
    });

    // ── Invitations ─────────────────────────────────────────

    test('invitePerson envoie les bons parametres', () async {
      when(() => mockApi.post('/api/v1/invitations', data: {
            'personId': 'pe-001',
            'invitationType': 'PARENT',
            'email': 'invite@test.com',
          })).thenAnswer((_) async => {
            'data': {'invitationId': 'inv-001', 'token': 'abc123'}
          });

      final result = await service.invitePerson(
        personId: 'pe-001',
        email: 'invite@test.com',
      );

      expect(result['token'], 'abc123');
    });

    // ── Commentaires ────────────────────────────────────────

    test('getPersonComments retourne une liste', () async {
      when(() => mockApi.get('/api/v1/persons/pe-001/comments'))
          .thenAnswer((_) async => {
                'data': [commentJson]
              });

      final comments = await service.getPersonComments('pe-001');

      expect(comments, hasLength(1));
      expect(comments.first.content, contains('chasseur'));
    });

    test('addPersonComment appelle POST', () async {
      when(() => mockApi.post('/api/v1/persons/pe-001/comments', data: {
            'content': 'Super histoire!',
          })).thenAnswer((_) async => {'data': commentJson});

      final comment =
          await service.addPersonComment('pe-001', 'Super histoire!');

      expect(comment.authorName, 'Jean Kouassi');
    });

    test('deletePersonComment appelle DELETE', () async {
      when(() => mockApi.delete('/api/v1/persons/pe-001/comments/co-001'))
          .thenAnswer((_) async {});

      await service.deletePersonComment('pe-001', 'co-001');

      verify(() => mockApi.delete('/api/v1/persons/pe-001/comments/co-001'))
          .called(1);
    });

    // ── AI Suggestions ──────────────────────────────────────

    test('generateAiSuggestions appelle POST et retourne des suggestions',
        () async {
      when(() => mockApi.post('/api/v1/genealogy/ai/suggest/pe-001'))
          .thenAnswer((_) async => {
                'data': [aiSuggestionJson]
              });

      final suggestions = await service.generateAiSuggestions('pe-001');

      expect(suggestions, hasLength(1));
      expect(suggestions.first.confidence, 0.92);
    });

    test('getPendingSuggestions retourne les suggestions en attente', () async {
      when(() => mockApi.get('/api/v1/genealogy/ai/suggestions/pe-001'))
          .thenAnswer((_) async => {
                'data': [aiSuggestionJson]
              });

      final suggestions = await service.getPendingSuggestions('pe-001');

      expect(suggestions, hasLength(1));
      expect(suggestions.first.status, 'PENDING');
    });

    test('reviewSuggestion accepte une suggestion', () async {
      when(() => mockApi.put(
            '/api/v1/genealogy/ai/suggestions/ai-001/review',
            data: {'accepted': true},
          )).thenAnswer((_) async => {
            'data': {...aiSuggestionJson, 'status': 'ACCEPTED'}
          });

      final suggestion = await service.reviewSuggestion('ai-001', true);

      expect(suggestion.status, 'ACCEPTED');
    });

    // ── Erreurs ─────────────────────────────────────────────

    test('getMyPerson propage les erreurs API', () async {
      when(() => mockApi.get('/api/v1/persons/me'))
          .thenThrow(Exception('Erreur reseau'));

      expect(
        () => service.getMyPerson(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
