import 'dart:convert';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'app_libs.dart';
import 'chatmessage.dart';
import 'threedots.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  late OpenAI? chatGPT;
  bool _isImageSearch = false;

  bool _isTyping = false;

  @override
  void initState() {
    chatGPT = OpenAI.instance.build(
      token: "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",
      baseOption: HttpSetup(receiveTimeout: 60000),
    );

    super.initState();
  }

  void uploadMessage(String text, bool isBot, bool isImage) {
    DBHelper.insert('messages', {
      'id': DateTime.now().toIso8601String(),
      'text': text,
      'isBot': isBot,
      'isImage': isImage
    });
  }

  Future<void> fetchAndSetPlaces() async {
    final dataList = await DBHelper.getData('messages');
    _messages = dataList
        .map(
          (item) => ChatMessage(
            text: item['text'],
            sender: item['isBot'] == 1 ? 'bot' : 'user',
            isImage: item['isImage'] == 1,
          ),
        )
        .toList();
    _messages = new List.from(_messages.reversed);
  }

  @override
  void dispose() {
    chatGPT?.close();
    chatGPT?.genImgClose();
    appTheme.removeListener(() {});

    super.dispose();
  }

  // Link for api - https://beta.openai.com/account/api-keys

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    ChatMessage message = ChatMessage(
      text: _controller.text,
      sender: "user",
      isImage: false,
    );

    setState(() {
      _messages.insert(0, message);
      _isTyping = true;
      uploadMessage(message.text, message.sender != "user", message.isImage);
    });

    _controller.clear();

    if (_isImageSearch) {
      final request = GenerateImage(message.text, 1, size: "256x256");

      final response = await chatGPT!.generateImage(request);
      // Vx.log(response!.data!.last!.url!);
      insertNewData(response!.data!.last!.url!, isImage: true);
    } else {
      final request = CompleteText(
          prompt: message.text, model: kTranslateModelV3, maxTokens: 3000);

      final response = await chatGPT!.onCompleteText(request: request);
      Vx.log(response!.choices[0].text);
      insertNewData(response.choices[0].text, isImage: false);
    }
  }

  void insertNewData(String response, {bool isImage = false}) {
    ChatMessage botMessage = ChatMessage(
      text: response,
      sender: "bot",
      isImage: isImage,
    );

    setState(() {
      _isTyping = false;
      _messages.insert(0, botMessage);
      uploadMessage(
          botMessage.text, botMessage.sender != "user", botMessage.isImage);
    });
  }

  Widget _buildTextComposer() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (value) => _sendMessage(),
            decoration: const InputDecoration.collapsed(
              hintText: "Question/description",
            ),
          ),
        ),
        ButtonBar(
          children: [
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                _isImageSearch = false;
                _sendMessage();
              },
            ),
            IconButton(
                onPressed: () {
                  _isImageSearch = true;
                  _sendMessage();
                },
                icon: const Icon(Icons.image))
          ],
        ),
      ],
    ).px16();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("AI ChatBot"),
          actions: [
            IconButton(
              icon: Icon(Icons.light_mode),
              onPressed: appTheme.switchingTheme,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Flexible(
                  child: FutureBuilder(
                future: fetchAndSetPlaces(),
                builder: (ctx, snapshot) =>
                    snapshot.connectionState == ConnectionState.waiting
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : ListView.builder(
                            reverse: true,
                            padding: Vx.m8,
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              return _messages[index];
                            },
                          ),
              )),
              if (_isTyping) const ThreeDots(),
              const Divider(
                height: 1.0,
              ),
              Container(
                decoration: BoxDecoration(
                    // color: context.cardColor,
                    ),
                child: _buildTextComposer(),
              )
            ],
          ),
        ));
  }
}
