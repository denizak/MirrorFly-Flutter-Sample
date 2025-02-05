import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libphonenumber/flutter_libphonenumber.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mirror_fly_demo/app/common/constants.dart';
import 'package:mirror_fly_demo/app/data/session_management.dart';
import 'package:mirror_fly_demo/app/data/helper.dart';
import 'package:mirror_fly_demo/app/routes/app_pages.dart';

import '../../../common/crop_image.dart';
import 'package:mirrorfly_plugin/mirrorfly.dart';

import '../../../data/apputils.dart';
import '../../../data/permissions.dart';

class ProfileController extends GetxController {
  TextEditingController profileName = TextEditingController();
  TextEditingController profileEmail = TextEditingController();
  TextEditingController profileMobile = TextEditingController();
  var profileStatus = "I am in Mirror Fly".obs;
  var isImageSelected = false.obs;
  var isUserProfileRemoved = false.obs;
  var imagePath = "".obs;
  var userImgUrl = "".obs;
  var emailPatternMatch = RegExp(Constants.emailPattern,multiLine: false);
  var loading = false.obs;
  var changed = false.obs;

  dynamic imageBytes;
  var from = Get.previousRoute;//Routes.login.obs;

  var name = "".obs;

  bool get emailEditAccess => true;//Get.previousRoute!=Routes.settings;
  RxBool mobileEditAccess = false.obs;//Get.previousRoute!=Routes.settings;

  var userNameFocus= FocusNode();
  var emailFocus= FocusNode();
  @override
  Future<void> onInit() async {
    super.onInit();
    userImgUrl.value = SessionManagement.getUserImage() ?? "";
    mirrorFlyLog("auth : ", SessionManagement.getAuthToken().toString());
    if (Get.arguments != null) {
      // from(Get.arguments["from"]);
      if (from == Routes.login) {
        profileMobile.text = Get.arguments['mobile'] ?? "";
      }
    } else {
      profileMobile.text = "";
    }
    if (from == Routes.login) {
      if(await AppUtils.isNetConnected()) {
        getProfile();
      }else{
        toToast(Constants.noInternetConnection);
      }
      checkAndEnableNotificationSound();
    }else{
      getProfile();
    }
    //profileStatus.value="I'm Mirror fly user";
    // await askStoragePermission();
    await AppPermission.getStoragePermission();
  }


  Future<void> save({bool frmImage=false}) async {
    var permission = await AppPermission.getStoragePermission();
    if (permission) {
      if (profileName.text
          .trim()
          .isEmpty) {
        toToast("Please enter your username");
      } else if (profileName.text
          .trim()
          .length < 3) {
        toToast("Username is too short");
      } else if (profileEmail.text
          .trim()
          .isEmpty) {
        toToast("Email should not be empty");
      } else if (!emailPatternMatch.hasMatch(profileEmail.text.toString())) {
        toToast("Please enter a valid Mail");
      } else if (profileStatus.value.isEmpty) {
        toToast("Enter Profile Status");
      } else {
        loading.value = true;
        showLoader();
        if (imagePath.value.isNotEmpty) {
          debugPrint("profile image update");
          updateProfileImage(imagePath.value, update: true);
        } else {
          if (await AppUtils.isNetConnected()) {
            debugPrint("profile update");
            var parse = await FlutterLibphonenumber().parse(profileMobile.text);
            debugPrint("parse-----> $parse");
            var unformatted = parse['national_number'];//profileMobile.text.replaceAll(" ", "").replaceAll("+", "");
            Mirrorfly
                .updateMyProfile(
                profileName.text.toString(),
                profileEmail.text.toString(),
                unformatted,
                profileStatus.value.toString(),
                userImgUrl.value.isEmpty ? null : userImgUrl.value
            )
                .then((value) {
              mirrorFlyLog("updateMyProfile", value);
              loading.value = false;
              hideLoader();
              if (value != null) {
                debugPrint(value);
                var data = profileUpdateFromJson(value);
                if (data.status != null) {
                  toToast(frmImage ? 'Removed profile image successfully' : data.message.toString());
                  if (data.status!) {
                    changed(false);
                    var userProfileData = ProData(
                        email: profileEmail.text.toString(),
                        image: userImgUrl.value,
                        mobileNumber: unformatted,
                        nickName: profileName.text,
                        name: profileName.text,
                        status: profileStatus.value);
                    SessionManagement.setCurrentUser(userProfileData);
                    if (from == Routes.login) {
                      // Mirrorfly.isTrailLicence().then((trail){
                        if(Mirrorfly.isTrialLicence) {
                          Get.offNamed(Routes.dashboard);
                        }else{
                          Get.offNamed(Routes.contactSync);
                        }
                      // });
                    }
                  }
                }
              } else {
                toToast("Unable to update profile");
              }
            }).catchError((error) {
              loading.value = false;
              hideLoader();
              debugPrint("issue===> $error");
              toToast(error.toString());
            });
          } else {
            loading(false);
            hideLoader();
            toToast(Constants.noInternetConnection);
          }
        }
      }
    }
  }

