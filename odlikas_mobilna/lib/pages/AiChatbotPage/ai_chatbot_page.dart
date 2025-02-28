import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/services/openAiService.dart';
import 'package:odlikas_mobilna/constants/constants.dart';

class AiChatbotPage extends StatefulWidget {
  const AiChatbotPage({Key? key}) : super(key: key);

  @override
  State<AiChatbotPage> createState() => _AiChatbotPageState();
}

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, required this.timestamp});
}

class _AiChatbotPageState extends State<AiChatbotPage> {
  final _promptController = TextEditingController();
  final _openAIService = OpenAIService();
  final _scrollController = ScrollController();

  List<Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add initial welcome messages
    _messages.add(
      Message(
        text: 'Što možemo napraviti za tebe?',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_promptController.text.isEmpty) return;

    final userMessage = _promptController.text;
    final userMessageObj = Message(
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessageObj);
      _isLoading = true;
      _promptController.clear();
    });

    // Scroll to bottom after adding user message
    _scrollToBottom();

    try {
      final response = await _openAIService.generateText(
        prompt: userMessage,
        maxTokens: 150,
      );

      final aiMessageObj = Message(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessageObj);
      });
    } catch (e) {
      final errorMessageObj = Message(
        text: 'Error: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(errorMessageObj);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      // Scroll to bottom after receiving AI response
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.02),

            // loading indicator
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                    child: Image.asset(
                  'assets/animations/spinningCircle.gif',
                  width: size.width * 0.15,
                )),
              )
            else
              Padding(
                padding: EdgeInsets.all(8),
                child: Center(
                  child: Image.asset(
                    'assets/images/AiCircle.png',
                    width: size.width * 0.15,
                  ),
                ),
              ),

            SizedBox(height: size.height * 0.02),

            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

            // Add the text input field directly to the body instead of bottomNavigationBar
            _buildInputField(),
          ],
        ),
      ),
      // Move the nav bar to the bottom
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.grey.shade200 : AppColors.primary,
          borderRadius: BorderRadius.circular(15),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            color: message.isUser ? AppColors.secondary : AppColors.background,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Separated input field from nav bar
  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.elliptical(100, 20),
          topRight: Radius.elliptical(100, 20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 10,
          ),
        ],
      ),
      child: SizedBox(
        height: 35,
        child: TextField(
          controller: _promptController,
          style: GoogleFonts.inter(
            height: 1,
            fontSize: 14,
            color: AppColors.secondary,
          ),
          decoration: InputDecoration(
            hintText: 'Pitajte naš AI ako imate pitanja oko nečega...',
            hintStyle:
                GoogleFonts.inter(color: AppColors.tertiary, fontSize: 14),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.search,
                size: 20,
                color: AppColors.accent,
              ),
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
          onSubmitted: (_) => _sendMessage(),
        ),
      ),
    );
  }

  // Only navigation bar, separated from input field
  Widget _buildNavBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, 0, Icons.home, '/home'),
            _buildNavItem(context, 1, Icons.work, '/jobs'),
            _buildNavItem(context, 2, Icons.timer, '/pomodoro'),
            _buildNavItem(context, 3, Icons.settings, '/settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, int index, IconData icon, String route) {
    return InkWell(
      onTap: () {
        if (index != 0) {
          Navigator.popAndPushNamed(context, route);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            size: 35,
            icon,
            color: index == 0 ? Colors.white : Colors.white70,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
