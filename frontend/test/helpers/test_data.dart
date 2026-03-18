// Donnees de test centralisees pour tous les tests unitaires et widget.

// ── JSON bruts (comme retournes par l'API) ──────────────────────────

const userJson = {
  'id': 'u-001',
  'email': 'testeur@gwangmeu.test',
  'displayName': 'Jean Kouassi',
  'avatarUrl': 'https://cdn.example.com/avatar.jpg',
  'coverUrl': null,
  'role': 'MEMBRE',
  'country': 'CMR',
  'nativeLanguage': 'Bassa',
  'bio': 'Passione de genealogie.',
  'supabaseId': 'sb-001',
  'verified': true,
  'fatherName': 'Pierre Kouassi',
  'fatherOrigin': 'Edea',
  'motherName': 'Marie Njoh',
  'motherOrigin': 'Douala',
  'maritalStatus': 'MARRIED',
  'tribe': 'Bassa',
  'clan': 'Bakoko',
  'profession': 'Ingenieur',
  'residenceCity': 'Paris',
  'residenceCountry': 'France',
};

const userMinimalJson = {
  'id': 'u-002',
  'email': 'minimal@gwangmeu.test',
};

const villageJson = {
  'id': 'v-001',
  'name': 'Edea',
  'description': 'Ville industrielle au bord de la Sanaga.',
  'country': 'CMR',
  'region': 'Littoral',
  'continentCode': 'AF-CENTRAL',
  'latitude': 3.7986,
  'longitude': 10.1337,
  'primaryDialect': 'Bassa',
  'memberCount': 42,
  'verified': true,
  'foundedYear': 1900,
  'populationEstimate': 85000,
};

const villageMinimalJson = {
  'id': 'v-002',
  'name': 'Bafoussam',
  'country': 'CMR',
};

const postTextJson = {
  'id': 'p-001',
  'authorId': 'u-001',
  'villageId': 'v-001',
  'content': 'Les langues africaines sont les gardiens de notre ame collective.',
  'moderationStatus': 'APPROVED',
  'reactionCount': 5,
  'commentCount': 2,
  'isLive': false,
  'isAiSuggestion': false,
};

const postMediaJson = {
  'id': 'p-002',
  'authorId': 'u-001',
  'villageId': 'v-001',
  'content': 'Photo de famille.',
  'mediaUrl': 'https://cdn.example.com/photo.jpg',
  'mediaType': 'IMAGE',
  'moderationStatus': 'APPROVED',
};

const postLiveJson = {
  'id': 'p-003',
  'authorId': 'u-001',
  'villageId': 'v-001',
  'content': 'Live ceremonie traditionnelle.',
  'moderationStatus': 'APPROVED',
  'isLive': true,
  'liveViewerCount': 150,
};

const postAiJson = {
  'id': 'p-004',
  'authorId': 'u-001',
  'villageId': 'v-001',
  'content': 'Suggestion IA: lien familial probable.',
  'moderationStatus': 'APPROVED',
  'isAiSuggestion': true,
  'aiConfidence': '0.87',
  'aiDescription': 'Lien probable pere-fils.',
};

const postPendingJson = {
  'id': 'p-005',
  'authorId': 'u-001',
  'villageId': 'v-001',
  'content': 'Post en attente de moderation.',
  'moderationStatus': 'PENDING',
};

const postMultiMediaJson = {
  'id': 'p-006',
  'authorId': 'u-001',
  'villageId': 'v-001',
  'content': 'Galerie photos.',
  'mediaUrls': [
    'https://cdn.example.com/1.jpg',
    'https://cdn.example.com/2.jpg',
    'https://cdn.example.com/3.jpg',
  ],
  'moderationStatus': 'APPROVED',
};

const personJson = {
  'id': 'pe-001',
  'userId': 'u-001',
  'firstName': 'Jean',
  'lastName': 'Kouassi',
  'gender': 'MALE',
  'birthDate': '1990-05-15T00:00:00.000',
  'birthPlace': 'Edea',
  'isAlive': true,
  'clan': 'Bakoko',
  'totem': 'Tortue',
  'email': 'jean@test.com',
  'phone': '+237600000000',
  'privacy': 'PUBLIC',
  'status': 'ALIVE',
};

const personChildJson = {
  'id': 'pe-002',
  'firstName': 'Amara',
  'lastName': 'Kouassi',
  'gender': 'MALE',
  'birthDate': '2024-06-15T00:00:00.000',
  'isAlive': true,
  'clan': 'Bakoko',
  'privacy': 'FAMILY_ONLY',
  'status': 'ALIVE',
};

