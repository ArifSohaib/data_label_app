import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'home_material.dart';

class ImageDetails extends StatelessWidget {
  final url;

  ImageDetails({Key key, @required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("image: $this.url"),
      ),
      body: Center(
        child: Column(
          children: [
            Image.network(
              this.url,
              height: 300.0,
              width: 300.0,
            ),
            Expanded(
                child: SizedBox(
              height: 50.0,
              child: _buildBody(context),
            )),
            RaisedButton(
              child: Text("Return to main page"),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MyHomePage()));
              },
            ),
          ],
        ),
      ),
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
    final record = Tags.fromSnapshot(data);

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
            final fresh = Tags.fromSnapshot(freshSnapshot);

            await transaction
                .update(record.reference, {'url': FieldValue.arrayUnion( [this.url]),'count': fresh.count + 1});
          }),
        ),
      ),
    );
  }
}

class Tags {
  final String name;
  final int count;
  final DocumentReference reference;

  Tags.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['count'] != null),
        name = map['name'],
        count = map['count'];

  Tags.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

  @override
  String toString() => "Record<$name:$count>";
}
