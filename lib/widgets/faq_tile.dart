import 'package:flutter/material.dart';

class FAQTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final String content;

  const FAQTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.content,
  }) : super(key: key);

  @override
  State<FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<FAQTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1.0,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[600],
            ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.remove : Icons.add,
            color: Colors.grey[600],
          ),
          onExpansionChanged: (bool expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Text(
                widget.content,
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 