import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';
import '../providers/match_prediction_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

/// Yapay Zeka Futbol Danışmanı & Quant Asistanı (AI Chat Assistant)
class AiChatAssistantScreen extends StatefulWidget {
  const AiChatAssistantScreen({super.key});

  @override
  State<AiChatAssistantScreen> createState() => _AiChatAssistantScreenState();
}

class _AiChatAssistantScreenState extends State<AiChatAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isGenerating = false;

  final List<String> _quickSuggestions = [
    '🔥 Günün en yüksek güvenli bankosu nedir?',
    '📊 Value Bet (Değerli Bahis) nasıl tespit edilir?',
    '💰 Kelly Kriteri ile kasa yönetimi nasıl yapılır?',
    '🚩 Korner ve Kart pazarlarında nelere dikkat edilir?',
    '⚡ Kabus Rakip (Bogey Team) ne anlama geliyor?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: 'Merhaba! Ben FOTTBOL Quant & AI Taktik Danışmanınızım. ⚽🤖\n\n'
            'Poisson olasılık modelleri, Bayesian oran füzyonu, Club Elo endeksleri, '
            'kart/korner pazarları veya kasa yönetimi hakkında aklınıza takılan her şeyi bana sorabilirsiniz.',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage(String query) async {
    final text = query.trim();
    if (text.isEmpty || _isGenerating) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isGenerating = true;
    });
    _scrollToBottom();

    final provider = Provider.of<MatchPredictionProvider>(context, listen: false);
    final apiKey = provider.geminiApiKey.trim();

    String reply;
    if (apiKey.isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: ApiConstants.geminiDefaultModel,
          apiKey: apiKey,
          systemInstruction: Content.system(
            'Sen FOTTBOL uygulamasının uzman spor quant analisti ve futbol taktik danışmanısın. '
            'Kullanıcılara istatistiksel Poisson dağılımı, Dixon-Coles düzeltmesi, Club Elo derecelendirmesi, '
            'Bayesian piyasa oran füzyonu, Kelly kasa yönetimi ve futbol taktikleri konusunda profesyonel, '
            'net, samimi ve Türkçe yanıtlar verirsin. Asla kesin kazanç vaat etmezsin; her zaman matematiksel '
            'beklenen değer (EV) ve risk yönetimi ilkelerine vurgu yaparsın.',
          ),
        );

        final response = await model.generateContent([Content.text(text)]).timeout(const Duration(seconds: 15));
        reply = response.text ?? _generateLocalAssistantFallback(text);
      } catch (e) {
        reply = _generateLocalAssistantFallback(text);
      }
    } else {
      reply = _generateLocalAssistantFallback(text);
    }

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
        _isGenerating = false;
      });
      _scrollToBottom();
    }
  }

  String _generateLocalAssistantFallback(String query) {
    final q = query.toLowerCase();

    if (q.contains('value bet') || q.contains('değerli bahis')) {
      return '💎 **Değerli Bahis (Value Bet) Nedir?**\n\n'
          'Piyasadaki bahis bürolarının sunduğu oran, matematiksel modelimizin hesapladığı gerçek gerçekleşme olasılığından daha yüksek olduğunda ortaya çıkar.\n\n'
          '📐 **Formül:** `Beklenen Değer (EV) = Model Olasılığı × Oran`\n'
          '• EV > 1.05 ise en az %5 matematiksel avantaja sahipsiniz demektir.\n'
          '• Uzun vadede pozitif EV oynayanlar spor bahislerinde istatistiksel olarak karlı çıkar.';
    }

    if (q.contains('kelly') || q.contains('kasa')) {
      return '💰 **Kelly Kriteri & Kasa Yönetimi (Bankroll):**\n\n'
          'Quant finans ve profesyonel bahis dünyasının altın kuralıdır. Kasanızın tamamını riske atmak yerine her bahse matematiksel üstünlüğünüz oranında para yatırmanızı sağlar.\n\n'
          '🛡️ **Önerimiz (1/2 Kelly):**\n'
          '• Formül: `f* = (b*p - q) / b`\n'
          '• Aşırı varyanstan korunmak için bulunan oranın yarısı (Half-Kelly) uygulanır ve tek maça maksimum %3-%5 kasa payı ayrılır.';
    }

    if (q.contains('kabus') || q.contains('bogey')) {
      return '⚠️ **Kabus Rakip (Bogey Team) Etkisi:**\n\n'
          'Kağıt üzerinde veya Elo puanında çok üstün olan bir dev takımın, tarihsel olarak kendisinden zayıf bir takıma karşı sürekli puan kaybetmesi psikolojik sendromudur.\n\n'
          '🎯 Algoritmamız son karşılaşmaları tarar; eğer favori takım son 4+ maçın %60\'ından fazlasında bu rakibe takılmışsa "Kabus Rakip Alarmı" verir ve saf favori oranlarından kaçınmanızı önerir.';
    }

    if (q.contains('korner') || q.contains('kart')) {
      return '🚩 **Korner & Kart Pazarları Analizi:**\n\n'
          '• **Kornerler:** Takımların ceza sahasına dikine giriş sıklığı ve ceza sahası dışı şut sayılarıyla doğrudan korelasyondur. Ortalaması 9.8 civarıdır.\n'
          '• **Kartlar:** Takım agresifliğinden ziyade **Hakem Sertliği (Strictness)** belirleyicidir. Hakemin ortalama kart sayısı (örn: 5.0 üzeri sert hakemler) ve derbi atmosferi çarpanları kart alt/üst tahmininde birincil faktördür.';
    }

    return '⚽ **FOTTBOL AI Quant Analiz:**\n\n'
        'Sorduğunuz konuyla ilgili modelimiz; canlı oranlar, Club Elo dereceleri ve takım xG üretimlerini Bayesian süzgecinden geçirerek kararlar üretir.\n\n'
        '📌 Daha detaylı ve kişiselleştirilmiş analizler için **Ayarlar** sekmesinden ücretsiz Gemini API anahtarınızı tanımlayabilirsiniz!';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('AI QUANT DANIŞMANI'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Mesaj Akışı
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                return _buildChatBubble(m);
              },
            ),
          ),

          // Üretim Animasyonu
          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quant Motoru & Gemini AI düşünüyor...',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // Hızlı Öneri Çipleri
          Container(
            height: 40,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickSuggestions.length,
              itemBuilder: (context, i) {
                final sug = _quickSuggestions[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(sug, style: const TextStyle(fontSize: 11.5)),
                    backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    onPressed: _isGenerating ? null : () => _sendMessage(sug),
                  ),
                );
              },
            ),
          ),

          // Metin Giriş Çubuğu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Maçlar, oranlar veya strateji sor...',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: _isGenerating ? null : () => _sendMessage(_controller.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage m) {
    final isMe = m.isUser;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.primary
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: Border.all(
                  color: isMe ? Colors.transparent : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: SelectableText(
                m.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white70, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}
