import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:cron/cron.dart';

class CharacteristicTile extends StatelessWidget {
  final BluetoothCharacteristic characteristic;
  final VoidCallback onReadPressed;
  final VoidCallback onWritePressed;
  final VoidCallback onNotificationPressed;
  const CharacteristicTile(
      {Key key,
        this.characteristic,
        this.onReadPressed,
        this.onWritePressed,
        this.onNotificationPressed})
      : super(key: key);



  @override
  Widget build(BuildContext context) {



    var state,state1 = 'null'; //狀態，X1為上一筆資料，X為當下這筆
    var mode, mode1 = 'null';
    final cron =  Cron();
    var power ='99' ;


    // if ('0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}' ==
    //     '0x1504') {_onNotificationPressed();}
    // if ('0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}' ==
    //     '0x1505') {_onNotificationPressed();}
    // if ('0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}' ==
    //     '0x1514') {_onNotificationPressed();}
    return
      StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (c, snapshot) {
         final value = snapshot.data;

        //液體狀態設定，先判斷是否需要更換，後判斷是否與上一筆資料相同
        //若資料相同則不上傳
        if ('0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}' ==
            '0x1504') {

         if (value.toString() == '[1]') {
               state = '1';
               if(state != state1){
               FirebaseFirestore.instance.collection('NTUTLab321').doc(
                   '${characteristic.deviceId.toString()}').update({
                 'change': '1',
               });}
           //_events.insert(0, new DateTime.now().toUtc()); //紀錄時
           // messagewigets.insert(0, '需更換'); //紀錄狀態
           //顯示液體狀態及建立可滑動wigets來顯示每筆資料
           return ListView(
             shrinkWrap: true,
             children: <Widget>[
               Container(
                 height: 50,
                 child: Card(
                 child: Row(
                   children: <Widget>[
                     Chip(
                       label: Text('液體狀態', style: TextStyle(fontSize: 15.0),),
                     ),
                     Container(
                       width: 30,
                       height: 15,
                       decoration: BoxDecoration(
                         color: Colors.redAccent,
                         borderRadius: BorderRadius.circular(10),
                       ),
                     ),
                     Container(
                       child: Text('  請更換', style: TextStyle(fontSize: 15.0),),
                     ),
                   ],
                 ),
               ),
                 ),




             ],

           );

         }


         else if (value.toString() == '[0]') {
           state = '0';
           if(state != state1){
             FirebaseFirestore.instance.collection('NTUTLab321').doc(
                 '${characteristic.deviceId.toString()}').update({
               'change': '0',
               //'time':FieldValue.arrayUnion([DateTime.now()]),
             });}
           //_events.insert(0, new DateTime.now().toUtc()); //記錄當下時間，儲存在events
           //  messagewigets.insert(0, '已更換');
           return ListView(
             shrinkWrap: true,
             children: <Widget>[
               Container(
                 height: 50,
                 child:Card(
                 child: Row(
                   children: <Widget>[
                     Chip(
                       label: Text('液體狀態', style: TextStyle(fontSize: 15.0),),
                     ),
                     Container(
                       width: 50,
                       height: 15,
                       decoration: BoxDecoration(
                         color: Colors.greenAccent,
                         borderRadius: BorderRadius.circular(10),
                       ),
                     ),
                     Container(
                       child: Text('  正常', style: TextStyle(fontSize: 15.0),),
                     ),
                   ],
                 ),
               ),),
             ],
           );
         }

         else if (value.toString() == '[2]' || value.toString() == '[3]') {

           return Container(height:50,child:Card(
               child: Text('準備資料中 請稍後...', style: TextStyle(fontSize: 15),)));
         }
         else if (value.toString() == '[4]' || value.toString() == '[5]') {
           FirebaseFirestore.instance.collection('NTUTLab321').doc(
               '${characteristic.deviceId.toString()}').update({
             'change': 'E',
           });

           return Container(height:50,child:Card(child: Text('感測器故障', style: TextStyle(fontSize: 15),)));
         }
         state1 = state;
        }


        //設定模式相關設定，先判斷是點滴還尿袋，後判斷是否與上一筆資料一樣，如果一樣則不上傳
        if ('0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}' ==
            '0x1505') {
          //characteristic.setNotifyValue(!characteristic.isNotifying)
                    if (value.toString() == '[1]') {

                      mode = '1';
                      if(mode != mode1){
                        FirebaseFirestore.instance.collection('NTUTLab321').doc(
                            '${characteristic.deviceId.toString()}').update({
                          'modedescription': '1',
                        });}
                      //_events.insert(0, new DateTime.now().toUtc());
                      // messagemodewigets.insert(0, '點滴模式');
                      return ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          Container(
                            height: 50,
                           child:Card(
                            child: Row(
                             children: <Widget>[
                              Chip(label: Text('設備模式', style: TextStyle(fontSize: 15.0),),),
                              Icon(Icons.water_damage_outlined,color: Colors.lightBlueAccent,),
                              Container(
                               child: Text('  點滴模式', style: TextStyle(fontSize: 15.0),),
                              ),
                             ],
                            ),
                           ),),
                        ],
                      );
                    }
                    else if (value.toString() == '[0]') {
                      mode = '0';
                      if(mode != mode1){
                        FirebaseFirestore.instance.collection('NTUTLab321').doc(
                            '${characteristic.deviceId.toString()}').update({
                          'modedescription': '0',
                        });}
                      // _events.insert(0, new DateTime.now().toUtc());
                      // messagemodewigets.insert(0, '尿袋模式');
                      return ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          Container(height:50,child:Card(
                            child: Row(
                              children: <Widget>[
                                Chip(
                                  label: Text(
                                    '設備模式', style: TextStyle(fontSize: 15.0),),
                                ),
                                Icon(Icons.whatshot_outlined,color: Colors.yellow,),
                                Container(
                                  child: Text(
                                    '  尿袋模式', style: TextStyle(fontSize: 15.0),),
                                ),

                              ],
                            ),
                          ),),
                        ],
                      );
                    }
                    mode1 = mode;
        }



        //顯示電量
        if ('0x${characteristic.uuid.toString().toUpperCase().substring(4, 8)}' ==
            '0x1514')
          {
            //characteristic.setNotifyValue(!characteristic.isNotifying);


          if (value.isNotEmpty  && value[0] > 74){
            power = value.toString();
            // FirebaseFirestore.instance.collection('NTUTLab321').doc('${characteristic.deviceId.toString()}').update({
            //   'alarm':'0',
            //   'power': value[0].toString(),
            // });

            return Card(
              child: Row(
                children: <Widget>[
                  Chip(
                    label: Text('剩餘電力', style: TextStyle(fontSize: 15.0),),
                  ),
                  Container(
                    height: 20,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.battery_full,color: Colors.green,),
                        Text(value[0].toString() + "%" +'  電量充足',
                            style: TextStyle(fontSize: 15.0)),

                      ],
                    ),
                  ),

                ],
              ),
            );
          }
          else if (value.isNotEmpty  && value[0] < 75 && value[0] > 24){
            power = value.toString();
            // FirebaseFirestore.instance.collection('NTUTLab321').doc('${characteristic.deviceId.toString()}').update({
            //   'alarm':'0',
            //   'power': value[0].toString(),
            // });
            return Card(
              child: Row(
                children: <Widget>[
                  Chip(
                    label: Text('剩餘電力', style: TextStyle(fontSize: 15.0),),
                  ),
                  Container(
                    height: 20,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.battery_full_sharp,color: Colors.yellowAccent,),
                        Text(value[0].toString() + "%" +'  建議充電',
                            style: TextStyle(fontSize: 15.0)),

                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          else if (value.isNotEmpty  && value[0] < 25 ){
            power = value.toString();
            // FirebaseFirestore.instance.collection('NTUTLab321').doc('${characteristic.deviceId.toString()}').update({
            //   'alarm':'1',
            //   'power': value[0].toString(),
            // });
            return Card(
              child: Row(
                children: <Widget>[
                  Chip(
                    label: Text('剩餘電力', style: TextStyle(fontSize: 15.0),),
                  ),
                  Container(
                    height: 20,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.battery_alert,color: Colors.redAccent,),
                        Text(value[0].toString()+ "%" +'  電量不足',
                            style: TextStyle(fontSize: 15.0)),

                      ],
                    ),
                  ),
                ],
              ),
            );
          }

        }

         cron.schedule( Schedule.parse('* */1 * * * *'), () async {
             FirebaseFirestore.instance.collection('NTUTLab321').doc(
                 '${characteristic.deviceId.toString()}').update({
               'power': power.toString().substring(1, 3),
             });
             print(power.toString().substring(1, 3)+DateTime.now().toString());
           });






        //其他版面設定，未用到
         //

        return Container(
          height: 50,
          child:

          ListTile(
            title: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[

                  //Theme.of(context).textTheme.bodyText2.copyWith(color: Theme.of(context).textTheme.caption.color),
                Row(
                  // mainAxisSize: MainAxisSize.min,
                  children: <Widget>[

                    Text('請載入或更新資料  (${characteristic.uuid.toString().toUpperCase().substring(4, 8)})',
                      style: TextStyle(fontSize: 10,),),
                    // IconButton(
                    //   icon: Icon(Icons.file_download, color: Theme.of(context).iconTheme.color.withOpacity(0.5),size:15 ,),
                    //   onPressed: onReadPressed,
                    // ),
                    IconButton(
                      icon: Icon(characteristic.isNotifying ? Icons.sync_disabled : Icons.sync, color: Theme.of(context).iconTheme.color.withOpacity(0.5),size:15),
                      onPressed:
                         // (){},
                          () { _onNotificationPressed();},
                      //onNotificationPressed,
                    ),

                  ],

                ),

              ],
            ),
           // subtitle: Text(value.toString(),style:TextStyle(fontSize: 10,)),
            contentPadding: EdgeInsets.all(0.0),

          ),
        );





      },
    );



  }
  void _onNotificationPressed() {
    characteristic.setNotifyValue(!characteristic.isNotifying);
  }

}