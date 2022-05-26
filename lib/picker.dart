import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application/cubits/cubit/detect_cubit.dart';
import 'package:flutter_application/login.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class PickImage extends StatefulWidget {
  const PickImage({Key? key}) : super(key: key);

  @override
  State<PickImage> createState() => _PickImageState();
}

class _PickImageState extends State<PickImage> {
  final ImagePicker _picker = ImagePicker();

  User? user = FirebaseAuth.instance.currentUser;
  UserModel loggedInUser = UserModel();

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get()
        .then((value) {
      this.loggedInUser = UserModel.fromMap(value.data());
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
          actions: [
            MaterialButton(
              onPressed: () {
                logout(context);
                context.read<DetectCubit>().reload();
              },
              child: Row(
                children: [Text("Log out")],
              ),
            )
          ],
          title: const Text("Welcome"),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 160, 75, 189)),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: SizedBox(
                  height: 100,
                  child: Image.asset(
                    "assets/camera.png",
                    fit: BoxFit.contain,
                  )),
            ),
            BlocBuilder<DetectCubit, DetectState>(
              builder: (context, state) {
                if (state is DetectInitial) {
                  return Container(
                    height: height / 5,
                    width: width,
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Color.fromARGB(255, 242, 239, 244))),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                          child: ElevatedButton(
                              child: Text("Pick an Image"),
                              onPressed: () async {
                                final XFile? image = await _picker.pickImage(
                                    source: ImageSource.gallery);
                                if (image != null) {
                                  File file = File(image.path);
                                  context.read<DetectCubit>().detect(file);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  primary: Color.fromARGB(255, 160, 75, 189)))),
                    ),
                  );
                } else if (state is DetectLoad) {
                  return Center(
                    child: Container(
                        height: height / 5,
                        width: width,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Wait while we load the data"),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: SpinKitRotatingCircle(
                                color: Color.fromARGB(255, 160, 75, 189),
                                size: 50.0,
                              ),
                            ),
                          ],
                        )),
                  );
                } else if (state is DetectSuccess) {
                  return Center(
                    child: Container(
                        height: height / 3,
                        width: width,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Text("The person is identified as a criminal.",
                          style: TextStyle(color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                  "\nThe confidence level is ${(state.level * 100).toStringAsFixed(3)}%"),
                            ),
                                Text("Name:${state.name}\n",
                                style: TextStyle(color:Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 25),),
                            ElevatedButton(
                                onPressed: () {
                                  context.read<DetectCubit>().reload();
                                },
                                child: Text("Check for another person"),
                                style: ElevatedButton.styleFrom(
                                    primary:
                                        Colors.green))
                          ],
                        )),
                  );
                } else if (state is DetectError) {
                  return Center(
                    child: Container(
                        height: height / 5,
                        width: width,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("This Person is not identified as a criminal",
                            style: TextStyle(fontSize:20,
                            fontWeight: FontWeight.bold),),
                            Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: ElevatedButton(
                                  onPressed: () {
                                    context.read<DetectCubit>().reload();
                                  },
                                  child: Text("Check for another person"),
                                  ),
                            )
                          ],
                        )),
                  );
                } else
                  return Container();
              },
            )
          ],
        ),
      ),
    );
  }
}

Future<void> logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  Navigator.of(context)
      .pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen()));
}
