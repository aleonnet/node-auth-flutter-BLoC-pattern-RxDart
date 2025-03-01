import 'package:disposebag/disposebag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc_pattern/flutter_bloc_pattern.dart';
import 'package:node_auth/pages/register/register.dart';
import 'package:node_auth/utils/delay.dart';
import 'package:node_auth/utils/snackbar.dart';
import 'package:node_auth/widgets/password_textfield.dart';

class RegisterPage extends StatefulWidget {
  static const routeName = '/register_page';

  const RegisterPage({Key key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  DisposeBag disposeBag;

  AnimationController registerButtonController;
  Animation<double> buttonSqueezeAnimation;

  FocusNode emailFocusNode;
  FocusNode passwordFocusNode;

  @override
  void initState() {
    super.initState();

    registerButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    buttonSqueezeAnimation = Tween(
      begin: 320.0,
      end: 70.0,
    ).animate(
      CurvedAnimation(
        parent: registerButtonController,
        curve: Interval(0.0, 0.250),
      ),
    );

    emailFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    disposeBag ??= () {
      final registerBloc = BlocProvider.of<RegisterBloc>(context);
      return DisposeBag([
        registerBloc.message$.listen(handleMessage),
        registerBloc.isLoading$.listen((isLoading) {
          if (isLoading) {
            registerButtonController
              ..reset()
              ..forward();
          } else {
            registerButtonController.reverse();
          }
        }),
      ]);
    }();
  }

  @override
  void dispose() {
    disposeBag.dispose();
    registerButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registerBloc = BlocProvider.of<RegisterBloc>(context);

    return Scaffold(
      key: scaffoldKey,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withAlpha(0xBF),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              color: Colors.transparent,
              width: double.infinity,
              height: kToolbarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  BackButton(color: Colors.white),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: nameTextField(registerBloc),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: emailTextField(registerBloc),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: passwordTextField(registerBloc),
                      ),
                      const SizedBox(height: 32.0),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: registerButton(registerBloc),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void handleMessage(RegisterMessage message) async {
    if (message is RegisterSuccessMessage) {
      scaffoldKey.showSnackBar('Register successfully');
      await delay(1000);
      Navigator.pop<String>(context, message.email);
    }
    if (message is RegisterErrorMessage) {
      scaffoldKey.showSnackBar(message.message);
    }
    if (message is RegisterInvalidInformationMessage) {
      scaffoldKey.showSnackBar('Invalid information');
    }
  }

  Widget emailTextField(RegisterBloc registerBloc) {
    return StreamBuilder<String>(
      stream: registerBloc.emailError$,
      builder: (context, snapshot) {
        return TextField(
          onChanged: registerBloc.emailChanged,
          autocorrect: true,
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8.0),
              child: Icon(Icons.email),
            ),
            labelText: 'Email',
            errorText: snapshot.data,
          ),
          keyboardType: TextInputType.emailAddress,
          maxLines: 1,
          style: TextStyle(fontSize: 16.0),
          focusNode: emailFocusNode,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(passwordFocusNode);
          },
          textInputAction: TextInputAction.next,
        );
      },
    );
  }

  Widget passwordTextField(RegisterBloc registerBloc) {
    return StreamBuilder<String>(
      stream: registerBloc.passwordError$,
      builder: (context, snapshot) {
        return PasswordTextField(
          errorText: snapshot.data,
          labelText: 'Password',
          onChanged: registerBloc.passwordChanged,
          focusNode: passwordFocusNode,
          onSubmitted: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          textInputAction: TextInputAction.done,
        );
      },
    );
  }

  Widget registerButton(RegisterBloc registerBloc) {
    return AnimatedBuilder(
      animation: buttonSqueezeAnimation,
      child: MaterialButton(
        onPressed: () {
          FocusScope.of(context).requestFocus(FocusNode());
          registerBloc.submitRegister();
        },
        color: Theme.of(context).backgroundColor,
        child: Text(
          'REGISTER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
        ),
        splashColor: Theme.of(context).accentColor,
      ),
      builder: (context, child) {
        final value = buttonSqueezeAnimation.value;

        return Container(
          width: value,
          height: 60.0,
          child: Material(
            elevation: 5.0,
            clipBehavior: Clip.antiAlias,
            shadowColor: Theme.of(context).accentColor,
            borderRadius: BorderRadius.circular(24.0),
            child: value > 75.0
                ? child
                : Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget nameTextField(RegisterBloc registerBloc) {
    return StreamBuilder<String>(
      stream: registerBloc.nameError$,
      builder: (context, snapshot) {
        return TextField(
          autocorrect: true,
          onChanged: registerBloc.nameChanged,
          decoration: InputDecoration(
            labelText: 'Name',
            errorText: snapshot.data,
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8.0),
              child: Icon(Icons.person),
            ),
          ),
          keyboardType: TextInputType.text,
          maxLines: 1,
          style: TextStyle(fontSize: 16.0),
          autofocus: true,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(emailFocusNode);
          },
          textInputAction: TextInputAction.next,
        );
      },
    );
  }
}
