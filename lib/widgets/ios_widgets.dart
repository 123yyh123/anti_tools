import 'dart:ui';
import 'package:flutter/material.dart';

/// iOS 26 风格的流光背景容器
/// iOS 26 风格的流光背景容器
class IOSBackground extends StatelessWidget {
  final Widget child;
  final Color primaryColor;
  final bool isSimpleMode; // 简约模式：无光晕，纯色渐变

  const IOSBackground({
    super.key,
    required this.child,
    required this.primaryColor,
    this.isSimpleMode = false, // 默认保持流光效果
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 底色层
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSimpleMode 
                // 简约模式：纯色到深色的平滑过渡
                ? [
                    primaryColor.withOpacity(0.15),
                    const Color(0xFF0A0A0A),
                  ]
                // 流光模式：深邃但有色彩倾向
                : [
                    const Color(0xFF1E1E2C), // 深蓝灰
                    const Color(0xFF121212), // 近乎黑
                  ],
            ),
          ),
        ),
        
        // 2. 光晕层（仅在非简约模式显示）
        if (!isSimpleMode) ...[
          // 顶部主色光晕 (左上)
          Positioned(
            top: -120,
            left: -120,
            child: _buildGlowCircle(primaryColor.withOpacity(0.8), 450),
          ),
          
          // 底部互补色光晕 (右下)
          Positioned(
            bottom: -150,
            right: -100,
            child: _buildGlowCircle(Colors.blueAccent.withOpacity(0.7), 350),
          ),
          
          // 中间随机光点
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            right: -60,
            child: _buildGlowCircle(Colors.purpleAccent.withOpacity(0.6), 250),
          ),

          // 模糊遮罩层
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(color: Colors.transparent),
          ),
        ],
        
        // 3. 内容层
        child,
      ],
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 120,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}

/// iOS 26 风格的悬浮玻璃卡片
class IOSGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const IOSGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.all(0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24), // 超大圆角
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // 强力磨砂
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12), // 提升亮度 (0.08 -> 0.12)
                border: Border.all(
                  color: Colors.white.withOpacity(0.25), // 提升描边亮度，增加质感
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS 26 风格的悬浮 TabBar
/// iOS 26 风格的液态玻璃 TabBar (带流动高光)
class IOSFloatingTabBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const IOSFloatingTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<IOSFloatingTabBar> createState() => _IOSFloatingTabBarState();
}

class _IOSFloatingTabBarState extends State<IOSFloatingTabBar> {
  @override
  Widget build(BuildContext context) {
    // 固定的 Tab 项宽度，用于计算滑块位置
    // 这里简单处理：假设只有两个 Tab，平分宽度。
    // 如果 Tab 数量动态，需要更复杂的 LayoutBuilder。
    // 现有逻辑只有 Hub 和 Monitor 两个，我们可以用百分比对齐。

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(50, 0, 50, 24), // 稍微缩进一点
          child: Container(
            height: 64, // 高度微调
            decoration: BoxDecoration(
              // 1. 容器底色 - 极深玻璃
              color: const Color(0xFF1A1A1A).withOpacity(0.75),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Stack(
                  children: [
                    // 2. 液态光标 (The Liquid Blob)
                    // 使用 AnimatedAlign 在两个 Tab 之间滑动
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 350), // 丝滑的 350ms
                      curve: Curves.fastOutSlowIn, // 液态流动的曲线
                      alignment: widget.currentIndex == 0 
                          ? const Alignment(-0.75, 0) // 左边位置微调
                          : const Alignment(0.75, 0), // 右边位置微调
                      child: Container(
                        width: 80, 
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            // 强发光，营造液态光晕
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: -5,
                            ),
                            BoxShadow(
                              color: Colors.purpleAccent.withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Tab 图标层 (透明背景，点击穿透)
                    Row(
                      children: [
                        Expanded(
                          child: _buildItem(0, Icons.rocket_launch, '控制台'),
                        ),
                        Expanded(
                          child: _buildItem(1, Icons.pie_chart, '监控'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, String label) {
    final isSelected = widget.currentIndex == index;
    
    return GestureDetector(
      onTap: () => widget.onTap(index),
      behavior: HitTestBehavior.opaque, // 确保点击区域铺满
      child: Container(
        alignment: Alignment.center,
        child: AnimatedScale(
          scale: isSelected ? 1.05 : 0.95, // 选中微微放大
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 使用 ShaderMask 给选中图标加渐变光泽
              isSelected 
              ? ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFE0E0FF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Icon(icon, color: Colors.white, size: 26),
                )
              : Icon(icon, color: Colors.white.withOpacity(0.4), size: 26),
              
              const SizedBox(height: 4),
              
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'Roboto', // 或者保持默认
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 显示 iOS 26 风格的玻璃弹窗
Future<T?> showIOSDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget>? actions,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.5), // 背景压暗
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: FadeTransition(
              opacity: animation,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525).withOpacity(0.65), // 深色半透明底
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ]
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 标题区
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          // 内容区
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: DefaultTextStyle(
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
                              child: content,
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // 操作区
                          if (actions != null && actions.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                              ),
                              child: Row(
                                children: actions.map((action) {
                                  return Expanded(child: action);
                                }).toList(),
                              ),
                            )
                          else
                            const SizedBox(height: 8), 
                        ],
                      ),
                    ),
                  )
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// 弹窗按钮
/// 弹窗按钮 (实现 iOS 风格按下变色)
class IOSDialogAction extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isDestructive;
  final bool isPrimary;

  const IOSDialogAction({
    super.key,
    required this.text,
    required this.onPressed,
    this.isDestructive = false,
    this.isPrimary = false,
  });

  @override
  State<IOSDialogAction> createState() => _IOSDialogActionState();
}

class _IOSDialogActionState extends State<IOSDialogAction> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _isPressed ? Colors.white.withOpacity(0.1) : Colors.transparent, // 按下时整个区域变亮
          border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: 17,
            fontWeight: widget.isPrimary ? FontWeight.w600 : FontWeight.normal,
            color: widget.isDestructive ? Colors.redAccent : (widget.isPrimary ? Colors.blueAccent : Colors.white),
          ),
        ),
      ),
    );
  }
}
