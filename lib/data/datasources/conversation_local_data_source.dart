import 'package:sqflite/sqflite.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'app_database.dart';

class ConversationLocalDataSource {
  ConversationLocalDataSource(this._appDb);

  final AppDatabase _appDb;

  Future<List<ConversationModel>> getConversations() async {
    final db = await _appDb.database;
    final rows = await db.query('conversations', orderBy: 'updated_at DESC');
    return rows.map(ConversationModel.fromMap).toList();
  }

  Future<void> insertConversation(ConversationModel model) async {
    final db = await _appDb.database;
    await db.insert('conversations', model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteConversation(String id) async {
    final db = await _appDb.database;
    // Messages are removed by ON DELETE CASCADE.
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> renameConversation(String id, String title) async {
    final db = await _appDb.database;
    await db.update('conversations', {'title': title}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final db = await _appDb.database;
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(MessageModel.fromMap).toList();
  }

  /// Inserts the message and bumps the parent conversation atomically.
  Future<void> insertMessage(MessageModel model) async {
    final db = await _appDb.database;
    await db.transaction((txn) async {
      await txn.insert('messages', model.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.update(
        'conversations',
        {'updated_at': model.timestamp.millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [model.conversationId],
      );
    });
  }
}
