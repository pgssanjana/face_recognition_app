import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
part 'detect_state.dart';

class DetectCubit extends Cubit<DetectState> {
  DetectCubit() : super(DetectInitial());

  final detectURL = Uri.parse(
      "https://recognitionengage.cognitiveservices.azure.com/face/v1.0/detect?returnFaceId=true&recognitionModel=recognition_04");
  final identifyURL = Uri.parse(
      "https://recognitionengage.cognitiveservices.azure.com/face/v1.0/identify");
      //insert api key here 
  static const API_KEY = "";

  void detect(File file) async {
    var faceid = null;
    var confidencelevel = null;
    var personid = null;
    if (file != null) {
      emit(DetectLoad());

      //Make 3 API Calls
      var response1 = null;
      // 1) Detect the faces in the image and get the face id
      try {
        response1 = await http.post(detectURL,
            headers: {
              "Ocp-Apim-Subscription-Key": API_KEY,
              "Content-Type": "application/octet-stream"
            },
            body: await file.readAsBytes());
      } on SocketException {
        emit(DetectError());
      }
      var response2 = null;
      if (response1.statusCode >= 200 && response1.statusCode <= 300) {
        final responseMap1 = jsonDecode(response1.body);
        if (responseMap1.isNotEmpty) faceid = responseMap1[0]["faceId"];
        // 2) Use the face id and make a face-identify API call
        try {
          response2 = await http.post(identifyURL,
              headers: {
                "Ocp-Apim-Subscription-Key": API_KEY,
                "Content-Type": "application/json"
              },
              body: jsonEncode({
                "personGroupId": "criminals",
                "faceIds": [faceid]
              }));
        } on SocketException {
          emit(DetectError());
        }

        if (response2.statusCode >= 200 && response2.statusCode <= 300) {
          final responseMap2 = jsonDecode(response2.body);
          final li = responseMap2[0]["candidates"];
          if (li.isNotEmpty) {
            confidencelevel = li[0]["confidence"];
            personid = li[0]["personId"];
            // print(personid);
            final face_nameURL = Uri.parse(
                "https://recognitionengage.cognitiveservices.azure.com/face/v1.0/persongroups/criminals/persons/${personid}");
            var response3 = null;
            //3)Fetch the person id and make an API call to fetch the name of the person
            try {
               response3 = await http.get(face_nameURL,
                  headers: {"Ocp-Apim-Subscription-Key": API_KEY});
            } on SocketException {
              emit(DetectError());
            }

            print("AS" + response3.body);
            if (response3.statusCode >= 200 && response3.statusCode <= 300) {
              final responseMap3 = jsonDecode(response3.body);
              final li = responseMap3["name"];
              // print(li);
              // print(responseMap3);
              emit(DetectSuccess(level: confidencelevel, name: li));
            }
          } else {
            emit(DetectError());
          }

          //resposne 3

        } else {
          emit(DetectError());
        }
      } else {
        emit(DetectError());
      }
    }
  }

  void reload() {
    emit(DetectInitial());
  }
}