  updateProfileImage(String path, {bool update = false}) async {
    if(await AppUtils.isNetConnected()) {
      loading.value = true;

      // if(checkFileUploadSize(path, Constants.mImage)) {
        showLoader();
        Mirrorfly.updateMyProfileImage(path).then((value) {
          mirrorFlyLog("updateMyProfileImage", value);
          loading.value = false;
          var data = json.decode(value);
          imagePath.value = Constants.emptyString;
          userImgUrl.value = data['data']['image'];
          SessionManagement.setUserImage(data['data']['image'].toString());
          hideLoader();
          if (update) {
            save();
          }
        }).catchError((onError) {
          debugPrint("Profile Update on error--> ${onError.toString()}");
          loading.value = false;
          hideLoader();
        });
      // }else{
      //   toToast("Image Size exceeds 10MB");
      // }
    }else{
      toToast(Constants.noInternetConnection);
    }

  }

  removeProfileImage() async {
    if(await AppUtils.isNetConnected()) {
      showLoader();
      loading.value = true;
      Mirrorfly.removeProfileImage().then((value) {
        loading.value = false;
        hideLoader();
        if (value != null) {
          SessionManagement.setUserImage(Constants.emptyString);
          isImageSelected.value = false;
          isUserProfileRemoved.value = true;
          userImgUrl(Constants.emptyString);
          if (from == Routes.login) {
            changed(true);
          } else {
            save(frmImage: true);
          }
          update();
        }
      }).catchError((onError) {
        loading.value = false;
        hideLoader();
      });
    }else{
      toToast(Constants.noInternetConnection);
    }
  }

  getProfile() async {
    //if(await AppUtils.isNetConnected()) {
      var jid = SessionManagement.getUserJID().checkNull();
      mirrorFlyLog("jid", jid);
      if (jid.isNotEmpty) {
        mirrorFlyLog("jid.isNotEmpty", jid.isNotEmpty.toString());
        loading.value = true;
        Mirrorfly.getUserProfile(jid,await AppUtils.isNetConnected()).then((value) {
          debugPrint("profile--> $value");
          insertDefaultStatusToUser();
          loading.value = false;
          var data = profileDataFromJson(value);
          if (data.status != null && data.status!) {
            if (data.data != null) {
              profileName.text = data.data!.name ?? "";
              if (data.data!.mobileNumber.checkNull().isNotEmpty) {
                //if (from.value != Routes.login) {
                validMobileNumber(data.data!.mobileNumber.checkNull()).then((valid) {
                  // if(valid) profileMobile.text = data.data!.mobileNumber.checkNull();
                  mobileEditAccess(!valid);
                });
              }else {
                mobileEditAccess(true);
              }

              profileEmail.text = data.data!.email ?? "";
              profileStatus.value = data.data!.status.checkNull().isNotEmpty ? data.data!.status.checkNull() : "I am in Mirror Fly";
              userImgUrl.value = data.data!.image ?? "";//SessionManagement.getUserImage() ?? "";
              SessionManagement.setUserImage(Constants.emptyString);
              changed((from == Routes.login));
              name(data.data!.name.toString());
              var userProfileData = ProData(
                  email: profileEmail.text.toString(),
                  image: userImgUrl.value,
                  mobileNumber: data.data!.mobileNumber.checkNull(),
                  nickName: profileName.text,
                  name: profileName.text,
                  status: profileStatus.value);
              SessionManagement.setCurrentUser(userProfileData);
              update();
            }
          } else {
            debugPrint("Unable to load Profile data");
            toToast("Unable to Connect to Server. Please login Again");
          }
        }).catchError((onError) {
          loading.value = false;
          toToast("Unable to load profile data, please login again");
        });
      }
   /* }else{
      toToast(Constants.noInternetConnection);
      Get.back();
    }*/

  }

  static void insertDefaultStatusToUser() async{
    try {
      await Mirrorfly.getProfileStatusList().then((value) {
        mirrorFlyLog("status list", "$value");
        if (value != null) {
          var profileStatus = statusDataFromJson(value.toString());
          if (profileStatus.isNotEmpty) {
            debugPrint("profile status list is not empty");
            var defaultStatus = Constants.defaultStatusList;

            for (var statusValue in defaultStatus) {
              var isStatusNotExist = true;
              for (var flyStatus in profileStatus) {
                if (flyStatus.status == (statusValue)) {
                  isStatusNotExist = false;
                }
              }
              if (isStatusNotExist) {
                Mirrorfly.insertDefaultStatus(statusValue);
              }
            }
          }else{
            insertStatus();
          }
        }else{
          debugPrint("status list is empty");
          insertStatus();

        }
      });
    } on Exception catch(er){
      debugPrint("Exception ==> $er");
    }
  }

