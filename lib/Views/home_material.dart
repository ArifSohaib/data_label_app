import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TagsHomePage extends StatefulWidget {
  @override
  _TagsHomePageState createState() {
    return _TagsHomePageState();
  }
}

class _TagsHomePageState extends State<TagsHomePage> {
  final inputController = TextEditingController();
  Record inputRecord;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Tag Selection')),
        body: Column(children: [
          Expanded(
              child: SizedBox(
            height: 50.0,
            child: _buildBody(context),
          )),
          TextField(
            controller: inputController,
            cursorColor: Colors.green,
          ),
          MaterialButton(
            child: Text("Input new tag"),
            onPressed: (){
              if(inputController.text.isNotEmpty) {
                setState(() {
                  inputRecord = Record.fromMap(
                      {"id":inputController.text, "name": inputController.text, "count": 0});
                });
                Firestore.instance.collection('image_tags').add(
                    {"name": inputController.text, "count": 0});
                return showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      // Retrieve the text the that user has entered by using the
                      // TextEditingController.
                      content: Text(inputRecord.toString()),
                    );
                  },
                );
              }
              else{
                return showDialog(
                  context: context,
                  builder: (context){
                    return AlertDialog(
                      content: Text("Please input a name for the new tag"),
                    );
                  }
                );
              }
            },
          )
        ]
        )
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('image_tags').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildList(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);

    return Padding(
      key: ValueKey(record.name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Text(record.name),
          trailing: Text(record.count.toString()),
          onTap: () => Firestore.instance.runTransaction((transaction) async {
            final freshSnapshot = await transaction.get(record.reference);
            final fresh = Record.fromSnapshot(freshSnapshot);

            await transaction
                .update(record.reference, {'count': fresh.count + 1});
          }),
        ),
      ),
    );
  }
}

class Record {
  final String name;
  final int count;
  final DocumentReference reference;
  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['count'] != null),
        name = map['name'],
        count = map['count'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => "Record<$name:$count>";
}
