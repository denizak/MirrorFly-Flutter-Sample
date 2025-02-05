import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/constants.dart';
import '../../../data/apputils.dart';
import '../../../data/session_management.dart';
import '../../../data/helper.dart';
import 'package:mirrorfly_plugin/mirrorfly.dart';
import '../../../routes/app_pages.dart';

class DeleteAccountController extends GetxController {

  var india = CountryData(name: "India", dialCode: "+91", code: "IN");
  var selectedCountry = CountryData(name: "India", dialCode: "+91", code: "IN").obs;

  String? get countryCode => selectedCountry.value.dialCode;
  TextEditingController mobileNumber = TextEditingController();


  deleteAccount() async {
    if(await AppUtils.isNetConnected()) {
      if(mobileNumber.text.isEmpty){
        Helper.showAlert(message: "Please enter your mobile number", actions: [
          TextButton(
              onPressed: () {
                Get.back();
              },
              child: const Text("Ok")),
        ]);
        return;
      }
      mirrorFlyLog("SessionManagement.getMobileNumber()", SessionManagement.getMobileNumber().toString().trim());
      mirrorFlyLog("SessionManagement.getCountryCode()", SessionManagement.getCountryCode().toString());
      mirrorFlyLog("Mirrorfly.isTrialLicence", Mirrorfly.isTrialLicence.toString());
      mirrorFlyLog("countryCode", countryCode.toString());
      var mobileNumberWithCountryCode = '${countryCode?.replaceAll('+', '')}${mobileNumber.text.trim()}';
      mirrorFlyLog("mobileNumberWithCountryCode", mobileNumberWithCountryCode);
      if(Mirrorfly.isTrialLicence) {
        if ((mobileNumber.text.trim() != SessionManagement.getMobileNumber() && mobileNumberWithCountryCode != SessionManagement.getMobileNumber()) ||
            SessionManagement.getCountryCode()?.replaceAll('+', '') !=
                countryCode?.replaceAll('+', '')) {
          Helper.showAlert(
              message: "The mobile number you entered doesn't match your account",
              actions: [
                TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text("Ok")),
              ]);
          return;
        }
      }else{
        var mob = '${countryCode?.replaceAll('+', '').toString().checkNull()}${mobileNumber.text.trim()}';
        if (mob != SessionManagement.getMobileNumber()) {
          Helper.showAlert(
              message: "The mobile number you entered doesn't match your account",
              actions: [
                TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: const Text("Ok")),
              ]);
          return;
        }
      }
      Get.toNamed(Routes.deleteAccountReason);
    }else{
      toToast(Constants.noInternetConnection);
    }
  }

}
