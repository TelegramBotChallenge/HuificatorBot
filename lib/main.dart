import 'package:telegrambot/telegrambot.dart';
import 'dart:async';
import 'dart:io' as io;

Future<dynamic> main(List<String> args) async {
  print(io.Directory.current);
  var token = new io.File('token.txt').readAsStringSync();
  var bot = new TelegramBot(token);
  var updates = pollForUpdates(bot);

  await for (var update in updates) {
//    if (update.inlineQuery != null) {
//      handleInlineQuery(bot, update.inlineQuery);
//    }
    if (update.message != null) {
      handleMessage(bot, update.message);
    }
  }
}

void handleMessage(TelegramBot bot, Message message) {
  var out = message.text.split(' ').map((x) => x + huify(x));
  bot.sendCommand(new SendMessage.plainText(message.chat.id,
      out.join(" ")));
}

String huify(String s) {
  if (s.length > 2) {
    var regexp = new RegExp('[^аеёиоуэюя]*([аеёиоуэюя])');
    return s.replaceFirstMapped(regexp, (m) {
      switch (m.group(1)) {
        case 'а':
          return '-хуя';
        case 'о':
          return '-хуё';
        case 'у':
          return '-хую';
        case 'э':
          return '-хуе';
        default:
          return '-ху' + m.group(1);
      }
    });
  } else {
    return '';
  }
}