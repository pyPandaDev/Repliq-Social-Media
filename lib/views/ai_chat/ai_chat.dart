import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:repliq/services/gemini_service.dart'; //
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:repliq/views/ai_chat/chat_history.dart';
import '../../widgets/voice_button.dart';

class AIChat extends StatefulWidget { //
  const AIChat({super.key}); //

  @override
  State<AIChat> createState() => _AIChatState(); //
}

class _AIChatState extends State<AIChat> with SingleTickerProviderStateMixin { //
  final TextEditingController _messageController = TextEditingController(); //
  final ScrollController _scrollController = ScrollController(); //
  final List<Map<String, dynamic>> _messages = []; //
  final GeminiService _geminiService = GeminiService(); //
  File? _selectedImage; //
  bool _isLoading = false; //
  bool _includeWebSearch = false; //
  bool _unrestrictedMode = false; //
  late AnimationController _loadingController; //
  String _currentlyGeneratingText = ''; //
  Timer? _typingTimer; //

  @override
  void initState() { //
    super.initState(); //
    _loadingController = AnimationController( //
      vsync: this, //
      duration: const Duration(seconds: 2), //
    )..repeat(); //
    _loadLastChat(); //
  }

  @override
  void dispose() { //
    _loadingController.dispose(); //
    _messageController.dispose(); //
    _scrollController.dispose(); //
    _typingTimer?.cancel(); //
    super.dispose(); //
  }

