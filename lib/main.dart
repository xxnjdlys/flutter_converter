import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import "package:hex/hex.dart";

import 'package:share/share.dart';

void main() => runApp(new MyApp());

const String HINT_TEXT = "result will be showed here";

const List<String> _defaultMaterials = const <String>[
  "HEX",
  'BINARY',
  'BASE64',
  'UNICODE',
];

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: "Converter"),
      // home: new MyHomePage(title: 'Converter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.name}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final String name;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  String _selectedMaterial = 'HEX';
  final Set<String> _materials = new Set<String>();
  final _textController = TextEditingController();
  bool _deleteIconVisible = false;
  String _resultString = HINT_TEXT;

  void _reset() {
    _materials.clear();
    _materials.addAll(_defaultMaterials);
  }

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> choiceChips = _materials.map<Widget>((String name) {
      return new ChoiceChip(
        key: new ValueKey<String>(name),
        backgroundColor: Colors.black26,
        selectedColor: Colors.greenAccent,
        label: new Text(
          name,
          style: new TextStyle(
              fontSize: 12.0,
              color: _selectedMaterial == name ? Colors.black87 : Colors.white),
        ),
        selected: _selectedMaterial == name,
        onSelected: (bool value) {
          setState(() {
            _selectedMaterial = value ? name : 'HEX';
          });
        },
      );
    }).toList();
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        actions: <Widget>[
          new IconButton(
            onPressed: _onMenuPressed,
            icon: new Icon(Icons.share),
          ),
        ],
        title: new Text(widget.title),
      ),
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: new Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug paint" (press "p" in the console where you ran
          // "flutter run", or select "Toggle Debug Paint" from the Flutter tool
          // window in IntelliJ) to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          // mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Padding(
              child: new TextField(
                onSubmitted: (value) {
                  setState(() {
                    SystemChannels.textInput.invokeMethod('TextInput.hide');
                    _resultString = convertTo(_textController.text);
                  });
                },
                onChanged: (value) {
                  setState(() {
                    if (value.length > 0) {
                      _deleteIconVisible = true;
                    } else {
                      _deleteIconVisible = false;
                    }
                  });
                  print("Input Text Is: $value");
                },
                controller: _textController,
                keyboardType: TextInputType.text,
                decoration: new InputDecoration(
                  border: new OutlineInputBorder(),
                  labelText: 'Converter',
                  hintText: 'input text here',
                  suffixIcon: new GestureDetector(
                    child: _deleteIconVisible
                        ? new Icon(Icons.delete)
                        : new SizedBox(
                            height: 24.0,
                            width: 24.0,
                          ),
                    onTap: () {
                      setState(() {
                        _updateStatus();
                      });
                    },
                  ),
                  // suffixIcon:
                  // prefixText: '\$',
                ),
                autofocus: true,
                maxLines: 1,
              ),
              padding: EdgeInsets.all(4.0),
            ),
            new Container(
              width: double.infinity,
              height: 100.0,
              child: new Card(
                  child: new Padding(
                padding: EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  top: 4.0,
                  bottom: 4.0,
                ),
                child: new Text(
                  _resultString,
                  style: new TextStyle(
                    color: Colors.black54,
                    fontSize: 12.0,
                  ),
                ),
              )),
            ),
            new _ChipsTile(
              label: 'Please choose an option:',
              children: choiceChips,
            ),
            const SizedBox(height: 8.0),
            new Center(
              child: new RaisedButton(
                child: const Text('CONVERT'),
                onPressed: _handleSubmitted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // "HEX",
  // 'BINARY',
  // 'BASE64',
  // 'UNICODE',
  convertTo(String text) {
    List<int> bytes = UTF8.encode(text);
    String result = "";
    if ("HEX" == _selectedMaterial) {
      result = HEX.encode(bytes);
    } else if ("BINARY" == _selectedMaterial) {
    } else if ("BASE64" == _selectedMaterial) {
    } else if ("UNICODE" == _selectedMaterial) {}
    return result;
  }

  void _handleSubmitted() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    setState(() {
      _resultString = convertTo(_textController.text);
    });
  }

  void showInSnackBar(String value) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(value)));
  }

  void _updateStatus() {
    _deleteIconVisible = false;
    _resultString = HINT_TEXT;
    _textController.text = "";
  }

  void _onMenuPressed() {
    final RenderBox box = context.findRenderObject();
    Share.share(
      _resultString,
      sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
    );
  }
}

class _ChipsTile extends StatelessWidget {
  const _ChipsTile({
    Key key,
    this.label,
    this.children,
  }) : super(key: key);

  final String label;
  final List<Widget> children;

  // Wraps a list of chips into a ListTile for display as a section in the demo.
  @override
  Widget build(BuildContext context) {
    return new ListTile(
      title: new Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
        child: new Text(label, textAlign: TextAlign.start),
      ),
      subtitle: children.isEmpty
          ? new Center(
              child: new Padding(
                padding: const EdgeInsets.all(8.0),
                child: new Text(
                  'None',
                  style: Theme
                      .of(context)
                      .textTheme
                      .caption
                      .copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            )
          : new Wrap(
              children: children
                  .map((Widget chip) => new Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: chip,
                      ))
                  .toList(),
            ),
    );
  }
}
