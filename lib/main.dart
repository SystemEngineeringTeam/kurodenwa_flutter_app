import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:developer';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';

final FirebaseMethods firebaseMethods = FirebaseMethods();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //App名(アプリ名)
      title: '目覚まし黒電話',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: TopPage(),
    );
  }
}

class Alarm {
  final String id;
  final bool isActive;
  final String time;
  final List<int> days;
  final String repeat;

  Alarm({
    required this.id,
    required this.isActive,
    required this.time,
    required this.days,
    required this.repeat,
  });

  factory Alarm.fromMap(String id, Map<String, dynamic> data) {
    return Alarm(
      id: id,
      isActive: data['alarm_status'] as bool,
      time: data['time'] as String,
      days: (data['week_day'] as String?)
              ?.split(',')
              .map((e) => int.tryParse(e) ?? 0)
              .toList() ??
          [],
      repeat: data['voice_number'] as String,
    );
  }

  @override
  String toString() {
    return 'Alarm(id: $id, isActive: $isActive, time: $time, days: $days, repeat: $repeat)';
  }
}

Future<List<Alarm>> fetchAlarmsFromJson() async {
  final alarmList = await firebaseMethods.get();

  return alarmList;
}

class TopPage extends StatefulWidget {
  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  List<Alarm> alarmList = [];
  bool isLoading = false; // ローディングフラグ

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  void _loadAlarms() async {
    setState(() {
      isLoading = true; // ローディング開始
    });

    final alarms = await fetchAlarmsFromJson(); // Firebaseからデータ取得
    setState(() {
      alarmList = alarms;
      isLoading = false; // ローディング終了
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('アラーム'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // ローディング中はインジケーターを表示
          : ListView.builder(
              itemCount: alarmList.length,
              itemBuilder: (context, index) {
                final alarm = alarmList[index];
                String _dayLabel(int day) {
                  switch (day) {
                    case 0:
                      return '日';
                    case 1:
                      return '月';
                    case 2:
                      return '火';
                    case 3:
                      return '水';
                    case 4:
                      return '木';
                    case 5:
                      return '金';
                    case 6:
                      return '土';
                    default:
                      return '';
                  }
                }

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child:ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    title: Text(
                      '時間: ${alarm.time}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '繰り返し: ${alarm.days.map((day) => _dayLabel(day)).join(", ")}',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, // 必須: 横幅を内容に合わせる
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.black),
                          onPressed: () async {
                            final shouldDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('確認'),
                                  content: Text('このアラームを削除しますか？'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false), // キャンセル
                                      child: Text('キャンセル'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true), // 削除
                                      child: Text('削除', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (shouldDelete == true) {
                              await firebaseMethods.delete(alarm.id); // Firebaseから削除
                              setState(() {
                                alarmList.removeAt(index); // リストを更新して即座に反映
                              });
                            }
                          },
                        ),
                        Switch(
                          value: alarm.isActive,
                          onChanged: (bool value) {
                            setState(() {
                              alarmList[index] = Alarm(
                                id: alarm.id,
                                isActive: value,
                                time: alarm.time,
                                days: alarm.days,
                                repeat: alarm.repeat,
                              );
                            });
                            firebaseMethods.update(alarmList[index]);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 新しいアラームのエントリページへ遷移
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return NewAlarmEntryPage();
            }),
          );

          // 戻ったときにアラームの再取得
          if (result == true) {
            _loadAlarms();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

//時間追加仮面ライダー
class NewAlarmEntryPage extends StatefulWidget {
  final String title = 'アラームを登録';

  const NewAlarmEntryPage({Key? key}) : super(key: key);

  @override
  _NewAlarmEntryPageState createState() => _NewAlarmEntryPageState();
}

class _NewAlarmEntryPageState extends State<NewAlarmEntryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: _form());
  }

  final _formKey = GlobalKey<FormState>();
  bool sunChk = false;
  bool monChk = false;
  bool tueChk = false;
  bool wedChk = false;
  bool thuChk = false;
  bool friChk = false;
  bool satChk = false;
  bool snoozeChk = false;
  String sound = 'default';
  DateTime dateTime = DateTime.now();

  Widget _form() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                initialDateTime: dateTime,
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                onDateTimeChanged: (DateTime newTime) {
                  setState(() => dateTime = newTime);
                },
              ),
            ),
            Table(children: <TableRow>[
              const TableRow(children: <Widget>[
                Center(child: Text("日")),
                Center(child: Text("月")),
                Center(child: Text("火")),
                Center(child: Text("水")),
                Center(child: Text("木")),
                Center(child: Text("金")),
                Center(child: Text("土")),
              ]),
              TableRow(children: <Widget>[
                Center(
                    child: Checkbox(
                        value: sunChk,
                        onChanged: (bool? value) {
                          setState(() => sunChk = value!);
                          debugPrint('sunChk = $value');
                        })),
                Center(
                    child: Checkbox(
                        value: monChk,
                        onChanged: (bool? value) {
                          setState(() => monChk = value!);
                          debugPrint('monChk = $value');
                        })),
                Center(
                    child: Checkbox(
                        value: tueChk,
                        onChanged: (bool? value) {
                          setState(() => tueChk = value!);
                          debugPrint('tueChk = $value');
                        })),
                Center(
                    child: Checkbox(
                        value: wedChk,
                        onChanged: (bool? value) {
                          setState(() => wedChk = value!);
                          debugPrint('wedChk = $value');
                        })),
                Center(
                    child: Checkbox(
                        value: thuChk,
                        onChanged: (bool? value) {
                          setState(() => thuChk = value!);
                          debugPrint('thuChk = $value');
                        })),
                Center(
                    child: Checkbox(
                        value: friChk,
                        onChanged: (bool? value) {
                          setState(() => friChk = value!);
                          debugPrint('friChk = $value');
                        })),
                Center(
                    child: Checkbox(
                        value: satChk,
                        onChanged: (bool? value) {
                          setState(() => satChk = value!);
                          debugPrint('satChk = $value');
                        })),
              ])
            ]),
            DropdownButton(
              items: const [
                DropdownMenuItem(
                    child: Padding(
                        child: Text("ボイスを選択"),
                        padding:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 16)),
                    value: 'default'),
                DropdownMenuItem(
                  value: '1',
                  child: Text('voice1:うまみ'),
                ),
                DropdownMenuItem(
                  value: '2',
                  child: Text('voice2:うまみ'),
                ),
                DropdownMenuItem(
                  value: '3',
                  child: Text('voice3:うまみ'),
                ),
                DropdownMenuItem(
                  value: '4',
                  child: Text('voice4:うまみ'),
                ),
                DropdownMenuItem(
                  value: '5',
                  child: Text('voice5:コッシー'),
                ),
                DropdownMenuItem(
                  value: '6',
                  child: Text('voice6:コッシー'),
                ),
                DropdownMenuItem(
                  value: '7',
                  child: Text('voice7:コッシー'),
                ),
                DropdownMenuItem(
                  value: '8',
                  child: Text('voice8:コッシー'),
                ),
                DropdownMenuItem(
                  value: '9',
                  child: Text('voice9:メロンぱん'),
                ),
                DropdownMenuItem(
                  value: '10',
                  child: Text('voice10:メロンぱん'),
                ),
                DropdownMenuItem(
                  value: '11',
                  child: Text('voice11:メロンぱん'),
                ),
                DropdownMenuItem(
                  value: '12',
                  child: Text('voice12:メロンぱん'),
                ),
                DropdownMenuItem(
                  value: '13',
                  child: Text('voice13:ちっぴー'),
                ),
                DropdownMenuItem(
                  value: '14',
                  child: Text('voice14:ちっぴー'),
                ),
                DropdownMenuItem(
                  value: '15',
                  child: Text('voice15:ちっぴー'),
                ),
                DropdownMenuItem(
                  value: '16',
                  child: Text('voice16:ちっぴー'),
                )
              ],
              value: sound,
              isExpanded: true,
              onChanged: (String? value) {
                setState(() => sound = value.toString());
                debugPrint('sound = $value');
              },
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // soundがdefaultでない場合のみ保存
                  if (sound != 'default') {
                    // 曜日をリストに変換
                    List<int> weekDays = [];
                    if (sunChk) weekDays.add(0);
                    if (monChk) weekDays.add(1);
                    if (tueChk) weekDays.add(2);
                    if (wedChk) weekDays.add(3);
                    if (thuChk) weekDays.add(4);
                    if (friChk) weekDays.add(5);
                    if (satChk) weekDays.add(6);

                    // アラームデータをFirebaseに保存
                    String formattedTime = DateFormat("H:mm").format(dateTime);
                    debugPrint("$formattedTime $sound ${weekDays.join(',')}");
                    firebaseMethods.set(
                      formattedTime, // 時間のフォーマット
                      true, // 初期状態はアクティブ
                      sound,
                      weekDays.join(','), // リストをカンマ区切りの文字列に変換
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('登録しました')),
                    );

                    // 登録完了後にトップページに戻る
                    Navigator.pop(context, true); // 成功を示すためにtrueを渡す
                  } else {
                    // エラーメッセージを表示
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ボイスを選択してください')),
                    );
                  }
                }
              },
              child: const Text("保存"),
            ),
          ],
        ),
      ),
    );
  }
}