  Future imagePicker(BuildContext context) async {
    if(await AppUtils.isNetConnected()) {
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(allowMultiple: false, type: FileType.image);
      if (result != null) {
        if(checkFileUploadSize(result.files.single.path!, Constants.mImage)) {
          isImageSelected.value = true;
          Get.to(CropImage(
            imageFile: File(result.files.single.path!),
          ))?.then((value) {
            value as MemoryImage;
            imageBytes = value.bytes;
            var name = "${DateTime
                .now()
                .millisecondsSinceEpoch}.jpg";
            writeImageTemp(value.bytes, name).then((value) {
              if (from == Routes.login) {
                imagePath(value.path);
                changed(true);
                update();
              } else {
                imagePath(value.path);
                // changed(true);
                updateProfileImage(value.path, update: false);
              }
            });
          });
        }else{
          toToast("Please select Image less than 10MB");
        }
      } else {
        // User canceled the picker
        isImageSelected.value = false;
      }
    }else{
      toToast(Constants.noInternetConnection);
    }
  }

  final ImagePicker _picker = ImagePicker();
  camera() async {
    if(await AppUtils.isNetConnected()) {
      final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera);
      if (photo != null) {
        isImageSelected.value = true;
        Get.to(CropImage(
          imageFile: File(photo.path),
        ))?.then((value) {
          value as MemoryImage;
          imageBytes = value.bytes;
          var name = "${DateTime.now().millisecondsSinceEpoch}.jpg";
          writeImageTemp(value.bytes, name).then((value) {
            if (from == Routes.login) {
              imagePath(value.path);
              changed(true);
            } else {
              imagePath(value.path);
              // changed(true);
              updateProfileImage(value.path, update: false);
            }
          });
        });
      } else {
        // User canceled the Camera
        isImageSelected.value = false;
      }
    }else{
      toToast(Constants.noInternetConnection);
    }
  }

  void showLoader() {
    Helper.progressLoading();
  }

  /// To hide loader
  void hideLoader() {
    Helper.hideLoading();
  }

  nameChanges(String text) {
    changed(true);
    name(profileName.text.toString());
    update();
  }

  onEmailChange(String text) {
    changed(true);
    update();
  }

  onMobileChange(String text){
    changed(true);
    validMobileNumber(text);
    update();
  }

  Future<bool> validMobileNumber(String text)async{
    var coded = text;
    if(!text.startsWith(SessionManagement.getCountryCode().toString())){
      mirrorFlyLog("SessionManagement.getCountryCode()", SessionManagement.getCountryCode().toString());
      coded = SessionManagement.getCountryCode().checkNull()+text;
    }
    var m = coded.contains("+") ? coded : "+$coded";
    /*var formattingMobileNumber = text;
    ///Added this function, due to the mobile number is Android and iOS is receiving without Country Code in Response
    if (text.startsWith("+") && text.substring(1).startsWith(SessionManagement.getCountryCode() ?? "")) {
      ///No need to append anything as the input contains Mobile Number with Country Code
      formattingMobileNumber = formattingMobileNumber.replaceFirst("+${SessionManagement.getCountryCode()}", "");
    }else{
      if (text.substring(0).startsWith(SessionManagement.getCountryCode() ?? "")) {
        ///if input have country code and mobile number and doesn't contain (+), we are appending it here
        formattingMobileNumber = formattingMobileNumber.replaceFirst("${SessionManagement.getCountryCode()}", "");
      } else {
        ///Else we are appending both (+) and Country Code with the input
        formattingMobileNumber = text;
      }
    }*/
    FlutterLibphonenumber().init();
    var formatNumberSync = FlutterLibphonenumber().formatNumberSync(m);
    try {
      var parse = await FlutterLibphonenumber().parse(formatNumberSync);
      debugPrint("parse-----> $parse");
      //{country_code: 91, e164: +91xxxxxxxxxx, national: 0xxxxx xxxxx, type: mobile, international: +91 xxxxx xxxxx, national_number: xxxxxxxxxx, region_code: IN}
      if (parse.isNotEmpty) {
        var formatted = parse['international'];//.replaceAll("+", '');
        profileMobile.text = formatted;
        return true;
      } else {
        return false;
      }
    }catch(e){
      debugPrint('validMobileNumber $e');
      return false;
    }
  }

  static void insertStatus() {
    debugPrint("Inserting Status");
    var defaultStatus = Constants.defaultStatusList;

    for (var statusValue in defaultStatus) {
      Mirrorfly.insertDefaultStatus(statusValue);

    }
    // Mirrorfly.getDefaultNotificationUri().then((value) {
    //   if (value != null) {
    //     // Mirrorfly.setNotificationUri(value);
    //     SessionManagement.setNotificationUri(value);
    //   }
    // });
  }
  static void checkAndEnableNotificationSound() {

    SessionManagement.vibrationType("0");
    SessionManagement.convSound(true);
    SessionManagement.muteAll(false);

    Mirrorfly.getDefaultNotificationUri().then((value) {
      debugPrint("getDefaultNotificationUri--> $value");
      if (value != null) {
        // Mirrorfly.setNotificationUri(value);
        SessionManagement.setNotificationUri(value);
        Mirrorfly.setNotificationSound(true);
        Mirrorfly.setDefaultNotificationSound();
        SessionManagement.setNotificationSound(true);
      }
    });
  }
}
