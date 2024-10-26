import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //App名(アプリ名)
      title: '目覚まし黒電話',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:TopPage(),
    );
  }
}

class Alarm {
  final String id;
  final bool isActive;
  final String time;
  final List<int> days;
  final int repeat;

  Alarm({
    required this.id,
    required this.isActive,
    required this.time,
    required this.days,
    required this.repeat,
  });

  factory Alarm.fromMap(String id, List<dynamic> data) {
    return Alarm(
      id: id,
      isActive: data[0] == 'true',
      time: data[1],
      days: (data[2] as String).split(',').map((e) => int.parse(e)).toList(),
      repeat: int.parse(data[3]),
    );
  }
}

//jsonから取り出し
List<Alarm> fetchAlarmsFromJson() {
  const jsonData = '''
  {
    "alarms" : {
      "ouotiaj123joijIJoi432":[
          "false",
          "10:00",
          "0,1,4",
          "1"
      ],
      "ouotiaj123joidsfJoi432":[
          "false",
          "10:30",
          "0,1,4",
          "1"
      ],
      "ouotiaj123joifdsJoi432":[
          "true",
          "10:30",
          "0,1,4",
          "1"
      ],
       "ouotiaj123joifdsJofdfi432":[
          "true",
          "10:30",
          "0,1,4",
          "1"
      ]
    }
  }
  ''';

  final Map<String, dynamic> data = json.decode(jsonData);
  final List<Alarm> alarmList = [];

  data['alarms']?.forEach((key, value) {
    alarmList.add(Alarm.fromMap(key, value));
  });
  // リストの内容を確認
  for (var alarm in alarmList) {
    print(
        'id: ${alarm.id}, '
        'isActive: ${alarm.isActive}, '
        'time: ${alarm.time},'
        ' days: ${alarm.days}, '
        'repeat: ${alarm.repeat}'
    );
  }
  return alarmList;
}


class TopPage extends StatefulWidget {
  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  List<Alarm> alarmList = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  void _loadAlarms() {
    setState(() {
      alarmList = fetchAlarmsFromJson();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('アラーム'),
      ),
      body: ListView.builder(
        itemCount: alarmList.length,
        itemBuilder: (context, index) {
          final alarm = alarmList[index];
          String _dayLabel(int day) {
            switch (day) {
              case 0: return '日';
              case 1: return '月';
              case 2: return '火';
              case 3: return '水';
              case 4: return '木';
              case 5: return '金';
              case 6: return '土';
              default: return '';
            }
          }

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              title: Text(
                '時間: ${alarm.time}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '繰り返し: ${alarm.days.map((day) => _dayLabel(day)).join(", ")}',
                style: TextStyle(fontSize: 14),
              ),
              trailing: Switch(
                value: alarm.isActive,
                activeColor: Colors.deepPurple,
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
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return NewAlarmEntryPage();
            }),
          );
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
        body: _form(

        )
    );
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
                  Center(child: Checkbox(
                      value: sunChk,
                      onChanged: (bool? value) {
                        setState(() => sunChk = value!);
                        debugPrint('sunChk = $value');
                      }
                  )),
                  Center(child: Checkbox(
                      value: monChk,
                      onChanged: (bool? value) {
                        setState(() => monChk = value!);
                        debugPrint('monChk = $value');
                      }
                  )),
                  Center(child: Checkbox(
                      value: tueChk,
                      onChanged: (bool? value) {
                        setState(() => tueChk = value!);
                        debugPrint('tueChk = $value');
                      }
                  )),
                  Center(child: Checkbox(
                      value:wedChk,
                      onChanged: (bool? value) {
                        setState(() => wedChk = value!);
                        debugPrint('wedChk = $value');
                      }
                  )),
                  Center(child: Checkbox(
                      value: thuChk,
                      onChanged: (bool? value) {
                        setState(() => thuChk = value!);
                        debugPrint('thuChk = $value');
                      }
                  )),
                  Center(child: Checkbox(
                      value: friChk,
                      onChanged: (bool? value) {
                        setState(() => friChk = value!);
                        debugPrint('friChk = $value');
                      }
                  )),
                  Center(child: Checkbox(
                      value: satChk,
                      onChanged: (bool? value) {
                        setState(() => satChk = value!);
                        debugPrint('satChk = $value');
                      }
                  )),
                ])
              ]),
              DropdownButton(
                items: const [DropdownMenuItem(child: Padding
                  (child: Text("デフォルト音"),
                    padding: EdgeInsets.symmetric(vertical: 0, horizontal: 16)
                  ),

                    value: 'default'),

                  DropdownMenuItem(
                    value: 'ずんだもん',
                    child: Text('ずんだもん'),
                  ),

                  DropdownMenuItem(
                      value: 'ゆっくりれいむ',
                      child: Text('ゆっくりれいむ'),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('登録しました')),
                      );
                    }
                  },
                  child: const Text("保存")),
            ],
          )),
    );
  }
}

