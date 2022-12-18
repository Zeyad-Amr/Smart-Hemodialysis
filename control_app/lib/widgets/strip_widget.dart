import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Strip extends StatelessWidget {
  const Strip(
      {Key? key,
      required this.icon,
      required this.txt,
      required this.type,
      required this.isWarning})
      : super(key: key);
  final Icon? icon;
  final String? txt;
  final String? type;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      debugPrint("Hello Web");
    }
    double widths = 0;
    double heights = 0;
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      widths = MediaQuery.of(context).size.width;
      heights = MediaQuery.of(context).size.height;
    } else if (kIsWeb ||
        MediaQuery.of(context).orientation == Orientation.landscape) {
      widths = MediaQuery.of(context).size.height;
      heights = MediaQuery.of(context).size.width;
    }
    return SizedBox(
      height: widths * 0.2,
      width: widths * 0.82,
      child: Stack(
        children: [
          Positioned(
            left: widths * 0.02,
            top: widths * 0.01,
            child: Container(
              decoration: BoxDecoration(
                color: type == 'PH' ? Colors.white : Colors.grey[900],
                borderRadius: BorderRadius.circular(30),
              ),
              width: widths * 0.8,
              height: widths * 0.16,
              child: Center(
                child: Text(
                  type == 'PH' ? txt! : type!,
                  style: TextStyle(
                      fontSize: 23,
                      color: type == 'PH' ? Colors.grey[800] : Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              width: widths * 0.18,
              height: widths * 0.18,
              decoration: BoxDecoration(
                color: !isWarning ? Colors.green[600] : Colors.red,
                borderRadius: BorderRadius.circular(100),
              ),
              child: type == 'PH'
                  ? Center(
                      child: Icon(
                      !isWarning ? Icons.done_rounded : Icons.close_rounded,
                      size: 50,
                      color: Colors.white,
                    ))
                  : Center(
                      child: Text(
                      txt!,
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    )),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              child: icon,
            ),
          ),
        ],
      ),
    );
  }
}
