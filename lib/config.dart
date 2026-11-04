class Config {
  // ══════════════════════════════════════════════════════════
  //  OpenAI — EK HI KEY, TEENO KAAM
  // ══════════════════════════════════════════════════════════
  static const String openAiApiKey = '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';
  static const String openAiBaseUrl =
      'https://api.openai.com/v1/chat/completions';
  static const String openAiVisionModel = 'gpt-4o-mini';

  static const int maxUploadSizeKb = 2048;
  static const int maxAiSizeKb = 200;

  static bool get hasOpenAiKey =>
      openAiApiKey.isNotEmpty && !openAiApiKey.startsWith('sk-YOUR');
}