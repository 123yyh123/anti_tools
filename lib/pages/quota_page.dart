import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/ios_widgets.dart';
import '../services/antigravity_service.dart';
import '../models/supported_models.dart';

class QuotaPage extends StatefulWidget {
  const QuotaPage({super.key});

  @override
  State<QuotaPage> createState() => _QuotaPageState();
}

class _QuotaPageState extends State<QuotaPage> {
  bool _isRefreshing = false;
  bool _isLoading = true;
  QuotaData? _quotaData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCachedData(); // 先加载缓存
  }

  /// 加载缓存的额度数据
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('cached_quota_data');
      
      if (cachedJson != null) {
        final jsonData = jsonDecode(cachedJson);
        final quotaData = QuotaData.fromJson(jsonData);
        
        if (mounted) {
          setState(() {
            _quotaData = quotaData;
            _isLoading = false;
          });
        }
      } else {
        // 没有缓存，直接查询
        _loadQuota();
      }
    } catch (e) {
      print('加载缓存失败: $e');
      _loadQuota(); // 缓存加载失败，直接查询
    }
  }

  /// 从 API 查询最新额度
  Future<void> _loadQuota() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        setState(() {
          _error = '请先在控制台页面获取 Token';
          _isLoading = false;
        });
        return;
      }

      final data = await AntigravityService.fetchQuota(refreshToken);
      
      if (!mounted) return;

      if (data != null) {
        // 保存到缓存
        await _saveToCache(data);
        
        setState(() {
          _quotaData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '额度查询失败，请稍后重试';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '查询异常: $e';
        _isLoading = false;
      });
    }
  }

  /// 保存到缓存
  Future<void> _saveToCache(QuotaData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(data.toJson());
      await prefs.setString('cached_quota_data', jsonStr);
    } catch (e) {
      print('保存缓存失败: $e');
    }
  }

  /// 手动刷新
  Future<void> _refreshQuota() async {
    // 如果已经在加载中，防止重复点击
    if (_isRefreshing || (_isLoading && _quotaData == null)) return;

    setState(() => _isRefreshing = true);
    
    // 注意：这里不再调用 _loadQuota() 里的 setState(isLoading=true)，因为那会触发全屏转圈/黑屏
    // 我们手动执行 _loadQuota 的逻辑部分
    try {
      _error = null; // 清除错误状态，但保留上次的数据显示
      
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        if (mounted) {
          setState(() {
            _error = '请先在控制台页面获取 Token';
            _isRefreshing = false;
          });
        }
        return;
      }

      final data = await AntigravityService.fetchQuota(refreshToken);
      
      if (!mounted) return;

      if (data != null) {
        await _saveToCache(data);
        setState(() {
          _quotaData = data;
          _isRefreshing = false;
          _isLoading = false; // 确保第一次加载后也置为 false
        });
      } else {
        setState(() {
          // 刷新失败仅 toast 或显示错误条，不清除旧数据
           // _error = '额度查询失败，请稍后重试'; // 可选：如果希望显示错误栏
          _isRefreshing = false;
        });
        
        // 建议：可以加个 SnackBar 提示失败，保持界面不闪烁
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('刷新失败，请检查网络'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // _error = '查询异常: $e';
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('刷新异常: $e'), duration: const Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('额度监控'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isRefreshing 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshQuota,
            tooltip: '刷新额度',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
            ? _buildErrorView()
            : _buildQuotaView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: IOSGlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.orangeAccent),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadQuota,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotaView() {
    if (_quotaData == null) {
      return const Center(child: Text('无额度数据'));
    }

    if (_quotaData!.isForbidden) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: IOSGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  '账号已被禁用',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _quotaData!.email,
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 概览卡片
          IOSGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_circle, size: 20, color: Colors.white70),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '当前账号',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ),
                    _buildSubscriptionBadge(_quotaData!.subscriptionTier),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _quotaData!.email,
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 刷新时间提示
          IOSGlassCard(
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.white.withOpacity(0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '上次刷新: ${_formatRefreshTime(_quotaData!.lastRefreshTime)}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                  ),
                ),
                TextButton.icon(
                  onPressed: _isRefreshing ? null : _refreshQuota,
                  icon: _isRefreshing 
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                      )
                    : const Icon(Icons.refresh, size: 14, color: Colors.white70),
                  label: Text(
                    _isRefreshing ? '刷新中...' : '刷新',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 额度统计
          const Text(
            '模型额度',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          const SizedBox(height: 12),

          // 各模型额度卡片
          if (_quotaData!.models.isEmpty)
            IOSGlassCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '暂无模型额度信息',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              ),
            )
          else
            ..._getSortedModels().map((model) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildQuotaCard(model),
            )),

          const SizedBox(height: 100),

          // 底部提示
          // IOSGlassCard(
          //   child: Row(
          //     children: [
          //       Icon(Icons.info_outline, size: 16, color: Colors.blue.shade300),
          //       const SizedBox(width: 8),
          //       Expanded(
          //         child: Text(
          //           _getResetHintText(_quotaData!.subscriptionTier),
          //           style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  /// 按照指定优先级排序模型列表
  List<ModelQuota> _getSortedModels() {
    if (_quotaData == null) return [];
    
    // 使用统一的优先级顺序
    final priorityOrder = SupportedModels.quotaDisplayOrder;

    final models = List<ModelQuota>.from(_quotaData!.models);
    
    models.sort((a, b) {
      final indexA = priorityOrder.indexOf(a.name);
      final indexB = priorityOrder.indexOf(b.name);
      
      // 如果都在优先级列表中，按优先级排序
      if (indexA != -1 && indexB != -1) {
        return indexA.compareTo(indexB);
      }
      // 如果只有 a 在优先级列表中，a 排前面
      if (indexA != -1) return -1;
      // 如果只有 b 在优先级列表中，b 排前面
      if (indexB != -1) return 1;
      // 都不在优先级列表中，保持原顺序
      return 0;
    });
    
    return models;
  }

  Widget _buildSubscriptionBadge(String tier) {
    Color bgColor;
    IconData icon;
    String text;

    final tierUpper = tier.toUpperCase();
    if (tierUpper.contains('ULTRA')) {
      bgColor = Colors.purple.shade600;
      icon = Icons.diamond;
      text = 'ULTRA';
    } else if (tierUpper.contains('PRO')) {
      bgColor = Colors.blue.shade600;
      icon = Icons.star;
      text = 'PRO';
    } else {
      bgColor = Colors.grey.shade600;
      icon = Icons.circle_outlined;
      text = 'FREE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaCard(ModelQuota model) {
    // 根据百分比选择颜色
    Color barColor;
    Color textColor;
    if (model.percentage >= 50) {
      barColor = Colors.green.shade400;
      textColor = Colors.green.shade300;
    } else if (model.percentage >= 20) {
      barColor = Colors.orange.shade400;
      textColor = Colors.orange.shade300;
    } else {
      barColor = Colors.red.shade400;
      textColor = Colors.red.shade300;
    }

    // 使用统一的模型名称映射
    final displayName = SupportedModels.getDisplayName(model.name);

    return IOSGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
              ),
              Row(
                children: [
                  Text(
                    _formatTimeRemaining(model.resetTime),
                    style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${model.percentage}%',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: model.percentage / 100,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [barColor, barColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeRemaining(String resetTimeStr) {
    if (resetTimeStr.isEmpty) return 'R: 未知';
    
    try {
      final resetTime = DateTime.parse(resetTimeStr);
      final duration = resetTime.difference(DateTime.now());
      
      if (duration.isNegative) return 'R: 已重置';
      
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      
      if (hours > 0) {
        return 'R: ${hours}h ${minutes}m';
      } else {
        return 'R: ${minutes}m';
      }
    } catch (e) {
      return 'R: 解析失败';
    }
  }

  /// 格式化刷新时间（人性化显示）
  String _formatRefreshTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays == 1) {
      return '昨天 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.month}/${time.day} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 根据订阅等级获取重置提示
  String _getResetHintText(String tier) {
    final tierUpper = tier.toUpperCase();
    if (tierUpper.contains('ULTRA')) {
      return 'Ultra 用户享有 5 小时快速重置周期';
    } else if (tierUpper.contains('PRO')) {
      return 'Pro 用户享有 5 小时快速重置周期';
    } else if (tierUpper.contains('FREE')) {
      return 'Free 用户通常为 7 天重置周期';
    }
    return '不同订阅等级重置周期不同，请以实际显示为准';
  }
}