//firebase用のクラス
class FirebaseMethods {
  final Uuid uuid = Uuid();
  List<Map<String, dynamic>> datas = []; // Firestoreから取得したデータを格納するリスト

  Future<void> set(time, status, voice, week) async {
    try {
      await FirebaseFirestore.instance.collection('alarms').doc(uuid.v4()).set({
        'time': time, // 時刻
        'alarm_status': status, // アラームの状態
        "voice_number": voice, // ボイスの番号
        "week_day": week // 曜日の指定
      });
    } catch (e) {
      debugPrint('Error creating Alarm from data: $e');
    }
  }
//消す処理
  Future<void> delete(String alarmId) async {
    try {
      await FirebaseFirestore.instance
          .collection('alarms')
          .doc(alarmId)
          .delete();
      debugPrint('Alarm deleted: $alarmId');
    } catch (e) {
      debugPrint('Error deleting Alarm: $e');
    }
  }

  // アラームを更新するメソッド
  Future<void> update(Alarm alarm) async {
    try {
      await FirebaseFirestore.instance
          .collection('alarms')
          .doc(alarm.id) // アラームのIDでドキュメントを特定
          .update({
        'time': alarm.time,
        'alarm_status': alarm.isActive,
        'voice_number': alarm.repeat,
        'week_day': alarm.days.join(','), // 曜日をカンマ区切りの文字列に変換
      });
    } catch (e) {
      debugPrint('Error updating Alarm: $e');
    }
  }

