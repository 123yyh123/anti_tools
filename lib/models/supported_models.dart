/// 支持的模型列表
/// 统一管理所有模型名称，避免魔法字符串散落各处
class SupportedModels {
  SupportedModels._();

  // ==================== Gemini 系列 ====================
  static const String gemini3ProHigh = 'gemini-3-pro-high';
  static const String gemini3ProLow = 'gemini-3-pro-low';
  static const String gemini3ProImage = 'gemini-3-pro-image';
  static const String gemini3Flash = 'gemini-3-flash';
  static const String gemini25Pro = 'gemini-2.5-pro';
  static const String gemini25Flash = 'gemini-2.5-flash';
  static const String gemini25FlashThinking = 'gemini-2.5-flash-thinking';
  static const String gemini25FlashLite = 'gemini-2.5-flash-lite';
  static const String gemini20FlashExp = 'gemini-2.0-flash-exp';
  static const String gemini20FlashThinkingExp = 'gemini-2.0-flash-thinking-exp-1219';

  // ==================== Claude 系列 ====================
  static const String claudeSonnet45 = 'claude-sonnet-4-5';
  static const String claudeSonnet45Thinking = 'claude-sonnet-4-5-thinking';
  static const String claudeOpus45Thinking = 'claude-opus-4-5-thinking';

  /// 默认激活模型（经过测试最稳定）
  static const String defaultActivationModel = gemini3ProHigh;

  /// 激活任务使用的模型列表（按优先级排序）
  static const List<String> activationModels = [
    gemini3ProHigh,
    claudeSonnet45,
    gemini3Flash,
  ];

  /// UI 模型选择器可选列表
  static const List<String> availableModels = [
    claudeSonnet45,
    claudeSonnet45Thinking,
    gemini3ProHigh,
    gemini3ProLow,
    gemini3Flash,
    gemini25Pro,
    gemini25Flash,
    gemini25FlashThinking,
    gemini25FlashLite,
    claudeOpus45Thinking,
  ];

  /// 额度页面显示排序优先级（越靠前越优先）
  static const List<String> quotaDisplayOrder = [
    gemini3ProHigh,
    gemini3ProLow,
    claudeSonnet45,
    claudeSonnet45Thinking,
    claudeOpus45Thinking,
    gemini3Flash,
    gemini25Pro,
    gemini25Flash,
    gemini25FlashThinking,
  ];

  /// 模型显示名称映射
  static String getDisplayName(String modelName) {
    switch (modelName) {
      // Gemini 系列
      case gemini3ProHigh:
        return 'Gemini 3 Pro High';
      case gemini3ProLow:
        return 'Gemini 3 Pro Low';
      case gemini3ProImage:
        return 'Gemini 3 Pro Image';
      case gemini3Flash:
        return 'Gemini 3 Flash';
      case gemini25Pro:
        return 'Gemini 2.5 Pro';
      case gemini25Flash:
        return 'Gemini 2.5 Flash';
      case gemini25FlashThinking:
        return 'Gemini 2.5 Flash Thinking';
      case gemini25FlashLite:
        return 'Gemini 2.5 Flash Lite';
      case gemini20FlashExp:
        return 'Gemini 2.0 Flash Exp';
      case gemini20FlashThinkingExp:
        return 'Gemini 2.0 Flash Thinking Exp';
      // Claude 系列
      case claudeSonnet45:
        return 'Claude Sonnet 4.5';
      case claudeSonnet45Thinking:
        return 'Claude Sonnet 4.5 Thinking';
      case claudeOpus45Thinking:
        return 'Claude Opus 4.5 Thinking';
      // 通用处理
      default:
        if (modelName.startsWith('gemini-')) {
          return 'Gemini ${modelName.replaceFirst('gemini-', '').replaceAll('-', ' ')}';
        } else if (modelName.startsWith('claude-')) {
          return 'Claude ${modelName.replaceFirst('claude-', '').replaceAll('-', ' ')}';
        }
        return modelName;
    }
  }
}
