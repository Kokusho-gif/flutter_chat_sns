import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:chat_sns/chat_page.dart';

// チャット用ライブラリ
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

// DateFormat用
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  final String title = 'Flutter Demo Home Page';

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String email = '';
  String password = '';
  String infoText = "";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        CustomScrollView(
          slivers: <Widget>[
            const SliverAppBar(
              pinned: true,
              snap: false,
              floating: false,
              expandedHeight: 160.0,
              title: Center(child: Text('Demo')),

              // スクロールしたら消えるところ
              flexibleSpace: FlexibleSpaceBar(
                background: FlutterLogo(),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return Container(
                    color: index.isOdd ? Colors.white : Colors.black12,
                    height: 100.0,
                    child: Center(
                      child: ElevatedButton(
                        child: Text('$index'),
                        onPressed: () async {
                          await Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) {
                              return ChatPage('Taisuke');
                            }),
                          );
                        },
                      ),
                    ),
                  );
                },
                childCount: 20,
              ),
            ),
          ],
        ),
      ]),
      drawer: Drawer(
        child: ListView(
          children: [
            Container(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 50, bottom: 20),
                    width: 100.0,
                    height: 100.0,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                            fit: BoxFit.fill,
                            image: NetworkImage(
                                'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg'))),
                  ),
                  Text(
                      '${FirebaseAuth.instance.currentUser == null ? 'ゲスト' : FirebaseAuth.instance.currentUser?.email}'),
                  const SizedBox(height: 20),
                  const ListTile(
                    title: Center(child: Text('プロフィール ')),
                    tileColor: Colors.black12,
                  ),
                  const ListTile(
                    title: Center(child: Text('フレンド')),
                    tileColor: Colors.white,
                  ),
                  const ListTile(
                    title: Center(child: Text('セッティング')),
                    tileColor: Colors.black12,
                  ),
                  const ListTile(
                    title: Center(child: Text('アカウント')),
                    tileColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.all(20),
              child: Column(
                children: [
                  FirebaseAuth.instance.currentUser == null
                      ? Column(
                          children: [
                            TextFormField(
                              decoration: InputDecoration(labelText: 'メールアドレス'),
                              onChanged: (String value) {
                                setState(() {
                                  email = value;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              decoration: InputDecoration(labelText: 'パスワード'),
                              onChanged: (String value) {
                                setState(() {
                                  password = value;
                                });
                              },
                            ),
                          ],
                        )
                      : SizedBox.shrink(),

                  const SizedBox(height: 8),

                  FirebaseAuth.instance.currentUser == null
                      ? ElevatedButton(
                          onPressed: () async {
                            try {
                              // メール/パスワードでログイン
                              final FirebaseAuth auth = FirebaseAuth.instance;
                              final UserCredential result =
                                  await auth.signInWithEmailAndPassword(
                                email: email,
                                password: password,
                              );

                              // ログインに成功した場合
                              final User user = result.user!;
                              setState(() {
                                infoText = "ログインOK";
                              });
                            } catch (e) {
                              // 登録に失敗した場合
                              setState(() {
                                infoText = "ログインNG:${e.toString()}";
                              });
                            }
                          },
                          child: Text('ログイン'),
                        )
                      : SizedBox.shrink(),

                  FirebaseAuth.instance.currentUser == null
                      ? ElevatedButton(
                          onPressed: () async {
                            await Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) {
                                return NewAccountPage();
                              }),
                            );
                          },
                          child: Text('ユーザ登録'),
                        )
                      : SizedBox.shrink(),

                  const SizedBox(height: 8),
                  // 3項演算子を用いて、カレントユーザがいるときログアウトボタンが出現
                  FirebaseAuth.instance.currentUser != null
                      ? ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            await Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) {
                                return MyHomePage();
                              }),
                            );
                          },
                          child: Text('ログアウト'))
                      : SizedBox.shrink(),
                  const SizedBox(height: 8),
                  Text(infoText),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum RadioValue { FIRST, SECOND, THIRD }

// ユーザ登録用ページ
class NewAccountPage extends StatefulWidget {
  const NewAccountPage({super.key});

  @override
  State<NewAccountPage> createState() => _NewAccountPageState();
}

class _NewAccountPageState extends State<NewAccountPage> {
  String email = '';
  String password = '';
  String infoText = '';
  String name = '';
  String sex = '';
  dynamic dateTime = DateTime.now();
  final _editController = TextEditingController();

  RadioValue _gValue = RadioValue.FIRST;

  _datePicker(BuildContext context) async {
    final DateTime? datePicked = await showDatePicker(
        context: context,
        initialDate: dateTime,
        firstDate: DateTime(1923),
        lastDate: DateTime(2024));
    if (datePicked != null && datePicked != dateTime) {
      setState(() {
        dateTime = datePicked;
      });
      _editController.text = DateFormat('yyyy年M月d日').format(dateTime);
    }
  }

  _onRadioSelected(value, String str) {
    setState(() {
      _gValue = value;
      sex = str;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          children: <Widget>[
            SizedBox(height: 50),
            TextFormField(
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'メールアドレス',
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) {
                setState(() {
                  email = value;
                });
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                  labelText: 'パスワード', border: OutlineInputBorder()),
              onChanged: (String value) {
                setState(() {
                  password = value;
                });
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              decoration: InputDecoration(
                labelText: '名前',
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) {
                setState(() {
                  name = value;
                });
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              controller: _editController,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: '生年月日',
                border: OutlineInputBorder(),
              ),
              onTap: () {
                _datePicker(context);
              },
            ),
            SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: RadioListTile(
                    title: Text('男性'),
                    value: RadioValue.FIRST,
                    groupValue: _gValue,
                    onChanged: (value) => _onRadioSelected(value, 'male'),
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: Text('女性'),
                    value: RadioValue.SECOND,
                    groupValue: _gValue,
                    onChanged: (value) => _onRadioSelected(value, 'female'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                try {
                  // メール/パスワードでユーザー登録
                  final FirebaseAuth auth = FirebaseAuth.instance;
                  final result = await auth.createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  );
                  final user = result.user!;
                  final document = FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .set({
                    'name': name,
                    'birthdate': dateTime,
                    'sex': sex,
                  });

                  // ユーザー登録に成功した場合
                  // チャット画面に遷移＋ログイン画面を破棄
                  await Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) {
                      return MyHomePage();
                    }),
                  );
                } catch (e) {
                  // ユーザー登録に失敗した場合
                  setState(() {
                    infoText = "登録に失敗しました：${e.toString()}";
                  });
                }
              },
              child: Text('登録'),
            ),
            Text('$infoText'),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) {
                    return MyHomePage();
                  }),
                );
              },
              child: Text('ホーム'),
            ),
          ],
        ),
      ),
    );
  }
}

// チャット画面用Widget
// class ChatPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('チャット'),
//         actions: <Widget>[
//           IconButton(
//             icon: Icon(Icons.close),
//             onPressed: () async {
//               // ログイン画面に遷移＋チャット画面を破棄
//               await Navigator.of(context).pushReplacement(
//                 MaterialPageRoute(builder: (context) {
//                   return MyHomePage();
//                 }),
//               );
//             },
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         child: Icon(Icons.add),
//         onPressed: () async {
//           // 投稿画面に遷移
//           await Navigator.of(context).push(
//             MaterialPageRoute(builder: (context) {
//               return AddPostPage();
//             }),
//           );
//         },
//       ),
//     );
//   }
// }

// 投稿画面用Widget
class AddPostPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('チャット投稿'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('戻る'),
          onPressed: () {
            // 1つ前の画面に戻る
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
