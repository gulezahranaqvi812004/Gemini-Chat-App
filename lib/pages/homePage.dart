import 'dart:io';
import 'dart:typed_data';

import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;

  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Gemini",
    profileImage:
    "https://seeklogo.com/images/G/google-gemini-logo-A5787B2669-seeklogo.com.png",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Gemini Chat"),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(
        trailing: [
          IconButton(
            onPressed: _sendMediaMessage,
            icon: const Icon(Icons.image),
          ),
        ],
      ),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    try {
      String question = chatMessage.text;
      List<Uint8List>? images;

      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [await File(chatMessage.medias!.first.url).readAsBytes()];
      }

      // Ensure that the `streamGenerateContent` method and endpoint are correct.
      gemini.streamGenerateContent(
        question,
        images: images,
      ).listen(
            (event) {
          String response = event.content?.parts
              ?.fold("", (previous, current) => "$previous ${current.text}") ??
              "";

          if (response.isNotEmpty) {
            ChatMessage message = ChatMessage(
              user: geminiUser,
              createdAt: DateTime.now(),
              text: response,
            );

            setState(() {
              messages = [message, ...messages];
            });
          }
        },
        onError: (error) {
          print("An error occurred: $error");
          // Handle the error (e.g., display a message to the user)
        },
      );
    } catch (e) {
      print("An unexpected error occurred: $e");
      // Handle unexpected errors
    }
  }

  Future<void> _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      // Describe the picture directly in the message text
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Please describe this picture.",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: file.name,
            type: MediaType.image,
          ),
        ],
      );

      // Send the message with the image for description
      _sendMessage(chatMessage);
    }
  }
}
