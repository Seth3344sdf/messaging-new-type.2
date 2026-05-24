import 'dart:math';

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';

class SeededData {
  final AppUser me;
  final List<AppUser> users;
  final List<Conversation> conversations;

  const SeededData({
    required this.me,
    required this.users,
    required this.conversations,
  });
}

typedef _Line = ({String text, bool fromMe, int minsAgo, bool isAi});

_Line _l(String text, bool fromMe, int minsAgo, {bool isAi = false}) =>
    (text: text, fromMe: fromMe, minsAgo: minsAgo, isAi: isAi);

class MockData {
  MockData._();

  static SeededData build({required AppUser pulse}) {
    final me = AppUser(
      id: 'u_me',
      name: 'Seth Abraham',
      avatarId: 'u:u_me',
      presence: Presence.online,
      status: 'shipping',
    );

    final users = <AppUser>[
      AppUser(id: 'u_1', name: 'Jamie Morales', avatarId: 'u:u_1', presence: Presence.online, status: 'flow state'),
      AppUser(id: 'u_2', name: 'Sana Reyes', avatarId: 'u:u_2', presence: Presence.idle, status: 'back in 10'),
      AppUser(id: 'u_3', name: 'Theo Kim', avatarId: 'u:u_3', presence: Presence.online, status: 'pairing'),
      AppUser(id: 'u_4', name: 'Lena Park', avatarId: 'u:u_4', presence: Presence.offline, status: 'ooo'),
      AppUser(id: 'u_5', name: 'Beni Adler', avatarId: 'u:u_5', presence: Presence.online, status: 'designing'),
      AppUser(id: 'u_6', name: 'Mira Okafor', avatarId: 'u:u_6', presence: Presence.online, status: 'customer calls'),
      AppUser(id: 'u_7', name: 'Diego Salas', avatarId: 'u:u_7', presence: Presence.idle, status: 'lunch'),
      AppUser(id: 'u_8', name: 'Priya Desai', avatarId: 'u:u_8', presence: Presence.online, status: 'heads down'),
    ];

    final rnd = Random(7);
    final now = DateTime.now();
    DateTime t(int minsAgo) => now.subtract(Duration(minutes: minsAgo));

    // --- 1:1 conversations ---
    final directSeeds = <({AppUser other, List<_Line> lines})>[
      (other: users[0], lines: [
        _l('got a sec? quick q on the migration', false, 540),
        _l('go', true, 538),
        _l('rollback plan?', false, 537),
        _l('flag-gated. pulse, what is the rollback again?', true, 536),
        _l('flip the flag off. legacy handler takes over. ~30s.', false, 535, isAi: true),
        _l('perfect', false, 530),
      ]),
      (other: users[1], lines: [
        _l('coffee tomorrow?', false, 1200),
        _l('yes 9am', true, 1198),
        _l('bringing q3 notes', false, 1190),
        _l('bring snacks', true, 1180),
      ]),
      (other: users[2], lines: [
        _l('deploy is green', false, 30),
        _l('nice', true, 28),
        _l('watching dashboards', false, 26),
        _l('pulse anything weird last hour?', true, 24),
        _l('p99 flat. errors flat. no spikes.', false, 23, isAi: true),
      ]),
      (other: users[3], lines: [
        _l('signing off', false, 60 * 18),
        _l('have a good one', true, 60 * 18 - 2),
      ]),
      (other: users[4], lines: [
        _l('pushed the new component', false, 120),
        _l('looks clean', true, 118),
        _l('reactions feel better now', false, 116),
        _l('agreed', true, 110),
        _l('pulse give me 2 cta options', true, 108),
        _l('1) "jump in"  2) "start the thread"', false, 107, isAi: true),
      ]),
      (other: users[5], lines: [
        _l('customer wants a demo friday', false, 240),
        _l('send the brief', true, 238),
        _l('on it', false, 236),
      ]),
      (other: users[6], lines: [
        _l('lunch?', false, 200),
        _l('five', true, 198),
      ]),
      (other: users[7], lines: [
        _l('shipped the avatar picker', false, 90),
        _l('smooth', true, 88),
        _l('adding generate-more next', false, 86),
      ]),
      (other: users[0], lines: [
        _l('side thread: icon brainstorm', false, 900),
        _l('go', true, 898),
        _l('leaf, flame, wave, sun', false, 896),
      ]),
      (other: users[2], lines: [
        _l('standup notes?', false, 3000),
        _l('posted', true, 2998),
      ]),
      (other: users[5], lines: [
        _l('pulse drafted the follow-up. it is decent.', false, 1500),
        _l('send it', true, 1498),
      ]),
      (other: users[7], lines: [
        _l('friday lunch?', false, 4000),
        _l('in', true, 3998),
      ]),
    ];

    final conversations = <Conversation>[];

    for (var i = 0; i < directSeeds.length; i++) {
      final seed = directSeeds[i];
      final msgs = <Message>[];
      for (var j = 0; j < seed.lines.length; j++) {
        final line = seed.lines[j];
        msgs.add(Message(
          id: 'm_${i}_$j',
          authorId: line.isAi
              ? pulse.id
              : (line.fromMe ? me.id : seed.other.id),
          text: line.text,
          sentAt: t(line.minsAgo),
          read: line.fromMe ? rnd.nextBool() : true,
          isAi: line.isAi,
        ));
      }
      msgs.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      final unread = msgs.where((m) => m.authorId != me.id && !m.read).length;
      conversations.add(Conversation(
        id: 'c_$i',
        participantIds: [me.id, seed.other.id, pulse.id],
        messages: msgs,
        unread: unread,
      ));
    }

    // --- Group chats ---
    final groupSeeds = <({String name, List<int> memberIdx, List<_Line> lines, int unread})>[
      (
        name: 'Launch Room',
        memberIdx: [0, 2, 4, 7],
        unread: 2,
        lines: [
          _l('two more days. how are we feeling?', false, 220),
          _l('good. last copy round today.', true, 218),
          _l('demo video almost done', false, 210),
          _l('pulse — anything still open?', true, 200),
          _l('two: pricing page links + onboarding screenshot.', false, 199, isAi: true),
          _l('on it', false, 60),
          _l('🔥', false, 10),
        ],
      ),
      (
        name: 'Design Crit',
        memberIdx: [4, 5, 7],
        unread: 0,
        lines: [
          _l('posted the new home v3', false, 500),
          _l('softer. love it.', true, 498),
          _l('typography is calmer too', false, 496),
          _l('agreed', true, 494),
        ],
      ),
      (
        name: 'Lunch Crew',
        memberIdx: [1, 3, 6],
        unread: 0,
        lines: [
          _l('thai or pizza', false, 800),
          _l('thai', true, 798),
          _l('thai', false, 797),
          _l('thai it is', false, 796),
        ],
      ),
      (
        name: 'AI Lab',
        memberIdx: [0, 2, 5, 7],
        unread: 1,
        lines: [
          _l('new eval results are up', false, 720),
          _l('huge jump on the reasoning set', true, 718),
          _l('pulse, summarize?', false, 716),
          _l('avg pass rate +18%. biggest gains on multi-step queries.', false, 715, isAi: true),
          _l('nice', true, 700),
        ],
      ),
    ];

    for (var i = 0; i < groupSeeds.length; i++) {
      final seed = groupSeeds[i];
      final memberIds = seed.memberIdx.map((idx) => users[idx].id).toList();
      final groupId = 'g_seed_$i';
      final msgs = <Message>[];
      for (var j = 0; j < seed.lines.length; j++) {
        final line = seed.lines[j];
        final author = line.isAi
            ? pulse.id
            : (line.fromMe ? me.id : memberIds[j % memberIds.length]);
        msgs.add(Message(
          id: 'gm_${i}_$j',
          authorId: author,
          text: line.text,
          sentAt: t(line.minsAgo),
          read: line.fromMe ? rnd.nextBool() : true,
          isAi: line.isAi,
        ));
      }
      msgs.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      conversations.add(Conversation(
        id: groupId,
        participantIds: [me.id, ...memberIds, pulse.id],
        messages: msgs,
        isGroup: true,
        groupName: seed.name,
        groupAvatarId: 'gav:$groupId',
        unread: seed.unread,
      ));
    }

    return SeededData(
      me: me,
      users: users,
      conversations: conversations,
    );
  }
}
