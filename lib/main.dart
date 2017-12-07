import 'package:telegrambot/telegrambot.dart';
import 'dart:async';
import 'dart:io' as io;
import 'dart:math';
import 'package:postgres/postgres.dart';


Future<dynamic> main(List<String> args) async {
  print(io.Directory.current);
  var token = new io.File('token.txt').readAsStringSync();
  var dbSettings = new io.File('db.txt').readAsLinesSync().map((s) =>
  s.split('=')[1]).toList();
  var app = new Application(
      token, dbSettings);
  app.start();
}

String huify(String s) {
  if (s.length > 2) {
    var regexp = new RegExp('[^аеёиоуэюя]*([аеёиоуэюя])');
    return s.replaceFirstMapped(regexp, (m) {
      switch (m.group(1)) {
        case 'а':
          return 'хуя';
        case 'о':
          return 'хуё';
        case 'у':
          return 'хую';
        case 'э':
          return 'хуе';
        default:
          return 'ху' + m.group(1);
      }
    });
  } else {
    return '';
  }
}

class Application {
  TelegramBot bot;
  Stream<Update> updates;

  String host;
  int port;
  String table;
  String username;
  String password;

  Application(String token, List<String> dbSettings) {
    bot = new TelegramBot(token);
    updates = pollForUpdates(bot);
    host = dbSettings[0];
    port = int.parse(dbSettings[1]);
    table = dbSettings[2];
    username = dbSettings[3];
    password = dbSettings[4];
  }

  Future<dynamic> start() async {
    var connection = new PostgreSQLConnection(
        host, port, table, username: username, password: password);
    await connection.open();
    await for (var update in updates) {
      if (update.message != null && update.message.text != null) {
        handleMessage(bot, update.message, connection);
      }
    }
  }

  Future<dynamic> updateProbability(PostgreSQLConnection connection, int p,
      int chat_id) async {
    await connection.query(
        "UPDATE probabilities SET probability = @p WHERE chat_id = @chat_id",
        substitutionValues: {
          "p": p, "chat_id": chat_id
        });
  }

  Future<dynamic> setProbability(PostgreSQLConnection connection,
      int chat_id) async {
    await connection.query(
        "INSERT INTO probabilities VALUES(@chat_id, 100)",
        substitutionValues: {
          "chat_id": chat_id
        });
  }

  Future<int> getProbability(PostgreSQLConnection connection,
      int chat_id) async {
    var p = await connection.query(
        "SELECT probability FROM probabilities WHERE chat_id = @chat_id",
        substitutionValues: {"chat_id": chat_id});
    if (p.isEmpty) {
      setProbability(connection, chat_id);
      return 100;
    }
    return p.first.first;
  }


  Future handleMessage(TelegramBot bot, Message message,
      PostgreSQLConnection connection) async {
    if (message.text.startsWith('/hueroyatnost') && message.text
        .split(' ')
        .length > 1) {
      var s = message.text.split(' ')[1];
      var n = int.parse(s, onError: (e) => null);
      if (n >= 0 && n <= 100) {
        updateProbability(connection, n, message.chat.id);
        bot.sendCommand(new SendMessage.plainText(message.chat.id,
            "Хуероятность теперь = " + s + "%"));
      } else {
        bot.sendCommand(new SendMessage.plainText(message.chat.id,
            "Хуёвая вероятность, давай по-новой!"));
      }
    } else {
      var rng = new Random();
      final regexp = new RegExp('[.,\/#!\$%\^&\*;:{}=\-`~()—]');
      var n = await getProbability(connection, message.chat.id);
      if (rng.nextInt(100) <= n) {
        var out = message.text.toLowerCase().split(' ').map((x) {
          if (x.length < 3) {
            return x;
          } else {
            var s = x.replaceAll(regexp, '');
            var huified = huify(x);
            if (huified == x) {
              return x;
            }
            return s + '-' + huify(x);
          }
        });
        bot.sendCommand(new SendMessage.plainText(message.chat.id,
            out.join(" "))
        );
      }
    }
  }
}