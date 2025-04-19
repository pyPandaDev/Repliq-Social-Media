import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class ChatHistory extends StatefulWidget {
  const ChatHistory({super.key});

  @override
  State<ChatHistory> createState() => _ChatHistoryState();
}

class _ChatHistoryState extends State<ChatHistory> {
  List<Map<String, dynamic>> _chatHistories = [];
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadChatHistories();
  }

  Future<void> _loadChatHistories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final histories = prefs.getStringList('all_chat_histories') ?? [];
      setState(() {
        _chatHistories = histories
            .map((str) => Map<String, dynamic>.from(jsonDecode(str)))
            .toList()
          ..sort((a, b) => (b['timestamp'] as String)
              .compareTo(a['timestamp'] as String));
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chat histories: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHistory(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> histories = prefs.getStringList('all_chat_histories') ?? [];
      histories.removeAt(index);
      await prefs.setStringList('all_chat_histories', histories);
      
      setState(() {
        _chatHistories.removeAt(index);
      });
    } catch (e) {
      print('Error deleting chat history: $e');
    }
  }

  Future<void> _deleteAllHistory() async {
    try {
      setState(() => _isDeleting = true);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('all_chat_histories');
      
      setState(() {
        _chatHistories.clear();
        _isDeleting = false;
      });
    } catch (e) {
      print('Error deleting all histories: $e');
      setState(() => _isDeleting = false);
    }
  }

  Future<void> _deletePrompt(int chatIndex, int messageIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> histories = prefs.getStringList('all_chat_histories') ?? [];
      
      // Get the chat and its messages
      var chat = _chatHistories[chatIndex];
      var messages = List<Map<String, dynamic>>.from(chat['messages']);
      
      // Remove the prompt and its corresponding AI response
      messages.removeAt(messageIndex); // Remove the prompt
      if (messageIndex < messages.length) {
        messages.removeAt(messageIndex); // Remove the AI response if it exists
      }
      
      if (messages.isEmpty) {
        // If no messages left, delete the entire chat
        histories.removeAt(chatIndex);
        setState(() {
          _chatHistories.removeAt(chatIndex);
        });
      } else {
        // Update the chat with remaining messages
        chat['messages'] = messages;
        histories[chatIndex] = jsonEncode(chat);
        setState(() {
          _chatHistories[chatIndex] = chat;
        });
      }
      
      await prefs.setStringList('all_chat_histories', histories);
      
      Get.snackbar(
        'Success',
        'Prompt deleted',
        backgroundColor: Colors.grey[900],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error deleting prompt: $e');
      Get.snackbar(
        'Error',
        'Failed to delete prompt',
        backgroundColor: Colors.red[900],
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (date == yesterday) {
      return 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return DateFormat('MMM d, y h:mm a').format(dateTime);
    }
  }

  String _getFirstMessage(List<dynamic> messages) {
    if (messages.isEmpty) return 'Empty chat';
    final firstUserMessage = messages.firstWhere(
      (msg) => msg['isUser'] == true && msg['type'] == 'text',
      orElse: () => {'content': 'No message'},
    );
    String content = firstUserMessage['content'] as String;
    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }

  int _getUserMessageCount(List<dynamic> messages) {
    return messages.where((msg) => msg['isUser'] == true && msg['type'] == 'text').length;
  }

  Map<String, List<Map<String, dynamic>>> _groupChatsByDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    final Map<String, List<Map<String, dynamic>>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (var chat in _chatHistories) {
      final date = DateTime.parse(chat['timestamp']).toLocal();
      final chatDate = DateTime(date.year, date.month, date.day);

      if (chatDate == today) {
        grouped['Today']!.add(chat);
      } else if (chatDate == yesterday) {
        grouped['Yesterday']!.add(chat);
      } else {
        grouped['Earlier']!.add(chat);
      }
    }

    return grouped;
  }

  Widget _buildPromptItem(String prompt, DateTime dateTime, VoidCallback onTap, 
      {required Function() onDelete}) {
    return InkWell(
      onTap: onTap,
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text('Delete Prompt',
                style: TextStyle(color: Colors.white)),
            content: Text(
                'Are you sure you want to delete this prompt?',
                style: TextStyle(color: Colors.grey[300])),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: TextStyle(color: Colors.grey[400])),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDelete();
                },
                child: Text('Delete',
                    style: TextStyle(color: Colors.red[400])),
              ),
            ],
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person_outline,
                color: Colors.blue[400], size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompt,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getTimeAgo(dateTime),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedChats = _groupChatsByDate();
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Chat History', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_chatHistories.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red[400]),
              onPressed: _isDeleting
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: Text('Delete All History',
                              style: TextStyle(color: Colors.white)),
                          content: Text(
                              'Are you sure you want to delete all chat histories?',
                              style: TextStyle(color: Colors.grey[300])),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel',
                                  style: TextStyle(color: Colors.grey[400])),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteAllHistory();
                              },
                              child: Text('Delete All',
                                  style: TextStyle(color: Colors.red[400])),
                            ),
                          ],
                        ),
                      );
                    },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _chatHistories.isEmpty
              ? Center(
                  child: Text(
                    'No chat history yet',
                    style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: groupedChats.length,
                  padding: EdgeInsets.all(16),
                  itemBuilder: (context, sectionIndex) {
                    final section = groupedChats.keys.elementAt(sectionIndex);
                    final chats = groupedChats[section]!;
                    
                    if (chats.isEmpty) return SizedBox.shrink();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            section,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ...chats.asMap().entries.map((entry) {
                          final index = _chatHistories.indexOf(entry.value);
                          final chat = entry.value;
                          final messages = List<Map<String, dynamic>>.from(chat['messages']);
                          final dateTime = DateTime.parse(chat['timestamp']).toLocal();
                          
                          return Card(
                            color: Colors.grey[900],
                            margin: EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () {
                                Get.back(result: messages);
                              },
                              onLongPress: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.grey[900],
                                    title: Text('Delete Chat',
                                        style: TextStyle(color: Colors.white)),
                                    content: Text(
                                        'Are you sure you want to delete this chat?',
                                        style: TextStyle(color: Colors.grey[300])),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancel',
                                            style: TextStyle(color: Colors.grey[400])),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteHistory(index);
                                        },
                                        child: Text('Delete',
                                            style: TextStyle(color: Colors.red[400])),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.chat_bubble_outline,
                                            color: Colors.blue[400], size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          _getTimeAgo(dateTime),
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                        ),
                                        Spacer(),
                                        Text(
                                          '${_getUserMessageCount(messages)} prompts',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      _getFirstMessage(messages),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
    );
  }
} 