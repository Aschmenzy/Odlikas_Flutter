import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_mobilna/services/AIAssistantService.dart';
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
  final _aiAssistantService = AIAssistantService();
  final _scrollController = ScrollController();

  final int currentIndex = 5; // Current index for the bottom navigation bar

  List<Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    //pocetna poruka
    _messages.add(
      Message(
        text:
            'Što mogu učiniti za tebe danas? Pitaj me o ocjenama, rasporedu, testovima ili profilu.',
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    );
  }

  //funkcija koja dodaje poruke u listu
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

    //skrolati na dno stranice
    _scrollToBottom();

    try {
      // Use our AI Assistant service instead of OpenAI directly
      final response = await _aiAssistantService.processQuery(userMessage);

      //objekt koji reprezentira poruku koju vraca AI
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
        text: 'Pogreška: $e',
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
      //skrolati na dno stranice
      _scrollToBottom();
    }
  }

//funkcija koja skorla na dno stranice s animacijon od 300ms
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
          _betterDiacriticsFix(message.text),
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
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.primary,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, 0, "assets/icon/home.svg", '/home'),
            _buildNavItem(context, 1, "assets/icon/work.svg", '/jobs'),
            _buildNavItem(context, 2, "assets/icon/pomodoro.png", '/pomodoro'),
            _buildNavItem(context, 3, "assets/icon/settings.png", '/settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, int index, String assetPath, String route) {
    final bool isActive = currentIndex == index;
    final bool isSvg = assetPath.toLowerCase().endsWith('.svg');

    return InkWell(
      onTap: () {
        if (!isActive) {
          Navigator.of(context).pushReplacementNamed(
            route,
            result: PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  Container(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isSvg
              ? SvgPicture.asset(
                  assetPath,
                  height: 30,
                  colorFilter: ColorFilter.mode(
                    isActive ? Colors.white : Colors.white70,
                    BlendMode.srcIn,
                  ),
                )
              : Image.asset(
                  assetPath,
                  height: 37,
                  color: isActive ? Colors.white : Colors.white70,
                ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
            ),
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

  String _betterDiacriticsFix(String text) {
    // Remove the strange character that appears after "Pronač"
    text = text.replaceAll(String.fromCharCode(0x0087), '');
    text = text.replaceAll(String.fromCharCode(0x008D), '');

    // Direct character replacements for Croatian letters
    final Map<String, String> replacements = {
      'Ä': 'č',
      'Å¡': 'š',
      'Å¾': 'ž',
      'Ä‡': 'ć',
    };

    // Apply replacements
    replacements.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    // Handle common word patterns
    final wordReplacements = {
      'PronaÄ': 'Pronađ',
      'IzraÄunaj': 'Izračunaj',
      'jednadÅ¾b': 'jednadžb',
      'konaÄno': 'konačno',
      'mnoÅ¾': 'množ',
      'mnoÅ¾enj': 'množnj',
      'Primjenjuje': 'Primjenjuje',
      'poniÅ¡tavaju': 'poništavaju',
    };

    // Apply word-level replacements
    wordReplacements.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    return text;
  }
}
