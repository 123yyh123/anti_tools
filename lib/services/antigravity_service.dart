import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class AntigravityService {
  // ================= 核心常量 =================
  static const String clientId = "1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com";
  static const String clientSecret = "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";
  static const String tokenUrl = "https://oauth2.googleapis.com/token";
  static const String projectUrl = "https://daily-cloudcode-pa.googleapis.com/v1internal:loadCodeAssist";
  static const String chatUrl = "https://daily-cloudcode-pa.googleapis.com/v1internal:streamGenerateContent?alt=sse";
  
  String refreshToken;
  String selectedModel;
  final void Function(String) onLog;
  
  AntigravityService({
    required this.refreshToken, 
    required this.onLog,
    required this.selectedModel,
  });

  /// 刷新 Access Token
  Future<String?> getAccessToken() async {
    onLog("正在刷新 Access Token...");
    try {
      final response = await http.post(
        Uri.parse(tokenUrl),
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        onLog("Token 刷新成功");
        return data['access_token'];
      } else {
        onLog("Token 刷新失败 [${response.statusCode}]");
        return null;
      }
    } catch (e) {
      onLog("网络错误: $e");
      return null;
    }
  }

  /// 获取 Project ID
  Future<String> getProjectId(String accessToken) async {
    onLog("获取 Project ID...");
    try {
      final response = await http.post(
        Uri.parse(projectUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'User-Agent': 'antigravity/1.11.9 android',
        },
        body: jsonEncode({'metadata': {'ideType': 'ANTIGRAVITY'}}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('cloudaicompanionProject')) {
          final pid = data['cloudaicompanionProject'];
          onLog("Project ID: $pid");
          return pid;
        }
      }
    } catch (e) {
      onLog("获取 Project ID 异常: $e");
    }
    
    // 兜底：生成随机 ID
    final fallback = "useful-spark-${Random().nextInt(90000) + 10000}";
    onLog("使用随机兜底 ID: $fallback");
    return fallback;
  }

  /// 发送保活请求 (使用用户选择的模型)
  Future<bool> sendKeepAlive(String accessToken, String projectId, {bool Function()? checkStop}) async {
    onLog("发送额度激活请求 (模型: $selectedModel)...");
    
    for (int i = 0; i < 5; i++) {
      if (checkStop?.call() == true) {
        onLog("🛑 任务已手动停止");
        return false;
      }

      onLog("[${i + 1}/5] 尝试中...");
      
      final payload = {
        'project': projectId,
        'requestId': 'agent-${_generateUuid()}',
        'request': {
          'contents': [{'role': 'user', 'parts': [{'text': 'Keep-alive'}]}],
          'systemInstruction': {
            'role': 'user',
            'parts': [{'text': 'You are Antigravity, a powerful agentic AI coding assistant designed by the Google Deepmind team working on Advanced Agentic Coding.You are pair programming with a USER to solve their coding task. The task may require creating a new codebase, modifying or debugging an existing codebase, or simply answering a question.**Absolute paths only****Proactiveness**'}]
          }
        },
        'model': selectedModel,
        'userAgent': 'antigravity',
        'requestType': 'agent',
      };

      try {
        final response = await http.post(
          Uri.parse(chatUrl),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
            'User-Agent': 'antigravity/1.11.9 android',
          },
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          onLog("成功！额度已激活。");
          return true;
        } else {
          onLog("失败 [${response.statusCode}]");
        }
      } catch (e) {
        onLog("网络异常: $e");
      }
      
      // 等待期间也要检查
      for (int w = 0; w < 4; w++) { // 2秒拆成 4 个 0.5s，响应更快
        if (checkStop?.call() == true) {
          onLog("🛑 任务已手动停止");
          return false;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    
    onLog("5 次尝试均失败");
    return false;
  }


  /// 一键执行完整流程
  Future<bool> runFullProcess({bool Function()? checkStop}) async {
    if (checkStop?.call() == true) return false;
    
    final token = await getAccessToken();
    if (token == null) return false;
    
    if (checkStop?.call() == true) return false;

    final projectId = await getProjectId(token);
    
    if (checkStop?.call() == true) return false;

    return await sendKeepAlive(token, projectId, checkStop: checkStop);
  }

  /// 获取用户邮箱
  static Future<String> getUserEmail(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['email'] ?? 'Unknown';
      }
    } catch (e) {
      print('获取用户邮箱失败: $e');
    }
    return 'Unknown';
  }

  /// 查询额度信息
  static Future<QuotaData?> fetchQuota(String refreshToken) async {
    try {
      // 1. 刷新 Access Token
      final tokenResponse = await http.post(
        Uri.parse(tokenUrl),
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      ).timeout(const Duration(seconds: 20));

      if (tokenResponse.statusCode != 200) {
        print('Token 刷新失败');
        return null;
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final accessToken = tokenData['access_token'];

      // 2. 获取用户邮箱
      final email = await getUserEmail(accessToken);

      // 3. 获取 Project ID 和订阅信息
      final projectResponse = await http.post(
        Uri.parse('https://cloudcode-pa.googleapis.com/v1internal:loadCodeAssist'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'User-Agent': 'antigravity/windows/amd64',
        },
        body: jsonEncode({'metadata': {'ideType': 'ANTIGRAVITY'}}),
      ).timeout(const Duration(seconds: 15));

      String? projectId;
      String? subscriptionTier;
      
      if (projectResponse.statusCode == 200) {
        final projectData = jsonDecode(projectResponse.body);
        projectId = projectData['cloudaicompanionProject'];
        
        // 优先从 paidTier 获取订阅信息
        if (projectData['paidTier'] != null) {
          subscriptionTier = projectData['paidTier']['id'];
        } else if (projectData['currentTier'] != null) {
          subscriptionTier = projectData['currentTier']['id'];
        }
      }

      final finalProjectId = projectId ?? 'bamboo-precept-lgxtn';

      // 4. 查询额度
      final quotaResponse = await http.post(
        Uri.parse('https://cloudcode-pa.googleapis.com/v1internal:fetchAvailableModels'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'User-Agent': 'antigravity/1.11.3 Darwin/arm64',
        },
        body: jsonEncode({'project': finalProjectId}),
      ).timeout(const Duration(seconds: 15));

      if (quotaResponse.statusCode == 403) {
        // 账号被禁用
        return QuotaData(
          email: email,
          models: [],
          isForbidden: true,
          subscriptionTier: subscriptionTier ?? 'FREE',
        );
      }

      if (quotaResponse.statusCode != 200) {
        print('额度查询失败: ${quotaResponse.statusCode}');
        return null;
      }

      final quotaData = jsonDecode(quotaResponse.body);
      final modelsMap = quotaData['models'] as Map<String, dynamic>;
      
      final List<ModelQuota> models = [];
      
      modelsMap.forEach((name, info) {
        if (info['quotaInfo'] != null) {
          final quotaInfo = info['quotaInfo'];
          final percentage = ((quotaInfo['remainingFraction'] ?? 0.0) * 100).toInt();
          final resetTime = quotaInfo['resetTime'] ?? '';
          
          // 只保留 gemini 和 claude 模型
          if (name.contains('gemini') || name.contains('claude')) {
            models.add(ModelQuota(
              name: name,
              percentage: percentage,
              resetTime: resetTime,
            ));
          }
        }
      });

      return QuotaData(
        email: email,
        models: models,
        isForbidden: false,
        subscriptionTier: subscriptionTier ?? 'FREE',
      );
    } catch (e) {
      print('额度查询异常: $e');
      return null;
    }
  }
  
  String _generateUuid() {
    final random = Random();
    return '${_hex(random, 8)}-${_hex(random, 4)}-${_hex(random, 4)}-${_hex(random, 4)}-${_hex(random, 12)}';
  }
  
  String _hex(Random random, int length) {
    return List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  }
}

// 额度数据模型
class QuotaData {
  final String email;
  final List<ModelQuota> models;
  final bool isForbidden;
  final String subscriptionTier;
  final DateTime lastRefreshTime; // 新增：最后刷新时间

  QuotaData({
    required this.email,
    required this.models,
    this.isForbidden = false,
    this.subscriptionTier = 'FREE',
    DateTime? lastRefreshTime,
  }) : lastRefreshTime = lastRefreshTime ?? DateTime.now();

  // 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'models': models.map((m) => m.toJson()).toList(),
      'isForbidden': isForbidden,
      'subscriptionTier': subscriptionTier,
      'lastRefreshTime': lastRefreshTime.toIso8601String(),
    };
  }

  // 从 JSON 反序列化
  factory QuotaData.fromJson(Map<String, dynamic> json) {
    return QuotaData(
      email: json['email'] ?? '',
      models: (json['models'] as List?)
          ?.map((m) => ModelQuota.fromJson(m))
          .toList() ?? [],
      isForbidden: json['isForbidden'] ?? false,
      subscriptionTier: json['subscriptionTier'] ?? 'FREE',
      lastRefreshTime: json['lastRefreshTime'] != null 
          ? DateTime.parse(json['lastRefreshTime'])
          : DateTime.now(),
    );
  }
}

class ModelQuota {
  final String name;
  final int percentage;
  final String resetTime;

  ModelQuota({
    required this.name,
    required this.percentage,
    required this.resetTime,
  });

  // 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'percentage': percentage,
      'resetTime': resetTime,
    };
  }

  // 从 JSON 反序列化
  factory ModelQuota.fromJson(Map<String, dynamic> json) {
    return ModelQuota(
      name: json['name'] ?? '',
      percentage: json['percentage'] ?? 0,
      resetTime: json['resetTime'] ?? '',
    );
  }
}
