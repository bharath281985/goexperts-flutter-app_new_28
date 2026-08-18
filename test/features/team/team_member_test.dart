import 'package:flutter_test/flutter_test.dart';
import 'package:goexperts_app/features/team/domain/team_member.dart';

void main() {
  test('parses the team members response payload', () {
    final result = TeamMembersResult.fromJson({
      'members': [
        {
          'id': 'TM-M123ABC',
          'name': 'John Doe',
          'email': 'john@example.com',
          'role': 'Developer',
          'department': 'Engineering',
          'status': 'invited',
          'createdAt': '2026-08-18T10:00:00.000Z',
        },
      ],
      'total': 1,
    });

    expect(result.total, 1);
    expect(result.members, hasLength(1));
    expect(result.members.single.id, 'TM-M123ABC');
    expect(result.members.single.department, 'Engineering');
    expect(result.members.single.createdAt, isNotNull);
  });

  test('handles absent and malformed team data safely', () {
    final result = TeamMembersResult.fromJson({'total': 'invalid'});

    expect(result.total, 0);
    expect(result.members, isEmpty);
  });

  test('parses live API format where data is directly a list', () {
    final result = TeamMembersResult.fromJson([
      {
        'id': 'TM-MSYCBPT2',
        'name': 'Bhanu',
        'email': 'bhanupra039@gmail.com',
        'role': 'Channel Sales Manager',
        'status': 'invited',
        'createdAt': '2026-08-18T07:27:47.558Z',
      },
    ]);

    expect(result.total, 1);
    expect(result.members.single.name, 'Bhanu');
    expect(result.members.single.role, 'Channel Sales Manager');
  });
}
