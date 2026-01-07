import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

/// OAuth 登录页面 - 使用 WebView 拦截回调方式
/// 逻辑与 fix_token.py 完全一致
class OAuthLoginPage extends StatefulWidget {
  const OAuthLoginPage({super.key});

  @override
  State<OAuthLoginPage> createState() => _OAuthLoginPageState();
}

class _OAuthLoginPageState extends State<OAuthLoginPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _status = '正在加载登录页面...';

  // ================= OAuth 配置 (与 fix_token.py 完全一致) =================
  static const String clientId = "1071006060591-tmhssin2h21lcre235vtolojh4g403ep.apps.googleusercontent.com";
  static const String clientSecret = "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";
  // 关键：使用 localhost 回调，和 Python 一致
  static const String redirectUri = "http://localhost:9999/callback";
  static const String tokenUrl = "https://oauth2.googleapis.com/token";
  
  // Scope 与 fix_token.py 完全一致
  static const List<String> scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/userinfo.email",
    "https://www.googleapis.com/auth/userinfo.profile",
    "https://www.googleapis.com/auth/cclog",
    "https://www.googleapis.com/auth/experimentsandconfigs",
  ];

  String get authUrl {
    final params = {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scopes.join(' '),
      'access_type': 'offline',
      'prompt': 'consent',
      'include_granted_scopes': 'true',
    };
    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'https://accounts.google.com/o/oauth2/v2/auth?$queryString';
  }

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _status = '加载中...';
            });
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
              _status = '';
            });
          },
          onNavigationRequest: (request) {
            debugPrint('🔗 Navigation: ${request.url}');
            
            // 拦截 localhost 回调 (和 Python 逻辑一致)
            if (request.url.startsWith('http://localhost:9999/callback')) {
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            // 忽略 localhost 连接错误（这是正常的，因为手机上没有服务器）
            if (error.url?.contains('localhost') == true) {
              return;
            }
            debugPrint('WebView Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(authUrl));
  }

  Future<void> _handleCallback(String url) async {
    setState(() {
      _isLoading = true;
      _status = '正在获取 Token...';
    });

    try {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      
      if (code == null || code.isEmpty) {
        final error = uri.queryParameters['error'];
        _showError('授权失败: ${error ?? "未知错误"}');
        return;
      }

      debugPrint('收到授权码: ${code.substring(0, 20)}...');

      // 用授权码换取 Token (和 fix_token.py 逻辑完全一致)
      final response = await http.post(
        Uri.parse(tokenUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
          'redirect_uri': redirectUri,
          'grant_type': 'authorization_code',
        },
      ).timeout(const Duration(seconds: 20));

      debugPrint('Token Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final refreshToken = data['refresh_token'];
        
        if (refreshToken != null && refreshToken.toString().isNotEmpty) {
          debugPrint('获取 Refresh Token 成功!');
          if (mounted) {
            Navigator.pop(context, refreshToken);
          }
        } else {
          _showError('响应中没有 refresh_token');
        }
      } else {
        final errorBody = response.body;
        debugPrint('Token Error: $errorBody');
        try {
          final error = jsonDecode(errorBody);
          _showError('Token 请求失败: ${error['error_description'] ?? error['error']}');
        } catch (_) {
          _showError('Token 请求失败: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Exception: $e');
      _showError('网络错误: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      _isLoading = false;
      _status = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google 账号登录'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_status, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
