import 'package:cidade_singular/app/models/user.dart';
import 'package:cidade_singular/app/screens/login/login_page.dart';
import 'package:cidade_singular/app/screens/opening/opening_page.dart';

import 'package:cidade_singular/app/services/auth_service.dart';
import 'package:cidade_singular/app/services/user_service.dart';
import 'package:cidade_singular/app/stores/user_store.dart';
import 'package:cidade_singular/app/util/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:image_picker/image_picker.dart';

import 'package:percent_indicator/percent_indicator.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  AuthService authService = Modular.get();

  UserService userService = Modular.get();

  UserStore userStore = Modular.get();

  TextEditingController userTypeController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController userNameController = TextEditingController();

  bool editingDescription = false;
  bool editingName = false;

  bool loadingPhoto = false;
  bool loadingName = false;
  bool loadingDescription = false;

  logout() async {
    await authService.logout();
    Modular.to.popAndPushNamed(OpeningPage.routeName);
  }

  final ImagePicker picker = ImagePicker();

  void pickImage() async {
    setState(() => loadingPhoto = true);
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      User? updated =
          await userService.update(id: userStore.user?.id ?? "", photo: image);
      if (updated != null) {
        userStore.setUser(updated);
      }
    }
    setState(() => loadingPhoto = false);
  }

  void updateUserDescription() async {
    setState(() => loadingDescription = true);
    User? updated = await userService.update(
        id: userStore.user?.id ?? "", description: descriptionController.text);
    if (updated != null) {
      userStore.setUser(updated);
    }
    setState(() => editingDescription = false);
    setState(() => loadingDescription = false);
  }

  void updateUserName() async {
    setState(() => loadingName = true);
    User? updated = await userService.update(
        id: userStore.user?.id ?? "", name: userNameController.text);
    if (updated != null) {
      userStore.setUser(updated);
    }
    setState(() => editingName = false);
    setState(() => loadingName = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        actions: [
          InkWell(
            onTap: logout,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(userStore.user == null ? "Login": "Sair"),
                SizedBox(width: 5),
                Icon(userStore.user == null ? Icons.login : Icons.logout_outlined),
              ],
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Observer(builder: (context) {
          User? user = userStore.user;

          return user == null
              ? Align(
                child: Text(
                  "Faça login para ter acesso a todas as funcionalidades!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: Constants.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: double.infinity),
                    Center(
                      child: loadingPhoto
                          ? CircularProgressIndicator()
                          : Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  foregroundImage: NetworkImage(user.picture),
                                  onForegroundImageError: (_, __) {},
                                  child: Text(
                                    user.name[0],
                                    style: TextStyle(fontSize: 38),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: pickImage,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        color: Constants.primaryColor,
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    SizedBox(height: 20),
                    getWidgetNivel(user.xp),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        editingName
                            ? Expanded(
                                child: buildField(
                                    title: 'Nome',
                                    controller: userNameController
                                      ..text = user.name,
                                    readOnly: false),
                              )
                            : Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 26,
                                  color: Constants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        if (editingName)
                          loadingName
                              ? CircularProgressIndicator()
                              : IconButton(
                                  onPressed: updateUserName,
                                  icon: Icon(Icons.task_alt),
                                  color: Colors.green,
                                ),
                        if (!loadingName)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                editingName = !editingName;
                              });
                            },
                            icon: Icon(editingName ? Icons.close : Icons.edit),
                            color: editingName
                                ? Colors.red
                                : Constants.primaryColor,
                          )
                      ],
                    ),
                    SizedBox(height: 30),
                    buildField(
                        controller: TextEditingController(text: user.email),
                        title: "Email"),
                    SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          child: buildField(
                              title: "Descrição",
                              readOnly: !editingDescription,
                              controller: descriptionController
                                ..text = user.description),
                        ),
                        if (editingDescription)
                          loadingDescription
                              ? CircularProgressIndicator()
                              : IconButton(
                                  onPressed: updateUserDescription,
                                  icon: Icon(Icons.task_alt),
                                  color: Colors.green,
                                ),
                        if (!loadingDescription)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                editingDescription = !editingDescription;
                              });
                            },
                            icon: Icon(
                                editingDescription ? Icons.close : Icons.edit),
                            color: editingDescription
                                ? Colors.red
                                : Constants.primaryColor,
                          )
                      ],
                    ),
                    SizedBox(height: 20),
                    buildField(
                        title: "Usuário",
                        controller: userTypeController
                          ..text = user.type.value +
                              ((user.type == UserType.CURATOR &&
                                      user.curator_type != null)
                                  ? " de " + (user.curator_type?.value ?? "")
                                  : "")),
                  ],
                );
        }),
      ),
    );
  }

  Widget buildField(
      {required String title,
      required TextEditingController controller,
      bool readOnly = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Constants.primaryColor,
          ),
        ),
        SizedBox(height: 2),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          textAlign: TextAlign.justify,
          maxLines: null,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide:
                  readOnly ? BorderSide.none : BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.all(10),
            hintText: "",
            counterText: "",
            helperMaxLines: 0,
            filled: true,
            fillColor: Constants.grey,
          ),
        ),
      ],
    );
  }

  int calculaXpDoNivel(int value) {
    if (value < 1000) return value;

    var strValue = value.toString();
    var len = strValue.length;

    var xp = strValue.substring(len - 3);
    return int.parse(xp);
  }

  Widget getWidgetNivel(int crias) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          getUserTitle(crias),
          style: TextStyle(
            fontSize: 16,
            color: Constants.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        LinearPercentIndicator(
          lineHeight: 20.0,
          percent: crias / getRange(crias),
          progressColor: Constants.primaryColor,
          backgroundColor: Constants.grey,
          curve: Curves.linear,
        ),
        Text(
          "$crias/${getRange(crias)}",
          style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w800,
              color: Constants.primaryColor),
        ),
      ],
    );
  }

  String getUserTitle(int crias) {
    if (crias >= 5000) return 'Vice-Curador';
    if (crias >= 1001) return 'Visitante Criativo';
    if (crias >= 101) return 'Visitante Singular';
    return 'Visitante Descobridor';
  }

  int getRange(int crias) {
    if (crias >= 5000) return crias;
    if (crias >= 1001) return 5000;
    if (crias >= 101) return 1001;
    return 101;
  }
}
