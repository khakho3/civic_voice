import 'package:civic_voice/models/trust_standing.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/features/citizen/models/citizen_profile.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> standingPayload({double stars = 3.5, bool low = false}) =>
    {
      'stars': stars,
      'outOf': 5,
      'label': 'Server standing',
      'lowStanding': low,
      'nextStep': stars == 5 ? null : {'stars': 4.5, 'resolvedReportsAway': 7},
    };
Map<String, dynamic> standingUser({
  String uid = 'uid-A',
  String id = 'account-A',
  String role = 'CITIZEN',
  bool guest = false,
  bool active = true,
  Object? rating,
}) => {
  'id': id,
  'publicId': 'CIT-TEST',
  'firebaseUid': uid,
  'role': role,
  'fullName': 'Citizen fixture',
  'isGuest': guest,
  'active': active,
  'trustRating': rating ?? standingPayload(),
};

void main() {
  test(
    'fractional stars, server milestone and flag round-trip without scoring',
    () {
      final raw = standingPayload(stars: 3.7, low: true);
      final data = TrustStandingData.fromJson({...raw, 'trustScore': 999});
      expect(data!.stars, 3.7);
      expect(data.lowStanding, isTrue);
      expect(data.scoreLabel, '3.7/5');
      expect(data.milestone, '7 more resolved reports to reach 4.5 stars.');
      expect(data.toJson(), raw);
      expect(data.toJson().containsKey('trustScore'), isFalse);
    },
  );
  test(
    'highest standing requires an explicit server ceiling and null milestone',
    () {
      final data = TrustStandingData.fromJson(standingPayload(stars: 5));
      expect(data!.milestone, 'You have reached the highest standing.');
      expect(
        TrustStandingData.fromJson({...standingPayload(), 'nextStep': null}),
        isNull,
      );
    },
  );
  final invalid = <Object?>[
    null,
    [],
    {},
    for (final value in [double.nan, double.infinity, -1, 0, 5.1, '3.5', true])
      {...standingPayload(), 'stars': value},
    {...standingPayload(), 'outOf': 0},
    {...standingPayload()}..remove('outOf'),
    {...standingPayload(), 'label': '   '},
    {...standingPayload(), 'lowStanding': 'false'},
    {...standingPayload()}..remove('lowStanding'),
    {...standingPayload()}..remove('nextStep'),
    {
      ...standingPayload(),
      'nextStep': {'stars': 3.5, 'resolvedReportsAway': 1},
    },
    {
      ...standingPayload(),
      'nextStep': {'stars': 6, 'resolvedReportsAway': 1},
    },
    {
      ...standingPayload(),
      'nextStep': {'stars': double.nan, 'resolvedReportsAway': 1},
    },
    for (final count in [0, -1, 2.5, '2', true, null])
      {
        ...standingPayload(),
        'nextStep': {'stars': 4, 'resolvedReportsAway': count},
      },
  ];
  for (var i = 0; i < invalid.length; i++) {
    test('malformed standing is hidden, case $i', () {
      expect(TrustStandingData.fromJson(invalid[i]), isNull);
    });
  }
  for (final role in ['ADMIN', 'MUNICIPAL', 'MINISTRY', 'MAINTENANCE']) {
    test('$role cannot carry citizen standing into a client role model', () {
      expect(SyncedUser.fromJson(standingUser(role: role)).trustRating, isNull);
    });
  }
  test(
    'sync and Citizen profile mapping retain standing while guest/inactive omit it',
    () {
      final user = SyncedUser.fromJson(standingUser());
      expect(user.trustRating!.stars, 3.5);
      final profile = CitizenProfile.fromMap({
        'id': 'A',
        'trustRating': user.trustRating!.toJson(),
      });
      expect(profile.copyWith(fullName: 'Edited').trustRating!.stars, 3.5);
      expect(
        CitizenProfile.fromMap(profile.toMap()).trustRating!.toJson(),
        profile.trustRating!.toJson(),
      );
      expect(profile.copyWith(isGuest: true).trustRating, isNull);
      expect(profile.copyWith(clearTrustRating: true).trustRating, isNull);
      expect(
        SyncedUser.fromJson(standingUser(guest: true)).trustRating,
        isNull,
      );
      expect(
        SyncedUser.fromJson(standingUser(active: false)).trustRating,
        isNull,
      );
      expect(
        CitizenProfile.fromMap({
          ...profile.toMap(),
          'isGuest': true,
        }).trustRating,
        isNull,
      );
    },
  );
}
