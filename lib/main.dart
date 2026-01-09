import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/antigravity_service.dart';
import 'pages/oauth_login_page.dart';
import 'pages/quota_page.dart';
import 'widgets/ios_widgets.dart';
import 'models/supported_models.dart';

// 全局主题色控制器
final ValueNotifier<Color> themeColor = ValueNotifier(const Color(0xFF000000));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final colorValue = prefs.getInt('theme_color');
  if (colorValue != null) {
    themeColor.value = Color(colorValue);
  }
  runApp(const AntigravityApp());
}

class AntigravityApp extends StatelessWidget {
  const AntigravityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: themeColor,
      builder: (context, color, child) {
        return MaterialApp(
          title: 'AntiTools',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: color,
              brightness: Brightness.dark,
              primary: color, 
              secondary: color,
              surface: Color.alphaBlend(color.withOpacity(0.15), Colors.grey.shade900), 
            ),
            useMaterial3: true,
            // 关键：全局透明，让底层流体背景透出来
            scaffoldBackgroundColor: Colors.transparent, 
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent, 
              elevation: 0,
              centerTitle: true,
            ),
            // 之前的 CardTheme 已经用不到了，因为我们用自定义 IOSGlassCard
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: color.withOpacity(0.8), // 按钮也要带点透明
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
          home: const HomePage(), // 这里等会儿会指向新的 Tab 页
        );
      },
    );
  }
}

class KeepAlivePage extends StatefulWidget {
  const KeepAlivePage({super.key});

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage> {
  final TextEditingController _tokenController = TextEditingController();
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _isRunning = false;
  bool _lastSuccess = false;
  bool _stopRequested = false;

  String _selectedModel = SupportedModels.claudeSonnet45;

  // 默认 Token 为空，需要用户获取
  static const String defaultToken = "";

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('refresh_token') ?? defaultToken;
    _tokenController.text = savedToken;
  }

