// import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:mirrorfly_plugin/mirrorfly.dart';

import 'package:get/get.dart';
import 'package:mirror_fly_demo/app/common/app_theme.dart';
import 'package:mirror_fly_demo/app/common/constants.dart';
import 'package:mirror_fly_demo/app/common/main_controller.dart';
import 'package:mirror_fly_demo/app/data/helper.dart';
import 'package:mirror_fly_demo/app/data/pushnotification.dart';
import 'package:mirror_fly_demo/app/modules/dashboard/bindings/dashboard_binding.dart';
import 'package:mirror_fly_demo/app/modules/login/bindings/login_binding.dart';
import 'app/data/session_management.dart';
import 'app/model/reply_hash_map.dart';
import 'app/modules/profile/bindings/profile_binding.dart';
import 'app/routes/app_pages.dart';

import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';





// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // If you're going to use other Firebase services in the background, such as Firestore,
//   // make sure you call `initializeApp` before using other Firebase services.
//   //await Firebase.initializeApp();
//   debugPrint("Handling a background message: ${message.messageId}");
//   PushNotifications.onMessage(message);
// }
bool shouldUseFirebaseEmulator = false;
// dynamic nonChatUsers = [];
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Mirrorfly.init(
      baseUrl: 'https://api-preprod-sandbox.mirrorfly.com/api/v1/',
      licenseKey: 'Your License Key Here',
      chatHistoryEnable: true,
      iOSContainerID: 'group.com.mirrorfly.flutter',enableDebugLog: true);
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
  }
  // await SessionManagement.onInit();
  // ReplyHashMap.init();
  // Mirrorfly.isTrailLicence().then((value) => SessionManagement.setIsTrailLicence(value.checkNull()));
  // Mirrorfly.cancelNotifications();
  if (!kIsWeb) {
    await Firebase.initializeApp();
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    PushNotifications.setupInteractedMessage();
  }
  if (shouldUseFirebaseEmulator) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 5050);
  }
  await SessionManagement.onInit();
  // Get.put<MainController>(MainController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: "MirrorFly",
      theme: MirrorFlyAppTheme.theme,
      debugShowCheckedModeBanner: false,
      onInit: () {
        ReplyHashMap.init();
        // Mirrorfly.isTrailLicence().then((value) => SessionManagement.setIsTrailLicence(value.checkNull()));
        Get.put<MainController>(MainController());
      },
      //initialBinding: getBinding(),
      initialRoute: SessionManagement.getEnablePin() ? Routes.pin : getInitialRoute(),
      //initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    );
  }
}
Bindings? getBinding(){
  if(SessionManagement.getLogin()){
    if(SessionManagement.getName().checkNull().isNotEmpty && SessionManagement.getMobileNumber().checkNull().isNotEmpty){
      return DashboardBinding();
    }else{
      return ProfileBinding();
    }
  }else{
    return LoginBinding();
  }
}

String getInitialRoute() {
  if(!SessionManagement.adminBlocked()) {
    if (SessionManagement.getLogin()) {
      if (SessionManagement
          .getName()
          .checkNull()
          .isNotEmpty && SessionManagement
          .getMobileNumber()
          .checkNull()
          .isNotEmpty) {
        debugPrint("=====CHAT ID=====");
        debugPrint(SessionManagement.getChatJid());
        if (SessionManagement
            .getChatJid()
            .checkNull()
            .isEmpty) {
          if(!Mirrorfly.isTrialLicence) {
            // mirrorFlyLog("nonChatUsers", nonChatUsers.toString());
            mirrorFlyLog("SessionManagement.isContactSyncDone()", SessionManagement.isContactSyncDone().toString());
            if (!SessionManagement.isContactSyncDone() /*|| nonChatUsers.isEmpty*/) {
              return AppPages.contactSync;
            }else{
              return AppPages.dashboard;
            }
          }else{
            mirrorFlyLog("login", "${SessionManagement
                .getChatJid()
                .checkNull()
                .isEmpty}");
            mirrorFlyLog("SessionManagement.getLogin()", "${SessionManagement.getLogin()}");
            return AppPages.dashboard;
          }
        } else {
          return "${AppPages.chat}?jid=${SessionManagement.getChatJid()
              .checkNull()}&from_notification=true";
        }
      } else {
        return AppPages.profile;
      }
    } else {
      return AppPages.initial;
    }
  }else{
    return AppPages.adminBlocked;
  }
}

