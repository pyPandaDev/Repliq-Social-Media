import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder(
        future: rootBundle.loadString('assets/privacy_policy.md'),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Markdown(
              data: snapshot.data!,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                h3: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                listBullet: const TextStyle(color: Colors.white),
                strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                em: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                code: const TextStyle(
                  color: Colors.white,
                  backgroundColor: Color(0xFF1E1E1E),
                  fontFamily: 'monospace',
                ),
                blockquote: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
} 