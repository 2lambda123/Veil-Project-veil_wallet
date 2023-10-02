import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:veil_wallet/src/core/constants.dart';
import 'package:veil_wallet/src/core/screen.dart';
import 'package:veil_wallet/src/layouts/mobile/back_layout.dart';
import 'package:veil_wallet/src/states/static/base_static_state.dart';
import 'package:veil_wallet/src/storage/storage_item.dart';
import 'package:veil_wallet/src/storage/storage_service.dart';
import 'package:veil_wallet/src/views/about.dart';
import 'package:veil_wallet/src/views/home.dart';
import 'package:veil_wallet/src/views/import_seed.dart';
import 'package:veil_wallet/src/views/new_wallet_save_seed.dart';
import 'package:veil_wallet/src/views/setup_biometrics.dart';
import 'package:veil_wallet/src/views/welcome.dart';
import 'package:veil_light_plugin/veil_light.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  SettingsState createState() {
    return SettingsState();
  }
}

class SettingsState extends State<Settings> {
  final _formKey = GlobalKey<FormState>();

  final _nodeUrlController = TextEditingController();
  final _nodeAuthController = TextEditingController();
  final _explorerUrlController = TextEditingController();
  final _txExplorerUrlController = TextEditingController();
  bool _useMinimumUTXOs = false;
  bool _isBiometricsActive = false;

