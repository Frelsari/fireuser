import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'service.dart';
import 'package:cron/cron.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fireuser/page_bluetooth/characteristic.dart';


class DeviceScreen extends StatefulWidget {
  DeviceScreen({@required this.device, Key key}); //使用該字段的類型並初始化
  final BluetoothDevice device;
  @override
  _DeviceScreen createState() => _DeviceScreen(device: device);
}

class _DeviceScreen extends State<DeviceScreen> {
  _DeviceScreen({@required this.device, Key key}); //使用該字段的類型並初始化
  final BluetoothDevice device;
  CollectionReference _collection;
  StreamSubscription<List<int>> streamSubscription ;

  @override
  void initState(){
    super.initState();
    _collection = FirebaseFirestore
        .instance.collection('NTUTLab321');
  }

  // @override
  // void dispose(){
  //   streamSubscription?.cancel();
  //   streamSubscription = null;
  //   super.dispose();
  //  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(device.id.toString(), style: TextStyle(fontSize: 16), overflow: TextOverflow.ellipsis,),
          actions: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              //藍芽狀態
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) {
                VoidCallback onPressed;
                String text;
                //top navigation 的 button
                switch (snapshot.data) {
                  case BluetoothDeviceState.connected:
                    onPressed = () {
                      return showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('忘記後需重新連接此裝置'),
                          content:
                          Text('忘記此裝置 ' + device.id.toString() + ' 的設定?'),
                          actions: <Widget>[
                            FlatButton(
                              child: Text('是', style: TextStyle(fontSize: 30, color: Colors.red),),
                              onPressed: () {
                                _collection.doc('${device.id.toString()}')
                                    .update({
                                  'change': 'X',
                                  'modedescription': '未使用',
                                  'time': [],
                                  'alarm': '0',
                                  'judge': 'unused',
                                });
                                device.disconnect();

                                Navigator.pop(context);
                              },
                            ),
                            FlatButton(
                              child: Text('否', style: TextStyle(fontSize: 30),),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                          ],
                        ),
                      );
                    };
                    text = "忘記此裝置";
                    break;
                  case BluetoothDeviceState.disconnected:
                    onPressed = () => device.connect();
                    text = '重新連線';
                    break;
                  default:
                    onPressed = null;
                    text = snapshot.data.toString().substring(21).toUpperCase();
                    break;
                }
                return FlatButton(
                  onPressed: onPressed,
                  child: Text(text, style: TextStyle(color: Colors.red),),
                );
              },
            ),
          ]),


      body:

      SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: (snapshot.data == BluetoothDeviceState.connected)
                    ? Icon(Icons.bluetooth_connected)
                    : Icon(Icons.bluetooth_disabled),
                title: Text('Device is ${snapshot.data.toString().split('.')[1]}.'),
                subtitle: Text('${device.id}'),
                trailing:


                StreamBuilder<bool>(
                  stream: device.isDiscoveringServices,
                  initialData: true,
                  builder: (c, snapshot) =>
                      IndexedStack(
                       index: snapshot.data ? 1 : 0,
                        children: <Widget>[
                      StreamBuilder<BluetoothDeviceState>(
                        stream: device.state,
                        initialData: BluetoothDeviceState.disconnected,
                        builder: (c, snapshot) {
                          if (snapshot.data == BluetoothDeviceState.connected) {
                            return FlatButton(
                              child: Text('載入頁面'),
                              color: Colors.tealAccent,
                              onPressed: () {
                                device.discoverServices();
                              },
                            );
                          } else {
                            return FlatButton(
                              child: Text('請稍後'),
                              color: Colors.grey,
                              onPressed: () {},
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: SizedBox(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                          width: 18.0,
                          height: 18.0,
                        ),
                        onPressed: null,
                      )
                    ],
                  ),
                ),

              ),
            ),



            StreamBuilder<List<BluetoothService>>(
              stream: device.services,
              initialData: [],
              builder: (c, snapshot) {
                return Column(
                  children: _buildServiceTiles(snapshot.data),
                );
              },
            ),


          ],
        ),
      ),



    );
  }



  //列出所有的服務
  List<Widget> _buildServiceTiles(List<BluetoothService> services) {

    // data.insert(0, '0');
    // datamode.insert(0, '0');
    //List<DateTime> _events = [];

    var X,X1 = '0'; //狀態，X1為上一筆資料，X為當下這筆
    var Y, Y1 = '0'; //模式，Y1為上一筆資料，Y為當下這筆
    var A ='0';
    var Z = 0;
    //宣告背景執行

    final cronpower = Cron();
    final cronstate = Cron();
    final cronset = Cron();
    final cronmode = Cron();
    final cronmodeauto = Cron();
    final cronpowerauto = Cron();




    return services.map((s)
    => ServiceTile(
        service: s,
        characteristicTiles: s.characteristics.map((c) {
          //檢測液面是否滿


          if ('0x${c.uuid.toString().toUpperCase().substring(4, 8)}' ==
              '0x1504') {
            // cronstateauto.schedule(
            //     Schedule.parse('*/20 * * * * *'), //安排每一分鐘紀錄一次值
            //         () async {
            //           c.setNotifyValue(!c.isNotifying);
            //         });
            cronstate.schedule(
                Schedule.parse('* */5 * * * *'), //安排每一分鐘紀錄一次值
                    () async {

                      //c.setNotifyValue(!c.isNotifying);
                      //Future.delayed(const Duration(milliseconds: 100), () {
                        streamSubscription = c.value.listen((value) {
                          if ((value.toString().substring(1, 2) == '1')) {
                            X = '需更換';
                          }
                          else if ((value.toString().substring(1, 2) == '0')) {
                            X = '不需更換';
                          }
                          else if ((value.toString().substring(1, 2) == '4'
                              || value.toString().substring(1, 2) == '5')) {
                            A = 'E';
                          }
                        },
                          onDone: () => streamSubscription.cancel(),
                        );
                        print(device.id.toString() + '->' + X + '->' + DateTime.now().toString());
                      // }
                      // );


      // Future state() async{
      //
      //     c.value.listen((value) {
      //     if ((value.toString().substring(1, 2) == '1')) {
      //       X = '需更換';
      //     }
      //     else if ((value.toString().substring(1, 2) == '0')) {
      //       X = '不需更換';
      //     }
      //     else if ((value.toString().substring(1, 2) == '4' ||
      //         value.toString().substring(1, 2) == '5')) {
      //       A = 'E';
      //     }
      //     print(c.value);
      //   }
      //   );
      // }
      // state();
      // print(X);
                    }
            );
          }



            //檢測使用模式------------------------------------------------------


            if ('0x${c.uuid.toString().toUpperCase().substring(4, 8)}' ==
                '0x1505') {
              // cronmodeauto.schedule(
              //     Schedule.parse('*/20 * * * * *'), //安排每一分鐘紀錄一次值
              //         () async {
              //       c.setNotifyValue(!c.isNotifying);
              //     });
              cronmode.schedule( Schedule.parse('* */5 * * * *'),
                    () async {
              //         //c.setNotifyValue(!c.isNotifying);
              //
              //
              //         Future.delayed(const Duration(milliseconds: 100), () {
              //           //   Future mode() async {
              //           //     //_events.insert(0, new DateTime.now());
                        streamSubscription = c.value.listen((value) {
                          if ((value.toString().substring(1, 2) == '1')) {
                            Y = '點滴模式';
                          }
                          else if ((value.toString().substring(1, 2) == '0')) {
                            Y = '尿袋模式';
                          }
                        },
                          onDone: () => dispose(),
                        );
                        print(device.id.toString() + '->' + Y + '->' + DateTime
                            .now().toString());
              //           //
              //           //   }
              //           //   mode();
              //           // } );
              //         }
              //         );
                     });

            }





            //上傳資料-------------------------------------------------------------------




            //設定一分鐘會上傳一次，如果與前一次值相同則不上傳
            //多delay200ms，確保此Future是最後一個執行，讓資料上傳的值是正確的
            cronset.schedule( Schedule.parse('* */5 * * * *'), () async {
            //
            //    Future.delayed(const Duration(milliseconds: 300), ()
            //    {
                //alldata記錄下來，以便下次進入此畫面中顯示
                //  alldata.insert(0, c.deviceId.toString() + DateFormat("yyyy-MM-dd HH:mm").format(_events[0]) + Y + X);

               // print('上傳');


                //
                if (X == '需更換' && X != X1 ) {
                  _collection.doc('${c.deviceId.toString()}')
                      .update({
                      'change': '1',
                    //'time':FieldValue.arrayUnion([{'date':Timestamp.fromDate(_events[0]).toDate(),'log':'背景 1'}]),
                    },
                  );
                }

                else if (X == '不需更換' && X != X1) {
                  _collection.doc('${c.deviceId.toString()}')
                      .update({
                    'change': '0',
                    //'time':FieldValue.arrayUnion([{'date':Timestamp.fromDate(_events[0]).toDate(),'log':'背景 0'}]),
                    //'time':FieldValue.arrayUnion([Timestamp.fromDate(_events[0]).toDate()]),
                  });
                }
                X1 = X;

                if (A == 'E') {
                  _collection.doc('${c.deviceId.toString()}')
                      .update({
                    'change': 'E',},);
                }



                if (Y == '尿袋模式' && Y != Y1) {
                  //	{上傳 mode:'尿袋'}
                  _collection.doc('${c.deviceId.toString()}')
                      .update({
                      'modedescription': '尿袋',
                    },
                  );
                }
                else if (Y == '點滴模式' && Y != Y1) {
                  //	{上傳  mode:'點滴'}
                  _collection.doc('${c.deviceId.toString()}')
                      .update({
                      'modedescription': '點滴',
                    },
                  );
                }
                Y1 = Y;


                if (25 < Z  ) {
                    _collection.doc('${c.deviceId.toString()}').update(
                      {
                        'alarm':'0',
                        'power': Z.toString()},
                       ); //設置後端響鈴
                      }

                if (0 < Z  && Z < 26 ) {
                  _collection.doc('${c.deviceId.toString()}').update(
                    {
                      'alarm':'1',
                      'power': Z.toString()
                    },
                      ); //設置後端響鈴
                }

    //
    //     });
    //
    //
    //
    //           // }
    //           // );
            });






     //上傳電量---------------------------------------------------------------------------------



           // cronset1.schedule(Schedule.parse('*/10 * * * * *'), () async {

              // Future.delayed(const Duration(milliseconds: 230), () {
              //   if (25 < Z  ) {
              //     //放電
              //     _collection.doc('${c.deviceId.toString()}')
              //         .update({
              //       'alarm':'0',
              //       'power': Z.toString()},
              //     ); //設置後端響鈴
              //   }
              //
              // // }
              // //  );
              //   if (0 < Z  && Z < 26 ) {
              //     //放電
              //     _collection.doc('${c.deviceId.toString()}')
              //         .update({
              //       'alarm':'1',
              //       'power': Z.toString()},
              //     ); //設置後端響鈴
              //   }

           // },
            //);
            // //cronset1.close();




    // Future.delayed(const Duration(milliseconds: 300), () {
    // Future set1() async {
    //   final cronset1 = Cron();
    //   cronset1.schedule(Schedule.parse('* */1 * * * *'), () async {
    //     if (0 < Z && Z != Z1) {
    //       //放電
    //       _collection.doc('${c.deviceId.toString()}')
    //           .update({
    //         'alarm': '0',
    //         'power': Z.toString()},
    //       ); //設置後端響鈴
    //     }
    //     Z1 = Z;
    //     print('我有船電量');
    //   },
    //   );
    //   await cronset1.close();
    // }
    // set1();
    // });



            //偵測電量--------------------------------------------------------------

            if ('0x${c.uuid.toString().toUpperCase().substring(4, 8)}' ==
                '0x1514') {
              // cronpowerauto.schedule(
              //     Schedule.parse('* */1 * * * *'), //安排每一分鐘紀錄一次值
              //         () async {
              //       c.read();
              //     });
              //   var cron = new Cron();//電量每1分鐘上傳一次
              cronpower.schedule(
                Schedule.parse('* */5 * * * *'),
                    () async {
              //         //     print('power');
              //         Future.delayed(const Duration(milliseconds: 200), () {
              //           //   Future power() async {
                        streamSubscription = c.value.listen((value)
                        {
                          Z = value[0];
                        },
                          onDone: () => dispose(),
                        );
              //           //     print(Z.toString());
              //           // }
              //           //   power();
              //           // }
              //           // );
              //           print(device.id.toString()+'->'+Z.toString()+'->'+DateTime.now().toString());
              //         },
              //         );
                     });
            }

            // if ('0x${c.uuid.toString().toUpperCase().substring(4, 8)}' ==
            //     '0x1514') {
            //   //   var cron = new Cron();//電量每1分鐘上傳一次
            //   Future.delayed(const Duration(milliseconds: 100), () {
            //     Future power() async {
            //       final cronpower = Cron();
            //       cronpower.schedule(
            //         Schedule.parse('* */1 * * * *'),
            //             () async {
            //           c.value.listen((value) {
            //             Z = value[0];
            //           });
            //           print('我有測power');
            //         },
            //       );
            //       await cronpower.close();
            //     }
            //   power();
            //   });
            // }



            return CharacteristicTile(
              characteristic: c,
              onReadPressed: () => c.read(),
              onNotificationPressed: () => c.setNotifyValue(!c.isNotifying),
            );


          },


        ).toList(),
      ),
    ).toList();
  }
 }
