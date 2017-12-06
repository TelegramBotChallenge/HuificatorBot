import 'package:telegrambot/telegrambot.dart';
import 'dart:async';
import 'dart:io' as io;
import 'dart:math';


Future<dynamic> main(List<String> args) async {
  print(io.Directory.current);
  var token = new io.File('token.txt').readAsStringSync();
  var app = new Application(token);
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
  int probability = 100;

  Application(String token) {
    bot = new TelegramBot(token);
    updates = pollForUpdates(bot);
  }

  Future<dynamic> start() async {
    await for (var update in updates) {
      if (update.message != null && update.message.text != null) {
        handleMessage(bot, update.message);
      }
    }
  }

  void handleMessage(TelegramBot bot, Message message) {
    if (message.text.startsWith('/hueroyatnost') && message.text
        .split(' ')
        .length > 1) {
      var s = message.text.split(' ')[1];
      var n = int.parse(s, onError: (e) => null);
      if (n >= 0 && n <= 100) {
        probability = n;
        bot.sendCommand(new SendMessage.plainText(message.chat.id,
            "Хуероятность теперь = " + s + "%"));
      } else {
        bot.sendCommand(new SendMessage.plainText(message.chat.id,
            "Хуёвая вероятность, давай по-новой!"));
      }
    } else {
      var rng = new Random();
      final regexp = new RegExp('[.,\/#!\$%\^&\*;:{}=\-`~()—]');
      if (rng.nextInt(100) <= probability) {
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