  Future<List<Alarm>> get() async {
    final collectionRef = FirebaseFirestore.instance.collection('alarms');
    final querySnapshot = await collectionRef.get();
    final queryDocSnapshot = querySnapshot.docs;

    List<Map<String, dynamic>> newData = [];

    for (final snapshot in queryDocSnapshot) {
      final data = snapshot.data();
      // ドキュメントのIDを取得して newData に追加
      newData.add({
        'id': snapshot.id, // ドキュメントのIDを追加
        ...data // 既存のデータを追加
      });
    }

    return convertToAlarms(newData);
  }

  Future<List<Alarm>> convertToAlarms(
      List<Map<String, dynamic>> alarmDataList) async {
    final List<Alarm> alarmList = [];

    for (var alarmData in alarmDataList) {
      // id と data の null チェック
      final id = alarmData['id'] as String;
      final alarm_status = alarmData['alarm_status'] as bool;
      final voice_number = alarmData['voice_number'] as String;
      final week_day_string = alarmData['week_day'] as String;
      final time = alarmData['time'] as String;
      final List<int> week_day = week_day_string.isNotEmpty
          ? week_day_string.split(',').map((day) => int.parse(day)).toList()
          : []; // 空のリストを代入

      try {
        alarmList.add(Alarm(
          id: id,
          isActive: alarm_status,
          time: time,
          days: week_day,
          repeat: voice_number,
        ));
      } catch (e) {
        debugPrint('Error creating Alarm from data: $e');
      }
    }

    // timeで昇順にソート
    alarmList.sort((a, b) {
      final timeA = DateFormat("H:mm").parse(a.time);
      final timeB = DateFormat("H:mm").parse(b.time);
      return timeA.compareTo(timeB);
    });

    return alarmList;
  }
}
