import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_shop/Widgets/customTextField.dart';
import 'package:e_shop/DialogBox/errorDialog.dart';
import 'package:e_shop/DialogBox/loadingDialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Store/storehome.dart';
import 'package:e_shop/Config/config.dart';

class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController nameTextEditingController =
      TextEditingController();
  final TextEditingController emailTextEditingController =
      TextEditingController();
  final TextEditingController passwordTextEditingController =
      TextEditingController();
  final TextEditingController cPasswordTextEditingController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String userImageUrl = "";
  File _imageFile;
  final imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(6.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              height: SizeConfig.blockSizeVertical * 2,
            ),
            InkWell(
              onTap: () {
                selectAndPicImage();
              },
              child: CircleAvatar(
                radius: SizeConfig.blockSizeHorizontal * 15,
                backgroundColor: Colors.white,
                backgroundImage:
                    _imageFile == null ? null : FileImage(_imageFile),
                child: _imageFile == null
                    ? Icon(
                        Icons.add_photo_alternate,
                        size: SizeConfig.blockSizeHorizontal * 15,
                        color: Colors.grey,
                      )
                    : null,
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical * 8,
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    isObsecure: false,
                    controller: nameTextEditingController,
                    data: Icons.person,
                    hintText: "Name",
                  ),

                  CustomTextField(
                    isObsecure: false,
                    controller: emailTextEditingController,
                    data: Icons.email,
                    hintText: "Email",
                  ),

                  CustomTextField(
                    isObsecure: true,
                    controller: passwordTextEditingController,
                    data: Icons.lock,
                    hintText: "Password",
                  ),

                  CustomTextField(
                    isObsecure: true,
                    controller: cPasswordTextEditingController,
                    data: Icons.lock,
                    hintText: "Confirm password",
                  ),
                ],
              ),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical * 8,
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical * 6,
              width: SizeConfig.blockSizeHorizontal * 40,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.pink,
                    shape: StadiumBorder(),
                  ),
                  onPressed: () {
                    uploadAndSaveImage();
                  },
                  child: Text(
                    "Sign up",
                    style: TextStyle(color: Colors.white),
                  )),
            ),
            SizedBox(
              height: SizeConfig.blockSizeVertical * 2,
            ),
            Container(
              height: 4.0,
              width: SizeConfig.screenWidth * 0.8,
              color: Colors.pink,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> selectAndPicImage() async {

    var pickedFile = PickedFile('');

    pickedFile = await imagePicker.getImage(source: ImageSource.gallery);

    setState(() {
      _imageFile = File(pickedFile.path);
    });
  }

  Future<void> uploadAndSaveImage() async {
    if (_imageFile == null) {
      showDialog(
          context: context,
          builder: (context) {
            return ErrorAlertDialog(
              message: "Please select an image",
            );
          });
    } else {
      passwordTextEditingController.text == cPasswordTextEditingController.text
          ? emailTextEditingController.text.isNotEmpty &&
                  passwordTextEditingController.text.isNotEmpty &&
                  cPasswordTextEditingController.text.isNotEmpty
              ? uploadStoreAge()
              : displayError(message: "Please fill the registration form")
          : displayError(message: "Passwords do not match");
    }
  }

  uploadStoreAge() async {
    showDialog(
        context: context,
        builder: (c) {
          return LoadingAlertDialog(
            message: "Registering, Please wait.....",
          );
        });

    String imageFileName = DateTime.now().millisecondsSinceEpoch.toString();

    StorageReference storageReference =
        FirebaseStorage.instance.ref().child(imageFileName);

    StorageUploadTask storageUploadTask = storageReference.putFile(_imageFile);

    StorageTaskSnapshot taskSnapshot = await storageUploadTask.onComplete;

    await taskSnapshot.ref.getDownloadURL().then((url) {
      userImageUrl = url;

    });
    registerUser();
  }

  displayError({String message}) {
    showDialog(
        context: context,
        builder: (c) {
          return ErrorAlertDialog(
            message: message,
          );
        });
  }

  FirebaseAuth _auth = FirebaseAuth.instance;

  registerUser() async {

    FirebaseUser fireBaseUser;

    await _auth.createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim()).then((auth){
       fireBaseUser = auth.user;
    }).catchError((error){
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (c){
          return ErrorAlertDialog(message: error.message.toString());
        }
      );
    });

    if(fireBaseUser != null) {
      saveDataToFirestore(fireBaseUser).then((value){
        Navigator.pop(context);
        Route route = MaterialPageRoute(builder: (context) => StoreHome());
        Navigator.pushReplacement(context, route);
      });
    }
  }

  Future saveDataToFirestore (FirebaseUser fUser) async{
    Firestore.instance.collection(AppConfig.collectionUser).document(fUser.uid).setData({
      AppConfig.userUID: fUser.uid,
      AppConfig.userEmail: fUser.email,
      AppConfig.userName: nameTextEditingController.text.trim(),
      AppConfig.userAvatarUrl: userImageUrl,
      AppConfig.userCartList: ["garbageValue"],
    });

    await AppConfig.sharedPreferences.setString(AppConfig.userUID, fUser.uid);
    await AppConfig.sharedPreferences.setString(AppConfig.userEmail, fUser.email);
    await AppConfig.sharedPreferences.setString(AppConfig.userName, nameTextEditingController.text.trim());
    await AppConfig.sharedPreferences.setString(AppConfig.userAvatarUrl, userImageUrl);
    await AppConfig.sharedPreferences.setStringList(AppConfig.userCartList, ["garbageValue"]);

  }
}