  Future<void> _loadLastChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatStr = prefs.getString('chat_history');
      if (chatStr != null) {
        final messages = List<Map<String, dynamic>>.from(
          jsonDecode(chatStr).map((x) => Map<String, dynamic>.from(x))
        );
        setState(() {
          _messages.addAll(messages);
        });
        // Scroll to bottom after loading messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      print('Error loading last chat: $e');
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save current chat
      await prefs.setString('chat_history', jsonEncode(_messages));
      
      // Save to all histories
      List<String> allHistories = prefs.getStringList('all_chat_histories') ?? [];
      
      // Create history entry
      final historyEntry = {
        'timestamp': DateTime.now().toIso8601String(),
        'messages': _messages,
        'isActive': true, // Add flag to identify active chat
      };
      
      // Check if we already have an active chat
      bool hasActiveChat = false;
      for (int i = 0; i < allHistories.length; i++) {
        final history = jsonDecode(allHistories[i]);
        if (history['isActive'] == true) {
          // Update existing active chat
          allHistories[i] = jsonEncode(historyEntry);
          hasActiveChat = true;
          break;
        }
      }
      
      if (!hasActiveChat) {
        // If no active chat exists, add as new chat
        allHistories.add(jsonEncode(historyEntry));
      }
      
      await prefs.setStringList('all_chat_histories', allHistories);
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  bool _areMessagesEqual(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i]['content'] != b[i]['content'] || 
          a[i]['isUser'] != b[i]['isUser'] ||
          a[i]['type'] != b[i]['type']) {
        return false;
      }
    }
    return true;
  }

  Future<void> _startNewChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> allHistories = prefs.getStringList('all_chat_histories') ?? [];
      
      // Mark all existing chats as inactive
      for (int i = 0; i < allHistories.length; i++) {
        final history = jsonDecode(allHistories[i]);
        history['isActive'] = false;
        allHistories[i] = jsonEncode(history);
      }
      
      await prefs.setStringList('all_chat_histories', allHistories);
      
      // Clear current chat
      setState(() {
        _messages.clear();
      });
      
      // Clear current chat from preferences
      await prefs.remove('chat_history');
    } catch (e) {
      print('Error starting new chat: $e');
    }
  }

  Future<void> _openChatHistory() async {
    final result = await Get.to(() => ChatHistory());
    if (result != null) {
      setState(() {
        _messages.clear();
        _messages.addAll(List<Map<String, dynamic>>.from(result));
      });
      _scrollToBottom();
    }
  }

  Widget _buildLoadingIndicator() { //
    return Padding( //
      padding: EdgeInsets.only(left: 16, right: 64, bottom: 24), //
      child: Column( //
        crossAxisAlignment: CrossAxisAlignment.start, //
        children: [ //
          Row( //
            children: [ //
              RotationTransition( //
                turns: _loadingController, //
                child: Image.asset( //
                  'assets/images/chat.png', //
                  width: 20, //
                  height: 20, //
                  color: Colors.grey[400], //
                ), //
              ), //
              SizedBox(width: 8), //
              Text( //
                '', // Removed 'RepliqAi' text
                style: TextStyle( //
                  color: Colors.grey[400], //
                  fontSize: 14, //
                ), //
              ), //
            ], //
          ), //
          SizedBox(height: 8), //
          Row( //
            children: [ //
              Text( //
                _currentlyGeneratingText, //
                style: TextStyle( //
                  color: Colors.white, //
                  fontSize: 16, //
                ), //
              ), //
              Text( //
                '▋', //
                style: TextStyle( //
                  color: Colors.white, //
                  fontSize: 16, //
                ), //
              ), //
            ], //
          ), //
        ], //
      ), //
    ); //
  }

  Widget _buildCodeBlock(String code, String language) { //
    return Container( //
      width: double.infinity, //
      margin: EdgeInsets.symmetric(vertical: 8), //
      decoration: BoxDecoration( //
        color: Colors.grey[900], //
        borderRadius: BorderRadius.circular(8), //
      ), //
      child: Column( //
        crossAxisAlignment: CrossAxisAlignment.start, //
        children: [ //
          Container( //
            width: double.infinity, //
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), //
            decoration: BoxDecoration( //
              color: Colors.grey[800], //
              borderRadius: BorderRadius.only( //
                topLeft: Radius.circular(8), //
                topRight: Radius.circular(8), //
              ), //
            ), //
            child: Row( //
              children: [ //
                Text( //
                  language, //
                  style: TextStyle( //
                    color: Colors.grey[400], //
                    fontSize: 14, //
                  ), //
                ), //
                Spacer(), //
                IconButton( //
                  icon: Icon(Icons.copy_outlined, size: 18, color: Colors.grey[400]), //
                  onPressed: () => _copyToClipboard(code), //
                  padding: EdgeInsets.zero, //
                  constraints: BoxConstraints( //
                    minWidth: 32, //
                    minHeight: 32, //
                  ), //
                ), //
              ], //
            ), //
          ), //
          SingleChildScrollView( //
            scrollDirection: Axis.horizontal, //
            child: Container( //
              padding: EdgeInsets.all(16), //
              child: HighlightView( //
                code, //
                language: language, //
                theme: monokaiSublimeTheme, //
                textStyle: TextStyle( //
                  fontFamily: 'monospace', //
                  fontSize: 14, //
                  height: 1.5, //
                ), //
              ), //
            ), //
          ), //
        ], //
      ), //
    ); //
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    final type = message['type'] as String;
    final content = message['content'] as String;
    final messageId = message['id'] as String;

    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Padding(
              padding: EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/chat.png',
                    width: 20,
                    height: 20,
                    color: Colors.grey[400],
                  ),
                  SizedBox(width: 8),
                  Text(
                    'RepliqAi',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (type == 'image')
                  Container(
                    margin: EdgeInsets.only(right: isUser ? 0 : 48, left: isUser ? 48 : 0),
                    constraints: BoxConstraints(maxWidth: 200),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(content),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else if (type == 'generated_image')
                  Container(
                    margin: EdgeInsets.only(right: isUser ? 0 : 48, left: isUser ? 48 : 0),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[900]?.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blueGrey[700]!)
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "🖼️ Generated Image:",
                          style: TextStyle(color: Colors.blue[300], fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        MarkdownBody(
                          data: content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                          ),
                          selectable: true,
                        ),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: IconButton(
                              icon: Icon(Icons.copy_outlined, size: 16, color: Colors.grey[400]),
                              onPressed: () => _copyToClipboard(content),
                              padding: EdgeInsets.zero,
                              tooltip: 'Copy description',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isUser)
                  Container(
                    margin: EdgeInsets.only(left: 48),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      content,
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (content.contains('```'))
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(right: 24),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    child: _parseAndBuildCodeBlocks(content),
                  )
                else
                  Container(
                    margin: EdgeInsets.only(right: 48),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data: content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                            h1: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            h2: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            h3: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            listBullet: TextStyle(color: Colors.white),
                            strong: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            em: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                            code: TextStyle(
                              color: Colors.white,
                              backgroundColor: Colors.grey[800],
                              fontFamily: 'monospace',
                            ),
                            blockquote: TextStyle(color: Colors.grey[300], fontSize: 16),
                          ),
                          selectable: true,
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: VoiceButton(
                                text: content,
                                messageId: messageId,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              height: 32,
                              width: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.copy_outlined, size: 16, color: Colors.grey[400]),
                                onPressed: () => _copyToClipboard(content),
                                padding: EdgeInsets.zero,
                                tooltip: 'Copy response',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _parseAndBuildCodeBlocks(String content) { //
    final List<Widget> widgets = []; //
    final RegExp codeBlockRegex = RegExp(r'```(\w+)?\n([\s\S]*?)\n```'); //
    int lastMatchEnd = 0; //

    for (final match in codeBlockRegex.allMatches(content)) { //
      // Add text before code block //
      if (match.start > lastMatchEnd) { //
        final textBefore = content.substring(lastMatchEnd, match.start); //
        if (textBefore.trim().isNotEmpty) { //
          widgets.add(MarkdownBody( //
            data: textBefore, //
            styleSheet: MarkdownStyleSheet( //
              p: TextStyle(color: Colors.white, fontSize: 16, height: 1.5), //
            ), //
          )); //
        }
      }

      // Add code block //
      final language = match.group(1) ?? 'text'; //
      final code = match.group(2) ?? ''; //
      widgets.add(_buildCodeBlock(code.trim(), language)); //

      lastMatchEnd = match.end; //
    }

    // Add remaining text after last code block //
    if (lastMatchEnd < content.length) { //
      final textAfter = content.substring(lastMatchEnd); //
      if (textAfter.trim().isNotEmpty) { //
        widgets.add(MarkdownBody( //
          data: textAfter, //
          styleSheet: MarkdownStyleSheet( //
            p: TextStyle(color: Colors.white, fontSize: 16, height: 1.5), //
          ), //
        )); //
      }
    }

    return Column( //
      crossAxisAlignment: CrossAxisAlignment.start, //
      children: widgets, //
    ); //
  }

  Future<void> _pickImage() async { //
    final ImagePicker picker = ImagePicker(); //
    final XFile? image = await picker.pickImage(source: ImageSource.gallery); //

    if (image != null) { //
      setState(() { //
        _selectedImage = File(image.path); //
      }); //
    }
  }

  void _clearImage() { //
    setState(() { //
      _selectedImage = null; //
    }); //
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty && _selectedImage == null) return;

    setState(() {
      // Add image first if exists
      if (_selectedImage != null) {
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': _selectedImage!.path,
          'isUser': true,
          'type': 'image',
        });
      }
      // Then add text message if exists
      if (message.isNotEmpty) {
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': message,
          'isUser': true,
          'type': 'text',
        });
      }
      _isLoading = true;
      _startTypingAnimation('Thinking');
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      String response;
      if (_selectedImage != null) {
        response = await _geminiService.analyzeImage(message, _selectedImage!);
      } else {
        response = await _geminiService.generateTextResponse(
          message,
          includeWebSearch: _includeWebSearch,
          unrestrictedMode: _unrestrictedMode,
          removeAllBoundaries: _unrestrictedMode,
          allowOffensiveContent: _unrestrictedMode,
          allowExplicitContent: _unrestrictedMode,
        );
      }

      setState(() {
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': response,
          'isUser': false,
          'type': 'text',
        });
        _isLoading = false;
        _selectedImage = null;
        _stopTypingAnimation();
      });

      _scrollToBottom();
      _saveChatHistory();
    } catch (e) {
      setState(() {
        _messages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': 'Sorry, something went wrong. Please try again.',
          'isUser': false,
          'type': 'text',
        });
        _isLoading = false;
        _selectedImage = null;
        _stopTypingAnimation();
      });
      print('Error: $e');
    }
  }

  void _startTypingAnimation(String initialText) { //
    setState(() { //
      _currentlyGeneratingText = initialText; //
    }); //

    _typingTimer?.cancel(); //
    _typingTimer = Timer.periodic(Duration(milliseconds: 500), (timer) { //
      setState(() { //
        if (_currentlyGeneratingText.endsWith('...')) { //
          _currentlyGeneratingText = _currentlyGeneratingText.substring(0, _currentlyGeneratingText.length - 3); //
        } else { //
          _currentlyGeneratingText = '$_currentlyGeneratingText.'; //
        }
      }); //
    }); //
  }

  void _stopTypingAnimation() { //
    _typingTimer?.cancel(); //
    _typingTimer = null; //
  }

  Future<void> _copyToClipboard(String text) async { //
    await Clipboard.setData(ClipboardData(text: text)); //
    Get.snackbar( //
      'Copied', //
      'Text copied to clipboard', //
      backgroundColor: Colors.grey[900], //
      colorText: Colors.white, //
      snackPosition: SnackPosition.BOTTOM, //
      margin: EdgeInsets.all(8), //
      duration: Duration(seconds: 2), //
    ); //
  }

  void _scrollToBottom() { //
    if (_scrollController.hasClients) { //
      _scrollController.animateTo( //
        _scrollController.position.maxScrollExtent, //
        duration: const Duration(milliseconds: 300), //
        curve: Curves.easeOut, //
      ); //
    }
  }

  Widget _buildRecommendations() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'What can I help with?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 40),
            Container(
              constraints: BoxConstraints(maxWidth: 500),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 2.2,
                children: [
                  _buildRecommendationButton(
                    icon: Icons.code_rounded,
                    label: 'Code',
                    color: Colors.blue[400]!,
                    onTap: () {
                      _messageController.text = 'Help me with coding ';
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _messageController.text.length),
                      );
                    },
                  ),
                  _buildRecommendationButton(
                    icon: Icons.edit_note_rounded,
                    label: 'Help me write',
                    color: Colors.green[400]!,
                    onTap: () {
                      _messageController.text = 'Help me write ';
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _messageController.text.length),
                      );
                    },
                  ),
                  _buildRecommendationButton(
                    icon: Icons.summarize_rounded,
                    label: 'Summarize text',
                    color: Colors.orange[400]!,
                    onTap: () {
                      _messageController.text = 'Summarize this text: ';
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _messageController.text.length),
                      );
                    },
                  ),
                  _buildRecommendationButton(
                    icon: Icons.image_search_rounded,
                    label: 'Analyze images',
                    color: Colors.purple[400]!,
                    onTap: () => _pickImage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/chat.png',
              width: 24,
              height: 24,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              'RepliqAi',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.public,
              color: _includeWebSearch ? Colors.white : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _includeWebSearch = !_includeWebSearch;
              });
            },
            tooltip: 'Toggle web search',
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(100, 0, 0, 0),
                items: [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.add, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('New Chat', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    onTap: _startNewChat,
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(Icons.history, color: Colors.white70),
                        SizedBox(width: 8),
                        Text('Chat History', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    onTap: () => Future(() => _openChatHistory()),
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_open,
                          color: _unrestrictedMode ? Colors.red : Colors.white70,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Unrestricted Mode',
                          style: TextStyle(
                            color: _unrestrictedMode ? Colors.red : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _unrestrictedMode = !_unrestrictedMode;
                      });
                    },
                  ),
                ],
                elevation: 8,
                color: Colors.grey[900],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildRecommendations()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildLoadingIndicator();
                      }
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedImage != null)
                            Container(
                              width: 32,
                              height: 32,
                              margin: EdgeInsets.only(left: 12, top: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey[800]!),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: -6,
                                    top: -6,
                                    child: IconButton(
                                      icon: Container(
                                        padding: EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.close, color: Colors.white, size: 12),
                                      ),
                                      onPressed: _clearImage,
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            IconButton(
                              icon: Icon(
                                Icons.add_photo_alternate_outlined,
                                color: Colors.white70,
                                size: 24,
                              ),
                              onPressed: _pickImage,
                              tooltip: 'Add image',
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(color: Colors.white),
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: _includeWebSearch
                                  ? 'Web Search...'
                                  : 'Ask Anything...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8, right: 8),
                        child: IconButton(
                          icon: Icon(
                            Icons.send,
                            color: Colors.white70,
                            size: 24,
                          ),
                          onPressed: () => _sendMessage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}