  @override
  void initState() {
    super.initState();
    // Fetch user data from API using BuildContext
    _nodeUrlController.text = BaseStaticState.nodeAddress;
    _nodeAuthController.text = BaseStaticState.nodeAuth;
    _explorerUrlController.text = BaseStaticState.explorerAddress;
    _txExplorerUrlController.text = BaseStaticState.txExplorerAddress;
    _useMinimumUTXOs = BaseStaticState.useMinimumUTXOs;

    setState(() {
      _isBiometricsActive = BaseStaticState.biometricsActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> authActions = [];

    if (BaseStaticState.prevScreen != Screen.welcome) {
      if (_isBiometricsActive) {
        authActions.add(Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: OutlinedButton.icon(
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(45),
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              var auth = LocalAuthentication();

              try {
                var didAuthenticate = await auth.authenticate(
                    localizedReason:
                        AppLocalizations.of(context)?.biometricsRemoveReason ??
                            stringNotFoundText,
                    options:
                        const AuthenticationOptions(useErrorDialogs: true));
                if (didAuthenticate) {
                  var storageService = StorageService();
                  await storageService.writeSecureData(
                      StorageItem(prefsBiometricsEnabled, false.toString()));
                  setState(() {
                    _isBiometricsActive = false;
                    BaseStaticState.biometricsActive = false;
                  });
                }
                // ignore: empty_catches
              } on PlatformException {}
            },
            icon: const Icon(Icons.fingerprint_rounded),
            label: Text(AppLocalizations.of(context)?.removeBiometricsButton ??
                stringNotFoundText),
          ),
        ));
      } else {
        authActions.add(Container(
          margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: OutlinedButton.icon(
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(45)),
            onPressed: () {
              Navigator.of(context).push(_setupBiometricsRoute());
            },
            icon: const Icon(Icons.fingerprint_rounded),
            label: Text(AppLocalizations.of(context)?.setupBiometricsButton ??
                stringNotFoundText),
          ),
        ));
      }
      authActions.add(SizedBox(
          width: double.infinity,
          child: Row(children: [
            Flexible(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(10, 0, 5, 10),
                  child: OutlinedButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(45)),
                    onPressed: () {
                      var mnemonic = Lightwallet.generateMnemonic();
                      BaseStaticState.newWalletWords = mnemonic;

                      BaseStaticState.prevScreen = Screen.settings;
                      Navigator.of(context).push(_createNewRoute());
                    },
                    icon: const Icon(Icons.new_label_rounded),
                    label: Text(
                        AppLocalizations.of(context)?.createWalletButton ??
                            stringNotFoundText,
                        overflow: TextOverflow.ellipsis),
                  ),
                )),
            Flexible(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(5, 0, 10, 10),
                  child: OutlinedButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(45)),
                    onPressed: () {
                      BaseStaticState.prevScreen = Screen.settings;
                      Navigator.of(context).push(_createImportRoute());
                    },
                    icon: const Icon(Icons.upload_rounded),
                    label: Text(
                        AppLocalizations.of(context)?.importWallet ??
                            stringNotFoundText,
                        overflow: TextOverflow.ellipsis),
                  ),
                ))
          ])));
    }

    return BackLayout(
        title: AppLocalizations.of(context)?.settingsTitle,
        back: () {
          Navigator.of(context).push(_createBackRoute());
        },
        child: Form(
            key: _formKey,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: ListView(
                  //mainAxisAlignment: MainAxisAlignment.start,
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                        Container(
                            margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            child: TextFormField(
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return null;
                                  }
                                  return value.startsWith('http://') ||
                                          value.startsWith('https://')
                                      ? null
                                      : '';
                                },
                                enableSuggestions: true,
                                autocorrect: false,
                                decoration: InputDecoration(
                                  contentPadding:
                                      const EdgeInsets.only(bottom: 0.0),
                                  border: const UnderlineInputBorder(),
                                  hintText: AppLocalizations.of(context)
                                      ?.nodeUrlInputFieldHint,
                                  label: Text(AppLocalizations.of(context)
                                          ?.nodeUrlInputField ??
                                      stringNotFoundText),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      _nodeUrlController.text =
                                          defaultNodeAddress;
                                    },
                                    icon: const Icon(Icons.restore_rounded),
                                  ),
                                ),
                                controller: _nodeUrlController)),
                        Container(
                            margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            child: TextFormField(
                                enableSuggestions: true,
                                autocorrect: false,
                                decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.only(bottom: 0.0),
                                    border: const UnderlineInputBorder(),
                                    hintText: AppLocalizations.of(context)
                                        ?.basicAuthInputFieldHint,
                                    label: Text(AppLocalizations.of(context)
                                            ?.basicAuthInputField ??
                                        stringNotFoundText)),
                                controller: _nodeAuthController)),
                        Container(
                            margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            child: TextFormField(
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null;
                                }
                                return value.startsWith('http://') ||
                                        value.startsWith('https://')
                                    ? null
                                    : '';
                              },
                              enableSuggestions: true,
                              autocorrect: false,
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.only(bottom: 0.0),
                                border: const UnderlineInputBorder(),
                                hintText: AppLocalizations.of(context)
                                    ?.explorerUrlInputFieldHint,
                                label: Text(AppLocalizations.of(context)
                                        ?.explorerUrlInputField ??
                                    stringNotFoundText),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    _explorerUrlController.text =
                                        defaultExplorerAddress;
                                  },
                                  icon: const Icon(Icons.restore_rounded),
                                ),
                              ),
                              controller: _explorerUrlController,
                            )),
                        Container(
                            margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                            child: TextFormField(
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null;
                                }
                                return value.startsWith('http://') ||
                                        value.startsWith('https://')
                                    ? null
                                    : '';
                              },
                              enableSuggestions: true,
                              autocorrect: false,
                              decoration: InputDecoration(
                                contentPadding:
                                    const EdgeInsets.only(bottom: 0.0),
                                border: const UnderlineInputBorder(),
                                hintText: AppLocalizations.of(context)
                                    ?.explorerTxInputFieldHint,
                                label: Text(AppLocalizations.of(context)
                                        ?.explorerTxInputField ??
                                    stringNotFoundText),
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    _txExplorerUrlController.text =
                                        defaultTxExplorerAddress;
                                  },
                                  icon: const Icon(Icons.restore_rounded),
                                ),
                              ),
                              controller: _txExplorerUrlController,
                            )),
                        Container(
                            margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      AppLocalizations.of(context)
                                              ?.useMinimumUTXOs ??
                                          stringNotFoundText,
                                      style: const TextStyle(fontSize: 16)),
                                  Switch(
                                      value: _useMinimumUTXOs,
                                      onChanged: (val) {
                                        setState(() {
                                          _useMinimumUTXOs = val;
                                        });
                                      }),
                                ])),
                      ] +
                      authActions +
                      [
                        Container(
                          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(45)),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                // done
                                BaseStaticState.nodeAddress =
                                    _nodeUrlController.text;
                                BaseStaticState.nodeAuth =
                                    _nodeAuthController.text;
                                BaseStaticState.explorerAddress =
                                    _explorerUrlController.text;
                                BaseStaticState.txExplorerAddress =
                                    _txExplorerUrlController.text;
                                BaseStaticState.useMinimumUTXOs =
                                    _useMinimumUTXOs;

                                var storageService = StorageService();
                                await storageService.writeSecureData(
                                    StorageItem(prefsSettingsNodeUrl,
                                        BaseStaticState.nodeAddress));
                                await storageService.writeSecureData(
                                    StorageItem(prefsSettingsNodeAuth,
                                        BaseStaticState.nodeAuth));
                                await storageService.writeSecureData(
                                    StorageItem(prefsSettingsExplorerUrl,
                                        BaseStaticState.explorerAddress));
                                await storageService.writeSecureData(
                                    StorageItem(prefsSettingsExplorerTxUrl,
                                        BaseStaticState.txExplorerAddress));
                                await storageService.writeSecureData(
                                    StorageItem(
                                        prefsSettingsUseMinimumUTXOs,
                                        BaseStaticState.useMinimumUTXOs
                                            .toString()));

                                /*WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  Navigator.of(context)
                                      .push(_createBackRoute());
                                });*/
                                WidgetsBinding.instance
                                    .scheduleFrameCallback((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)
                                              ?.settingsSaved ??
                                          stringNotFoundText),
                                    ),
                                  );
                                });
                              }
                            },
                            icon: const Icon(Icons.save_rounded),
                            label: Text(
                                AppLocalizations.of(context)?.saveButton ??
                                    stringNotFoundText,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(45)),
                            onPressed: () {
                              Navigator.of(context).push(_createAboutRoute());
                            },
                            icon: const Icon(Icons.info_rounded),
                            label: Text(
                                AppLocalizations.of(context)?.aboutButton ??
                                    stringNotFoundText,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ]),
            )));
  }
}

Route _createBackRoute() {
  return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
    if (BaseStaticState.prevScreen == Screen.home ||
        BaseStaticState.useHomeBack) {
      return const Home();
    }
    return const Welcome();
  }, transitionsBuilder: (context, animation, secondaryAnimation, child) {
    const begin = Offset(-1.0, 0.0);
    const end = Offset.zero;
    const curve = Curves.ease;

    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  });
}

Route _createNewRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) {
      return const NewWalletSaveSeed();
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

Route _createImportRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) {
      return const ImportSeed();
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

Route _createAboutRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) {
      return const About();
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

Route _setupBiometricsRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) {
      return const SetupBiometrics();
    },
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}
