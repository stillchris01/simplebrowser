import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:flutter_browser/main.dart';
import 'package:flutter_browser/models/browser_model.dart';
import 'package:flutter_browser/models/search_engine_model.dart';
import 'package:flutter_browser/models/webview_model.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
//import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';

//import '../../project_info_popup.dart';

bool setDevsettings = false;

class CrossPlatformSettings extends StatefulWidget {
  CrossPlatformSettings({Key key}) : super(key: key);

  @override
  _CrossPlatformSettingsState createState() => _CrossPlatformSettingsState();
}

class _CrossPlatformSettingsState extends State<CrossPlatformSettings> {
  TextEditingController _customHomePageController = TextEditingController();
  TextEditingController _customUserAgentController = TextEditingController();

  @override
  void dispose() {
    _customHomePageController.dispose();
    _customUserAgentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var children = _buildBaseSettings();
    if (browserModel.webViewTabs.length > 0) {
      children.addAll(_buildWebViewTabSettings());
    }

    return ListView(
      children: children,
    );
  }

  List<Widget> _buildBaseSettings() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var settings = browserModel.getSettings();

    var widgets = <Widget>[
      ListTile(
        title: const Text("General Settings"),
        enabled: false,
      ),
      new Divider(height: 20.0,),
      ListTile(
        title: const Text("Search Engine"),
        subtitle: Text(settings.searchEngine.name),
        trailing: DropdownButton<SearchEngineModel>(
          hint: Text("Search Engine"),
          onChanged: (value) {
            setState(() {
              settings.searchEngine = value;
              browserModel.updateSettings(settings);
            });
          },
          value: settings.searchEngine,
          items: SearchEngines.map((searchEngine) {
            return DropdownMenuItem(
              value: searchEngine,
              child: Text(searchEngine.name),
            );
          }).toList(),
        ),
      ),
      new Divider(height: 20.0,),
      ListTile(
        title: const Text("Home page"),
        subtitle: Text(settings.homePageEnabled
            ? (settings.customUrlHomePage.isEmpty
                ? "ON"
                : settings.customUrlHomePage)
            : "OFF"),
        onTap: () {
          _customHomePageController.text = settings.customUrlHomePage;

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                contentPadding: EdgeInsets.all(0.0),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    StatefulBuilder(
                      builder: (context, setState) {
                        return SwitchListTile(
                          title: Text(settings.homePageEnabled ? "ON" : "OFF"),
                          value: settings.homePageEnabled,
                          onChanged: (value) {
                            setState(() {
                              settings.homePageEnabled = value;
                              browserModel.updateSettings(settings);
                            });
                          },
                        );
                      },
                    ),
                    StatefulBuilder(builder: (context, setState) {
                      return ListTile(
                        enabled: settings.homePageEnabled,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                onSubmitted: (value) {
                                  setState(() {
                                    settings.customUrlHomePage = value ?? "";
                                    browserModel.updateSettings(settings);
                                    Navigator.pop(context);
                                  });
                                },
                                keyboardType: TextInputType.url,
                                decoration: InputDecoration(
                                    hintText: 'Custom URL Home Page'),
                                controller: _customHomePageController,
                              ),
                            )
                          ],
                        ),
                      );
                    })
                  ],
                ),
              );
            },
          );
        },
      ),
      new Divider(height: 20.0,),
      FutureBuilder(
        future: InAppWebViewController.getDefaultUserAgent(),
        builder: (context, snapshot) {
          var deafultUserAgent = "";
          if (snapshot.hasData) {
            deafultUserAgent = snapshot.data;
          }

          return ListTile(
            title: const Text("Default User Agent"),
            subtitle: Text(deafultUserAgent),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: deafultUserAgent));
            },
          );
        },
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "Enables debugging of web contents.",
        child: SwitchListTile(
          title: const Text("Debugging Enabled"),
          value: Platform.isAndroid ? settings.debuggingEnabled : true,
          onChanged: (value) {
            setState(() {
              settings.debuggingEnabled = value;
              browserModel.updateSettings(settings);
              if (browserModel.webViewTabs.length > 0) {
                var webViewModel = browserModel.getCurrentTab().webViewModel;
                webViewModel.options.crossPlatform.debuggingEnabled = value;
                webViewModel.webViewController
                    .setOptions(options: webViewModel.options);
                browserModel.save();
              }
            });
          },
        ),
      ),
    ];

    return widgets;
  }

  List<Widget> _buildWebViewTabSettings() {
    var browserModel = Provider.of<BrowserModel>(context, listen: true);
    var currentWebViewModel = Provider.of<WebViewModel>(context, listen: true);
    var _webViewController = currentWebViewModel.webViewController;

    var widgets = <Widget>[
      new Divider(height: 20.0,),
      ListTile(
        title: const Text("Current WebView Settings"),
        enabled: false,
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "Sets whether the WebView should enable JavaScript.",
        child: SwitchListTile(
          title: const Text("JavaScript Enabled"),
          value: currentWebViewModel.options.crossPlatform.javaScriptEnabled,
          onChanged: (value) async {
            currentWebViewModel.options.crossPlatform.javaScriptEnabled = value;
            _webViewController.setOptions(options: currentWebViewModel.options);
            currentWebViewModel.options = await _webViewController.getOptions();
            browserModel.save();
            setState(() {});
          },
        ),
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "Enables or disables caching.",
        child: SwitchListTile(
          title: const Text("Cache Enabled"),
          value: currentWebViewModel.options.crossPlatform.cacheEnabled,
          onChanged: (value) async {
            currentWebViewModel.options.crossPlatform.cacheEnabled = value;
            _webViewController.setOptions(options: currentWebViewModel.options);
            currentWebViewModel.options = await _webViewController.getOptions();
            browserModel.save();
            setState(() {});
          },
        ),
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "Select a Custom User Agent.\nDon't mess around if you don't\nknow what this does.",
        child: StatefulBuilder(
          builder: (context, setState) {
            return ListTile(
              title: const Text("Custom User Agent"),
              onTap: () {
                _customUserAgentController.text =
                    currentWebViewModel.options.crossPlatform.userAgent;

                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      contentPadding: EdgeInsets.all(0.0),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                Expanded(
                                  child: TextField(
                                    onSubmitted: (value) async {
                                      currentWebViewModel.options.crossPlatform
                                          .userAgent = value ?? "";
                                      _webViewController.setOptions(
                                          options: currentWebViewModel.options);
                                      currentWebViewModel.options =
                                          await _webViewController.getOptions();
                                      browserModel.save();
                                      setState(() {
                                        Navigator.pop(context);
                                      });
                                    },
                                    decoration: InputDecoration(
                                        hintText: 'Custom User Agent'),
                                    controller: _customUserAgentController,
                                    keyboardType: TextInputType.multiline,
                                    textInputAction: TextInputAction.go,
                                    maxLines: null,
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "Enables or disables on-screen zoom.",
        child: SwitchListTile(
          title: const Text("Support Zoom"),
          value: currentWebViewModel.options.crossPlatform.supportZoom,
          onChanged: (value) async {
            currentWebViewModel.options.crossPlatform.supportZoom = value;
            _webViewController.setOptions(options: currentWebViewModel.options);
            currentWebViewModel.options = await _webViewController.getOptions();
            browserModel.save();
            setState(() {});
          },
        ),
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "Sets whether the WebView should\nprevent HTML5 audio or video\nfrom autoplaying.",
        child: SwitchListTile(
          title: const Text("Media Playback Requires User Gesture"),
          value: currentWebViewModel
              .options.crossPlatform.mediaPlaybackRequiresUserGesture,
          onChanged: (value) async {
            currentWebViewModel
                .options.crossPlatform.mediaPlaybackRequiresUserGesture = value;
            _webViewController.setOptions(options: currentWebViewModel.options);
            currentWebViewModel.options = await _webViewController.getOptions();
            browserModel.save();
            setState(() {});
          },
        ),
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "Shows or hides the vertical scrollbar.",
        child: SwitchListTile(
          title: const Text("Vertical ScrollBar Enabled"),
          value:
              currentWebViewModel.options.crossPlatform.verticalScrollBarEnabled,
          onChanged: (value) async {
            currentWebViewModel.options.crossPlatform.verticalScrollBarEnabled =
                value;
            _webViewController.setOptions(options: currentWebViewModel.options);
            currentWebViewModel.options = await _webViewController.getOptions();
            browserModel.save();
            setState(() {});
          },
        ),
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "Shows or hides the horizontal scrollbar.",
        child: SwitchListTile(
          title: const Text("Horizontal ScrollBar Enabled"),
          value: currentWebViewModel
              .options.crossPlatform.horizontalScrollBarEnabled,
          onChanged: (value) async {
            currentWebViewModel.options.crossPlatform.horizontalScrollBarEnabled =
                value;
            _webViewController.setOptions(options: currentWebViewModel.options);
            currentWebViewModel.options = await _webViewController.getOptions();
            browserModel.save();
            setState(() {});
          },
        ),
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "Disables vertical scrolling.",
        child: SwitchListTile(
          title: const Text("Disable Vertical Scroll"),
          value: currentWebViewModel.options.crossPlatform.disableVerticalScroll,
          onChanged: (value) async {
            currentWebViewModel.options.crossPlatform.disableVerticalScroll =
                value;
            _webViewController.setOptions(options: currentWebViewModel.options);
            currentWebViewModel.options = await _webViewController.getOptions();
            browserModel.save();
            setState(() {});
          },
        ),
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "Disables horizontal scrolling.",
        child: SwitchListTile(
          title: const Text("Disable Horizontal Scroll"),
          value:
              currentWebViewModel.options.crossPlatform.disableHorizontalScroll,
          onChanged: (value) async {
            currentWebViewModel.options.crossPlatform.disableHorizontalScroll =
                value;
            _webViewController.setOptions(options: currentWebViewModel.options);
            currentWebViewModel.options = await _webViewController.getOptions();
            browserModel.save();
            setState(() {});
          },
        ),
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "Disables the context menu.",
        child: SwitchListTile(
          title: const Text("Disable Context Menu"),
          value: currentWebViewModel.options.crossPlatform.disableContextMenu,
          onChanged: (value) async {
            currentWebViewModel.options.crossPlatform.disableContextMenu = value;
            _webViewController.setOptions(options: currentWebViewModel.options);
            currentWebViewModel.options = await _webViewController.getOptions();
            browserModel.save();
            setState(() {});
          },
        ),
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "Sets the minimum font size.\nDefault is 8.",
        child: ListTile(
          title: const Text("Minimum Font Size"),
          trailing: Container(
            width: 50.0,
            child: TextFormField(
              initialValue: currentWebViewModel
                  .options.crossPlatform.minimumFontSize
                  .toString(),
              keyboardType: TextInputType.numberWithOptions(),
              onFieldSubmitted: (value) async {
                currentWebViewModel.options.crossPlatform.minimumFontSize =
                    int.parse(value);
                _webViewController.setOptions(
                    options: currentWebViewModel.options);
                currentWebViewModel.options =
                    await _webViewController.getOptions();
                browserModel.save();
                setState(() {});
              },
            ),
          ),
        ),
      ),
      new Divider(height: 20.0,),
      Tooltip(
        message: "",
        child: ListTile(
          title: const Text("About"),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: "Simple Browser",
              applicationVersion: "0.1 ALPHA",
              applicationLegalese: "Licensed under the Apache LICENSE 2.0. Core of this app is the flutter_browser by Lorenzo Pichilli.",
            );
          },
        ),
      ),
    ];

    return widgets;
  }
}
