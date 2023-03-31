import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:chat_sns/main.dart';

import 'dart:convert';
import 'dart:math';

// flutter_chat_uiを使うためのパッケージをインポート
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'package:provider/provider.dart';
// ランダムなIDを採番してくれるパッケージ
import 'package:uuid/uuid.dart';

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

class ChatPage extends StatefulWidget {
  const ChatPage(this.name, {Key? key}) : super(key: key);

  final String name;
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  String Id = '';
  types.User? _user;

  // ゲストの書き込みに対するポップアップ
  _myDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("メンバーのみ書き込み可能です"),
        content: ElevatedButton(
          child: Text('会員登録する'),
          onPressed: () async {
            await Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) {
                return NewAccountPage();
              }),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("close"),
          )
        ],
      ),
    );
  }

  void initState() {
    _setUserInfo();
    _getMessages();
    super.initState();
  }

  // UserにFirebaseAuthでしようされるuidを設定し、関連付ける
  Future<void> _setUserInfo() async {
    User? user = FirebaseAuth.instance.currentUser;
    String uid;
    if (user != null) {
      uid = user.uid;
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      _user = types.User(id: uid, firstName: document['name']);
    } else {
      uid = 'guest';
      _user = types.User(id: uid, firstName: 'ゲスト');
    }
  }

  // firestoreからメッセージの内容をとってきて_messageにセット
  void _getMessages() async {
    final getData = await FirebaseFirestore.instance
        .collection('chat_room')
        .doc(widget.name)
        .collection('contents')
        .get();

    final message = getData.docs
        .map((d) => types.TextMessage(
            author:
                types.User(id: d.data()['uid'], firstName: d.data()['name']),
            createdAt: d.data()['createdAt'],
            id: d.data()['id'],
            text: d.data()['text']))
        .toList();

    setState(() {
      _messages = [...message];
    });
  }

  // メッセージ内容をfirestoreにセット
  void _addMessage(types.TextMessage message) async {
    setState(() {
      _messages.insert(0, message);
    });
    await FirebaseFirestore.instance
        .collection('chat_room')
        .doc(widget.name)
        .collection('contents')
        .add({
      'uid': message.author.id,
      'name': message.author.firstName,
      'createdAt': message.createdAt,
      'id': message.id,
      'text': message.text,
    });
  }

  // メッセージ送信時の処理
  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user!,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomString(),
      text: message.text,
    );
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _addMessage(textMessage);
    } else {
      _myDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('チャット'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () async {
              // ログイン画面に遷移＋チャット画面を破棄
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return MyHomePage();
                }),
              );
            },
          ),
        ],
      ),
      body: Chat(
        theme: const DefaultChatTheme(
          // メッセージ入力欄の色
          inputBackgroundColor: Colors.blue,
          // 送信ボタン
          sendButtonIcon: Icon(Icons.send),
          sendingIcon: Icon(Icons.update_outlined),
        ),
        // ユーザーの名前を表示するかどうか
        showUserNames: true,
        // メッセージの配列
        messages: _messages,
        // onPreviewDataFetched: _handlePreviewDataFetched,
        onSendPressed: _handleSendPressed,
        user: _user!,
      ),
    );
  }
}
