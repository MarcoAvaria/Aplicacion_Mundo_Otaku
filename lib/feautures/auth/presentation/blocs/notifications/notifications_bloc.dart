//import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

//import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:aplicacion_mundo_otaku/domain/entities/push_message.dart';
import 'package:aplicacion_mundo_otaku/firebase_options.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  //await Firebase.initializeApp();
  await Firebase.initializeApp().then((app) {
    //print("Initialized $app");
    // FirebaseMessaging.instance.getToken().then((token) {
    //   if (kDebugMode) {
    //     print("My token is: $token");
    //   }
    // });
  });

  print("Handling a background message: ${message.messageId}");
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  
  FirebaseMessaging messaging = FirebaseMessaging.instance;


  NotificationsBloc() : super(const NotificationsState()) {
    
    on<NotificationStatusChanged>( _notificationStatusChanged );
    on<NotificationReceived>( _onPushMessageReceived );

    // Verificar estado de notificaciones
    _initialStatusCheck();

    // Lister para notificaciones en Foreground
    _onForegroundMessage();

  }


  static Future<void> initializeFCM() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }


  void _notificationStatusChanged( NotificationStatusChanged event, Emitter<NotificationsState> emit ) {
    emit(
      state.copyWith(
        status: event.status
      ));
      _getFCMToken();
  }

  void _onPushMessageReceived( NotificationReceived event, Emitter<NotificationsState> emit ) {
    emit(
      state.copyWith(
        notifications: [ event.pushMessage, ...state.notifications ]
      )
    );  
  }


  void _initialStatusCheck() async {
    final settings = await messaging.getNotificationSettings();
    add( NotificationStatusChanged(settings.authorizationStatus));
    
  }

  void _getFCMToken() async {
    //final setting = await messaging.getNotificationSettings();
    if ( state.status != AuthorizationStatus.authorized ) return ;

    final token = await messaging.getToken();
    print(token);
  }

  void handleRemoteMessage( RemoteMessage message ) {
    //print('Got a message whilst in the foreground!');
    //print('Message data: ${message.data}');
    if (message.notification == null) return;
    //print('Message also contained a notification: ${message.notification}');
    final notification = PushMessage(
      messageId: message.messageId
        ?.replaceAll(':', '').replaceAll('%', '')
        ?? '', 
      title: message.notification!.title ?? '', 
      body: message.notification!.body ?? '', 
      sentDate: message.sentTime ?? DateTime.now(),
      data: message.data,
      imageUrl: Platform.isAndroid
        ? message.notification!.android?.imageUrl
        : message.notification!.apple?.imageUrl,
    );

    add( NotificationReceived( notification ) );
    //print(notification);
  }

  void _onForegroundMessage() {
    FirebaseMessaging.onMessage.listen( handleRemoteMessage );
  }
  

  void requestPermission() async {

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    add( NotificationStatusChanged(settings.authorizationStatus));
  }

  PushMessage? getMessageById( String pushMessageId ) {
    final exist = state.notifications.any((element) => element.messageId == pushMessageId);
    if ( !exist ) return null;

    return state.notifications.firstWhere((element) => element.messageId == pushMessageId );
  }
}