const personMinimalJson = {
  'id': 'pe-003',
  'firstName': 'Marie',
  'lastName': 'Njoh',
  'gender': 'FEMALE',
  'privacy': 'PUBLIC',
  'status': 'ALIVE',
};

const unionJson = {
  'id': 'un-001',
  'husbandId': 'pe-001',
  'wifeId': 'pe-003',
  'unionTypes': ['MARRIAGE_CIVIL', 'MARRIAGE_TRADITIONAL'],
  'unionOrder': 1,
  'startDate': '2015-08-20T00:00:00.000',
  'isActive': true,
  'isDotPaid': true,
  'dotPaidBy': 'pe-001',
  'dotDescription': 'Dot traditionnelle Bassa',
  'dotWitnesses': ['Chef du village', 'Oncle maternel'],
};

const familyTreeJson = {
  'subject': personJson,
  'father': [
    {
      'id': 'pe-010',
      'firstName': 'Pierre',
      'lastName': 'Kouassi',
      'gender': 'MALE',
      'privacy': 'PUBLIC',
      'status': 'ALIVE',
    }
  ],
  'mother': [
    {
      'id': 'pe-011',
      'firstName': 'Marie',
      'lastName': 'Njoh',
      'gender': 'FEMALE',
      'privacy': 'PUBLIC',
      'status': 'ALIVE',
    }
  ],
  'children': [personChildJson],
  'siblings': <Map<String, dynamic>>[],
  'unions': [unionJson],
  'paternalGP': <Map<String, dynamic>>[],
  'maternalGP': <Map<String, dynamic>>[],
  'cousins': <Map<String, dynamic>>[],
  'uncles': <Map<String, dynamic>>[],
  'pendingSuggestions': <Map<String, dynamic>>[],
};

const siblingJson = {
  'person': personMinimalJson,
  'type': 'FULL',
  'sharedParentId': 'pe-010',
};

const clanJson = {
  'id': 'cl-001',
  'name': 'Bakoko',
  'villageId': 'v-001',
  'description': 'Grande famille Bassa de Edea.',
  'personCount': 12,
};

const commentJson = {
  'id': 'co-001',
  'personId': 'pe-001',
  'authorId': 'u-001',
  'authorName': 'Jean Kouassi',
  'content': 'Mon grand-pere etait un chasseur reconnu.',
  'createdAt': '2025-01-15T10:30:00.000',
};

const aiSuggestionJson = {
  'id': 'ai-001',
  'personAId': 'pe-001',
  'personBId': 'pe-010',
  'suggestedRelation': 'FATHER',
  'confidence': 0.92,
  'reasons': ['Meme nom de famille', 'Meme village d\'origine'],
  'status': 'PENDING',
};

final notificationJson = <String, dynamic>{
  'id': 'n-001',
  'type': 'CHILD_ASSOCIATION_REQUEST',
  'title': 'Demande d\'association',
  'body': 'Jean Kouassi souhaite vous associer comme parent de Amara.',
  'data': <String, dynamic>{'requestId': 'req-001', 'childName': 'Amara'},
  'read': false,
};

final notificationReadJson = <String, dynamic>{
  'id': 'n-002',
  'type': 'PARENT_ADDED',
  'title': 'Parent ajoute',
  'body': 'Pierre a ete ajoute comme pere.',
  'data': <String, dynamic>{},
  'read': true,
};

const chatGroupJson = {
  'id': 'cg-001',
  'villageId': 'v-001',
  'name': 'General Edea',
  'description': 'Discussion generale',
  'type': 'GENERAL',
  'memberCount': 15,
  'createdBy': 'u-001',
};

const chatMessageJson = {
  'id': 'cm-001',
  'groupId': 'cg-001',
  'senderId': 'u-001',
  'senderName': 'Jean Kouassi',
  'content': 'Bonjour la communaute!',
  'type': 'TEXT',
};

const countryJson = {
  'id': 'c-001',
  'isoCode': 'CMR',
  'name': 'Cameroun',
  'continentCode': 'AF-CENTRAL',
  'flagEmoji': '\u{1F1E8}\u{1F1F2}',
  'phoneCode': '+237',
  'villageCount': 3,
};

const languageJson = {
  'id': 'l-001',
  'name': 'French',
  'nameLocal': 'Francais',
  'official': true,
};

const villageMemberJson = {
  'userId': 'u-001',
  'displayName': 'Jean Kouassi',
  'avatarUrl': 'https://cdn.example.com/avatar.jpg',
  'type': 'MEMBER',
  'joinedAt': '2025-01-10T00:00:00.000',
};
