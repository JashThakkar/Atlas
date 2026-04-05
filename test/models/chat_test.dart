import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/models/chat.dart';
import 'package:atlas/models/message.dart';

void main() {
  group('ChatRoom', () {
    group('getChatId', () {
      test('returns alphabetically sorted user IDs joined by underscore', () {
        final id = ChatRoom.getChatId('userB', 'userA');
        expect(id, 'userA_userB');
      });

      test('is symmetric: same result regardless of argument order', () {
        final id1 = ChatRoom.getChatId('alice', 'bob');
        final id2 = ChatRoom.getChatId('bob', 'alice');
        expect(id1, id2);
      });

      test('handles IDs that are already in sorted order', () {
        final id = ChatRoom.getChatId('alpha', 'beta');
        expect(id, 'alpha_beta');
      });

      test('produces unique IDs for different user pairs', () {
        final id1 = ChatRoom.getChatId('user-1', 'user-2');
        final id2 = ChatRoom.getChatId('user-1', 'user-3');
        expect(id1, isNot(equals(id2)));
      });
    });

    test('constructor sets all fields correctly', () {
      final now = DateTime(2024, 6, 1, 10, 0);
      final room = ChatRoom(
        id: 'room-1',
        participants: ['alice', 'bob'],
        lastMessage: 'See you at the gym!',
        lastMessageTime: now,
        lastMessageSenderId: 'alice',
      );

      expect(room.id, 'room-1');
      expect(room.participants, ['alice', 'bob']);
      expect(room.lastMessage, 'See you at the gym!');
      expect(room.lastMessageTime, now);
      expect(room.lastMessageSenderId, 'alice');
    });

    test('constructor allows optional fields to be null', () {
      final room = ChatRoom(
        id: 'room-2',
        participants: ['user-1', 'user-2'],
      );

      expect(room.lastMessage, isNull);
      expect(room.lastMessageTime, isNull);
      expect(room.lastMessageSenderId, isNull);
    });
  });

  group('Message', () {
    final testDate = DateTime(2024, 6, 1, 12, 30);

    test('constructor sets all fields correctly', () {
      final message = Message(
        id: 'msg-1',
        chatId: 'chat-1',
        senderId: 'user-1',
        content: 'Hello!',
        timestamp: testDate,
        isRead: true,
      );

      expect(message.id, 'msg-1');
      expect(message.chatId, 'chat-1');
      expect(message.senderId, 'user-1');
      expect(message.content, 'Hello!');
      expect(message.timestamp, testDate);
      expect(message.isRead, isTrue);
    });

    test('isRead defaults to false', () {
      final message = Message(
        chatId: 'chat-1',
        senderId: 'user-1',
        content: 'Hi',
        timestamp: testDate,
      );

      expect(message.isRead, isFalse);
    });

    test('id defaults to null', () {
      final message = Message(
        chatId: 'chat-1',
        senderId: 'user-2',
        content: 'Hey',
        timestamp: testDate,
      );

      expect(message.id, isNull);
    });
  });
}
