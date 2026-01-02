import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/experiment_service.dart';

/// 声明页面
class DeclarationPage extends StatefulWidget {
  const DeclarationPage({Key? key}) : super(key: key);

  @override
  State<DeclarationPage> createState() => _DeclarationPageState();
}

class _DeclarationPageState extends State<DeclarationPage> {
  bool _algorithmAgreed = false;
  bool _interestAgreed = false;
  bool _privacyAgreed = false;
  
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: Consumer<ExperimentService>(
        builder: (context, experimentService, child) {
          final info = experimentService.experimentInfo;
          
          if (info == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // 根据分组决定展示哪些声明
          final declarations = <Map<String, dynamic>>[];
          
          if (info.showAlgorithmDeclaration) {
            declarations.add({
              'title': '算法透明度声明',
              'icon': Icons.psychology,
              'content': dotenv.env['ALGORITHM_DECLARATION'] ?? '算法声明内容',
              'agreed': _algorithmAgreed,
              'onChanged': (bool? value) {
                setState(() {
                  _algorithmAgreed = value ?? false;
                });
              },
            });
          }
          
          if (info.showInterestDeclaration) {
            declarations.add({
              'title': '利益立场声明',
              'icon': Icons.balance,
              'content': dotenv.env['INTEREST_DECLARATION'] ?? '利益立场声明内容',
              'agreed': _interestAgreed,
              'onChanged': (bool? value) {
                setState(() {
                  _interestAgreed = value ?? false;
                });
              },
            });
          }
          
          if (info.showPrivacyDeclaration) {
            declarations.add({
              'title': '隐私保护声明',
              'icon': Icons.security,
              'content': dotenv.env['PRIVACY_DECLARATION'] ?? '隐私声明内容',
              'agreed': _privacyAgreed,
              'onChanged': (bool? value) {
                setState(() {
                  _privacyAgreed = value ?? false;
                });
              },
            });
          }

          // 如果没有需要展示的声明,直接跳转
          if (declarations.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await experimentService.updateProgress(
                userId: authService.userId!,
                completedDeclaration: true,
              );
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/experiment-conversation');
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

          // 检查当前页是否已同意
          bool currentPageAgreed = false;
          if (_currentPage < declarations.length) {
            currentPageAgreed = declarations[_currentPage]['agreed'] as bool;
          }
          
          final isLastPage = _currentPage == declarations.length - 1;

          return Column(
            children: [
              // 页面指示器
              if (declarations.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(declarations.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF8E6FF7)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              
              // 分页内容
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // 禁用手势滑动
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: declarations.length,
                  itemBuilder: (context, index) {
                    final declaration = declarations[index];
                    return _buildDeclarationPage(
                      title: declaration['title'] as String,
                      icon: declaration['icon'] as IconData,
                      content: declaration['content'] as String,
                      agreed: declaration['agreed'] as bool,
                      onChanged: declaration['onChanged'] as Function(bool?),
                      pageNumber: index + 1,
                      totalPages: declarations.length,
                    );
                  },
                ),
              ),
              
              // 底部按钮区域
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // 上一步按钮（如果不是第一页）
                      if (_currentPage > 0)
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF8E6FF7)),
                                foregroundColor: const Color(0xFF8E6FF7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                '上一步',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      if (_currentPage > 0) const SizedBox(width: 12),
                      
                      // 下一步/完成按钮
                      Expanded(
                        flex: _currentPage > 0 ? 1 : 1,
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: currentPageAgreed
                                ? () async {
                                    if (isLastPage) {
                                      // 最后一页，完成所有声明
                                      final authService = Provider.of<AuthService>(
                                        context,
                                        listen: false,
                                      );
                                      
                                      final success = await experimentService.updateProgress(
                                        userId: authService.userId!,
                                        completedDeclaration: true,
                                      );
                                      
                                      if (success && mounted) {
                                        Navigator.of(context).pushReplacementNamed(
                                          '/experiment-conversation',
                                        );
                                      } else if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('更新进度失败,请重试')),
                                        );
                                      }
                                    } else {
                                      // 不是最后一页，跳转到下一页
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8E6FF7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isLastPage ? '开始使用' : '下一步',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeclarationPage({
    required String title,
    required IconData icon,
    required String content,
    required bool agreed,
    required Function(bool?) onChanged,
    required int pageNumber,
    required int totalPages,
  }) {
    return Container(
      color: const Color(0xFFF8F5FF),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 图标和标题
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8E6FF7).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                size: 40,
                                color: const Color(0xFF8E6FF7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (totalPages > 1)
                              Text(
                                '声明 $pageNumber / $totalPages',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // 声明内容 - 醒目显示
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E6FF7).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF8E6FF7).withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          content,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Color(0xFF1F2937),
                            height: 1.8,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 同意勾选框 - 更醒目
                      InkWell(
                        onTap: () => onChanged(!agreed),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: agreed
                                ? const Color(0xFF8E6FF7).withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: agreed
                                  ? const Color(0xFF8E6FF7)
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Transform.scale(
                                scale: 1.2,
                                child: Checkbox(
                                  value: agreed,
                                  onChanged: onChanged,
                                  activeColor: const Color(0xFF8E6FF7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  '我已仔细阅读并完全理解以上声明内容',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF2D3142),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

