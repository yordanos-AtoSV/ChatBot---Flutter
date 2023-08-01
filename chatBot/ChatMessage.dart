import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:flutter/services.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage(
      {super.key,
      required this.text,
      required this.sender,
      this.isImage = false});

  final String text;
  final String sender;
  final bool isImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: (sender == "user"
          ? Theme.of(context).canvasColor
          : Theme.of(context).primaryColor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sender)
              .text
              .subtitle1(context)
              .make()
              .box
              .color(sender == "user" ? Vx.red200 : Vx.green200)
              .p16
              .rounded
              .alignCenter
              .makeCentered(),
          Expanded(
            child: isImage
                ? AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      text,
                      loadingBuilder: (context, child, loadingProgress) =>
                          loadingProgress == null
                              ? child
                              : const CircularProgressIndicator.adaptive(),
                    ),
                  )
                : text.trim().text.bodyText1(context).make().px8(),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: Icon(
                isImage ? Icons.download : Icons.copy,
              ),
              onPressed: () async {
                if (isImage) {
                  bool? status = false;
                  status = await GallerySaver.saveImage(text,
                      albumName: 'Downloads');
                  if (status!) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      duration: Duration(milliseconds: 1500),
                      content: Text('image downloaded.'),
                    ));
                  }
                } else {
                  await Clipboard.setData(ClipboardData(text: text)).then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        duration: Duration(milliseconds: 1500),
                        content: Text('copied to clip board.'),
                      ), 
                    );
                  });
                }
              },
            ),
          )
        ],
      ).py8(),
    );
  }
}