  Future<void> _saveToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', _tokenController.text.trim());
  }

  /// 打开 OAuth 登录页面获取 Token
  Future<void> _openOAuthLogin() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const OAuthLoginPage()),
    );
    
    if (result != null && result.isNotEmpty) {
      setState(() {
        _tokenController.text = result;
      });
      await _saveToken();
      if (mounted) {
        showIOSDialog(
          context: context,
          title: '✨ 获取成功 ✨',
          content: Column(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Token 已成功获取并自动保存', 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                '您现在可以开始使用额度时钟功能了', 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
              ),
            ],
          ),
          actions: [
            IOSDialogAction(
              text: '好的',
              onPressed: () => Navigator.pop(context),
              isPrimary: true,
            ),
          ],
        );
      }
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add("[${DateTime.now().toString().substring(11, 19)}] $message");
    });
    // 自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showColorPicker() {
    // 1. � 霓虹流光组
    final neonColors = [
      const Color(0xFF7D5FFF), // Cyber Violet
      const Color(0xFF18DCFF), // Neon Blue
      const Color(0xFF32FF7E), // Electric Lime
      const Color(0xFFFF3838), // Crimson Red
      const Color(0xFFFF9F1A), // Plasma Gold
      const Color(0xFFCD84F1), // Bright Lilac
    ];

    // 2. 🌿 简约纯色组 (莫兰迪/Flat)
    final simpleColors = [
      const Color(0xFF000000), // Pure Black (纯黑)
      const Color(0xFFFFFFFF), // Pure White (纯白)
      const Color(0xFFB2BEC3), // Soothing Breeze (银灰)
      const Color(0xFF74B9FF), // Soft Blue (柔光蓝)
      const Color(0xFF55EFC4), // Muted Teal (低调青)
      const Color(0xFFFF7675), // Pink Glamour (柔粉)
      const Color(0xFFA29BFE), // Shy Moment (淡紫)
    ];

    showIOSDialog(
      context: context,
      title: '选择主题光晕',
      content: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        // 限制高度以防溢出屏幕
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColorSection('霓虹流光', neonColors, useGlow: true),
              const SizedBox(height: 24),
              _buildColorSection('简约纯色', simpleColors, useGlow: false), // 关闭发光
            ],
          ),
        ),
      ),
      actions: [
        IOSDialogAction(
          text: '完成',
          onPressed: () => Navigator.pop(context),
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildColorSection(String title, List<Color> colors, {required bool useGlow}) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            letterSpacing: 1,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: colors.map((color) {
            final isSelected = themeColor.value.value == color.value;
            // 对于纯色模式，如果颜色太浅（如白），Icon需要用深色
            final isLightColor = color.computeLuminance() > 0.5;
            
            return GestureDetector(
              onTap: () async {
                themeColor.value = color;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('theme_color', color.value);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  // 只有 useGlow 为 true 时才显示发光阴影
                  boxShadow: useGlow ? [
                    BoxShadow(
                      color: color.withOpacity(isSelected ? 0.6 : 0.2),
                      blurRadius: isSelected ? 12 : 6,
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                  ] : null, // 纯色模式无阴影
                  border: isSelected
                    ? Border.all(color: Colors.white, width: 3)
                    : Border.all(color: Colors.white.withOpacity(0.2), width: 1), // 增加一点边框清晰度
                ),
                child: isSelected
                    ? Icon(
                        Icons.check, 
                        color: (useGlow || !isLightColor) ? Colors.white : Colors.black87, 
                        size: 24
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showModelPicker() {
    showIOSDialog(
      context: context,
      title: '选择模型',
      content: SizedBox(
        height: 300,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: SupportedModels.availableModels.length,
          separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.1), height: 1),
          itemBuilder: (context, index) {
            final model = SupportedModels.availableModels[index];
            final isSelected = model == _selectedModel;
            return InkWell(
              onTap: () {
                setState(() => _selectedModel = model);
                Navigator.pop(context);
              },
              splashColor: Colors.transparent, // 禁用扩散水波纹
              highlightColor: Colors.white.withOpacity(0.1), // 仅使用高亮
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        model,
                        style: TextStyle(
                          fontSize: 15,
                          color: isSelected ? Colors.blueAccent : Colors.white70,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check, color: Colors.blueAccent, size: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        IOSDialogAction(
          text: '取消',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Future<void> _runKeepAlive() async {
    // 如果正在运行，则视为停止请求
    if (_isRunning) {
      _stopRequested = true;
      _addLog("🛑 正在停止任务...");
      return;
    }
    
    // 如果没有 Token，提示获取
    if (_tokenController.text.isEmpty) {
      showIOSDialog(
        context: context,
        title: '提示',
        content: const Text('请先获取 Token!', textAlign: TextAlign.center),
        actions: [
          IOSDialogAction(
            text: '好的',
            onPressed: () => Navigator.pop(context),
            isPrimary: true,
          ),
        ],
      );
      return;
    }
    
    await _saveToken();
    
    setState(() {
      _isRunning = true;
      _logs.clear();
      _lastSuccess = false;
      _stopRequested = false;
    });
    
    final service = AntigravityService(
      refreshToken: _tokenController.text.trim(),
      onLog: _addLog,
      selectedModel: _selectedModel,
    );
    
    // 传入检查停止的回调
    final success = await service.runFullProcess(
      checkStop: () => _stopRequested,
    );
    
    if (mounted) {
      setState(() {
        _isRunning = false;
        _lastSuccess = success;
      });
      
      if (success) {
        // 延迟一点点，让停止动画先播完
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          showIOSDialog(
            context: context,
            title: '✨ 成功 ✨',
            content: Column(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 64),
                const SizedBox(height: 16),
                const Text(
                  '额度时钟已重置', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  '已消耗微量 Token，若为首次发送，下一次重置将在约 5 小时后', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
            actions: [
              IOSDialogAction(
                text: '太棒了',
                onPressed: () => Navigator.pop(context),
                isPrimary: true,
              ),
            ],
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AntiTools'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: _showColorPicker,
            tooltip: '切换主题',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Token 输入区
                    IOSGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Refresh Token',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                              ),
                              TextButton.icon(
                                onPressed: _openOAuthLogin,
                                icon: const Icon(Icons.login, size: 16, color: Colors.white),
                                label: const Text('获取 Token', style: TextStyle(color: Colors.white)),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _tokenController,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 12, color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.2),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              hintText: '点击上方按钮获取，或手动粘贴...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Column(
                        children: [
                          const Text(
                            '📢 P.S. 请确保已开启 VPN/代理，否则无法连接',
                            style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // 模型选择区
                    // 模型选择区
                    GestureDetector(
                      onTap: _showModelPicker,
                      child: IOSGlassCard(
                        child: Row(
                          children: [
                            const Icon(Icons.smart_toy, size: 20, color: Colors.white70),
                            const SizedBox(width: 12),
                            const Text('模型', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            const Spacer(),
                            Text(
                              _selectedModel,
                              style: const TextStyle(fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 20),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // 一键打卡按钮
                    SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _runKeepAlive, // 运行状态下点击即为停止
                        icon: _isRunning
                            ? const Icon(Icons.stop_circle_outlined, size: 28)
                            : Icon(
                                _lastSuccess ? Icons.check_circle : Icons.rocket_launch,
                                size: 28,
                              ),
                        label: Text(
                          _isRunning ? '停止激活' : '激活额度时钟',
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          // 运行时显示红色 (停止)，成功时显示绿色，默认显示主题色
                          backgroundColor: _isRunning 
                              ? Colors.redAccent 
                              : (_lastSuccess ? Colors.green.shade700 : null), 
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              
              // 日志标题区
              SliverToBoxAdapter(
                child: IOSGlassCard(
                  margin: const EdgeInsets.only(bottom: 2), 
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '执行日志',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (_logs.isNotEmpty)
                        GestureDetector(
                          onTap: () => setState(() => _logs.clear()),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('清空', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 日志空状态或列表
              if (_logs.isEmpty)
                SliverToBoxAdapter(
                  child: IOSGlassCard(
                    margin: const EdgeInsets.only(top: 0),
                    child: SizedBox(
                      height: 200, // 给个固定高度
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_edu, size: 48, color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 12),
                            Text(
                              '暂无日志记录',
                              style: TextStyle(color: Colors.white.withOpacity(0.4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  // 底部留出足够空间给悬浮 TabBar (70 + 20 + 20)
                  padding: const EdgeInsets.only(bottom: 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final log = _logs[index];
                        Color color = Colors.white70;
                        if (log.contains('成功')) color = Colors.greenAccent;
                        if (log.contains('失败') || log.contains('错误') || log.contains('异常')) color = Colors.redAccent;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), // 稍微缩进
                          child: Container(
                            // 给个极其微弱的背景区分行
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? Colors.white.withOpacity(0.03) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13, // 稍微大一点更易读
                                color: color,
                                height: 1.4,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: _logs.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _tokenController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // 使用 IndexedStack 需要保持页面实例
  final List<Widget> _pages = const [
    KeepAlivePage(),
    QuotaPage(),
  ];

  @override
  Widget build(BuildContext context) {
    // 定义简约色组（与 _showColorPicker 中的保持一致）
    const simpleColors = [
      Color(0xFF000000), // Pure Black
      Color(0xFFFFFFFF), // Pure White
      Color(0xFFB2BEC3), // Silver Grey
      Color(0xFF74B9FF), // Soft Blue
      Color(0xFF55EFC4), // Muted Teal
      Color(0xFFFF7675), // Pink Glamour
      Color(0xFFA29BFE), // Shy Moment
    ];

    // 监听主题色变化，传递给背景
    return ValueListenableBuilder<Color>(
      valueListenable: themeColor,
      builder: (context, color, child) {
        // 判断当前颜色是否属于简约组
        final isSimpleMode = simpleColors.any((c) => c.value == color.value);
        
        return Scaffold(
          // 关键：将 Scaffold 背景设为透明，以便露出底层的 IOSBackground
          backgroundColor: Colors.transparent, 
          extendBody: true, // 让 body 延伸到底部，覆盖在 TabBar 下面
          body: IOSBackground(
            primaryColor: color, // 传递当前主题色
            isSimpleMode: isSimpleMode, // 传递简约模式标志
            child: Stack(
              children: [
                // 页面内容
                IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
                
                // 悬浮 TabBar
                IOSFloatingTabBar(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
