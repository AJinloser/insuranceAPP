import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/experiment_service.dart';

/// 测后问卷页面
class PostSurveyPage extends StatefulWidget {
  const PostSurveyPage({Key? key}) : super(key: key);

  @override
  State<PostSurveyPage> createState() => _PostSurveyPageState();
}

class _PostSurveyPageState extends State<PostSurveyPage> {
  bool _hasClickedLink = false;

  @override
  Widget build(BuildContext context) {
    final surveyUrl = dotenv.env['POST_SURVEY_URL'] ?? 'https://www.wjx.cn';
    
    return WillPopScope(
      onWillPop: () async => false, // 禁止返回
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F5FF),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8E6FF7).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in,
                            size: 40,
                            color: Color(0xFF8E6FF7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // 标题
                        const Text(
                          '实验即将结束',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // 说明文字
                        const Text(
                          '感谢您参与本次实验!在结束前,请完成测后问卷。问卷将帮助我们了解您的实验体验和感受。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6B7280),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        const Text(
                          '请点击下方链接填写问卷,完成后点击退出按钮结束实验。',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // 问卷链接按钮
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final uri = Uri.parse(surveyUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                                setState(() {
                                  _hasClickedLink = true;
                                });
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('无法打开问卷链接')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text(
                              '打开测后问卷',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8E6FF7),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // 提示信息
                        if (!_hasClickedLink)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '请先点击上方链接打开问卷',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // 退出按钮
                        if (_hasClickedLink) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '已打开问卷链接,完成问卷后点击退出',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                debugPrint('===> PostSurveyPage: 点击退出实验按钮');
                                
                                final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false,
                                );
                                final experimentService = Provider.of<ExperimentService>(
                                  context,
                                  listen: false,
                                );
                                
                                // 先保存userId，因为logout后会清空
                                final userId = authService.userId;
                                debugPrint('===> PostSurveyPage: userId = $userId');
                                
                                if (userId == null) {
                                  debugPrint('===> PostSurveyPage: userId为null，无法继续');
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('用户信息已失效，无法更新实验进度')),
                                    );
                                  }
                                  return;
                                }
                                
                                // 更新实验进度
                                debugPrint('===> PostSurveyPage: 开始更新实验进度');
                                await experimentService.updateProgress(
                                  userId: userId,
                                  completedPostSurvey: true,
                                );
                                debugPrint('===> PostSurveyPage: 实验进度更新完成');
                                
                                // 清除实验信息
                                debugPrint('===> PostSurveyPage: 清除实验信息');
                                experimentService.clear();
                                
                                // 退出登录
                                debugPrint('===> PostSurveyPage: 开始退出登录');
                                debugPrint('===> PostSurveyPage: 登出前 authStatus = ${authService.authStatus}');
                                await authService.logout();
                                debugPrint('===> PostSurveyPage: 登出后 authStatus = ${authService.authStatus}');
                                
                                // 返回根页面（MaterialApp的home）
                                // MaterialApp会根据authStatus自动显示LoginScreen
                                debugPrint('===> PostSurveyPage: mounted = $mounted');
                                if (mounted) {
                                  debugPrint('===> PostSurveyPage: 导航到根页面');
                                  try {
                                    // 使用 pushNamedAndRemoveUntil 返回到根路由
                                    // 由于没有定义 '/' 路由，Navigator会回退到MaterialApp的home
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/',
                                      (route) => false,
                                    );
                                    debugPrint('===> PostSurveyPage: 导航操作完成');
                                  } catch (e) {
                                    debugPrint('===> PostSurveyPage: 导航操作出错: $e');
                                  }
                                } else {
                                  debugPrint('===> PostSurveyPage: mounted=false，无法执行导航操作');
                                }
                              },
                              icon: const Icon(Icons.exit_to_app),
                              label: const Text(
                                '退出实验',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[400],
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
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

