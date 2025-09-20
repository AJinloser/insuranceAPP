import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';
import '../widgets/guidance_widgets.dart';

class PlanningAnalysisPage extends StatefulWidget {
  const PlanningAnalysisPage({Key? key}) : super(key: key);

  @override
  State<PlanningAnalysisPage> createState() => _PlanningAnalysisPageState();
}

class _PlanningAnalysisPageState extends State<PlanningAnalysisPage> {
  String _timeRange = '周'; // 周、月
  bool _isLoading = false;
  String? _selectedGoalId; // 用于记录选中的目标ID，用于环状图交互
  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // 获取目标基本信息
    final goalService = Provider.of<GoalService>(context, listen: false);
    await goalService.getGoalBasicInfo(context);
    
    // 获取图表数据
    await _loadChartData();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadChartData() async {
    try {
      debugPrint('开始加载图表数据，时间范围: $_timeRange');
      setState(() {
        _chartData.clear(); // 清空之前的数据
      });

      final goalService = Provider.of<GoalService>(context, listen: false);
      final now = DateTime.now();
      
      // 根据时间范围获取数据
      List<DateTime> dates = [];
      switch (_timeRange) {
        case '周':
          for (int i = 6; i >= 0; i--) {
            dates.add(now.subtract(Duration(days: i)));
          }
          break;
        case '月':
          for (int i = 29; i >= 0; i--) {
            dates.add(now.subtract(Duration(days: i)));
          }
          break;
      }

      debugPrint('生成日期列表，共 ${dates.length} 个日期');
      List<Map<String, dynamic>> newChartData = [];
      
      for (final date in dates) {
        final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final goals = await goalService.getGoalsByDate(context, dateString);
        
        double plannedAmount = 0.0;
        double completedAmount = 0.0;
        
        for (final goal in goals) {
          for (final subTask in goal.subTasks) {
            plannedAmount += subTask.subTaskAmount ?? 0.0;
            if (subTask.subTaskStatus == true) {
              completedAmount += subTask.subTaskAmount ?? 0.0;
            }
          }
        }
        
        newChartData.add({
          'date': date,
          'planned': plannedAmount,
          'completed': completedAmount,
        });
      }

      debugPrint('图表数据加载完成，共 ${newChartData.length} 个数据点');
      setState(() {
        _chartData = newChartData;
      });
    } catch (e) {
      debugPrint('加载图表数据失败: $e');
      setState(() {
        _chartData = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<GoalService>(
        builder: (context, goalService, child) {
          final hasGoals = goalService.goals.isNotEmpty;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 引导性内容（始终显示）
                _buildAnalysisGuidanceContent(),
                const SizedBox(height: 24),
                
                // 图表内容或空状态
                if (hasGoals) ...[
                  _buildPieChart(),
                  const SizedBox(height: 32),
                  _buildLineChart(),
                ] else ...[
                  _buildEmptyAnalysisState(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPieChart() {
    return Consumer<GoalService>(
      builder: (context, goalService, child) {
        final goals = goalService.goals;
        
        if (goals.isEmpty) {
          return _buildEmptyPieChart();
        }

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _selectedGoalId == null ? '目标分配概览' : '子目标分解',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    if (_selectedGoalId != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedGoalId = null;
                          });
                        },
                        tooltip: '返回目标概览',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PieChart(
                          PieChartData(
                            sections: _selectedGoalId == null 
                                ? _buildPieSections(goals)
                                : _buildSubGoalPieSections(goals),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
                                  if (_selectedGoalId == null) {
                                    // 在目标概览模式下，点击选择目标
                                    final index = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                                    if (index < goals.length) {
                                      setState(() {
                                        _selectedGoalId = goals[index].goalId;
                                      });
                                    }
                                  }
                                  // 在子目标模式下，不处理点击事件（可以扩展为选择特定子目标）
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _selectedGoalId == null
                            ? _buildPieLegend(goals)
                            : _buildSubGoalLegend(goals),
                      ),
                    ],
                  ),
                ),
                if (_selectedGoalId != null) ...[
                  const SizedBox(height: 20),
                  _buildSubGoalDetails(_selectedGoalId!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 构建规划分析页面的引导性内容
  Widget _buildAnalysisGuidanceContent() {
    return Column(
      children: [
        // 欢迎卡片
        GuidanceWidgets.buildWelcomeCard(
          context: context,
          title: '财务规划分析',
          subtitle: '通过可视化图表分析您的财务目标分配和完成进度，让规划更加直观',
          icon: Icons.analytics_outlined,
        ),
        const SizedBox(height: 16),
        
        // 功能介绍卡片
        GuidanceWidgets.buildFeaturesCard(
          title: '分析功能说明',
          features: [
            FeatureItem(
              icon: Icons.pie_chart,
              title: '目标分配图',
              description: '环状图显示各目标的金额占比，点击查看子目标分解',
              color: Colors.blue,
            ),
            FeatureItem(
              icon: Icons.show_chart,
              title: '进度趋势图',
              description: '折线图追踪预计完成与实际完成的对比趋势',
              color: Colors.green,
            ),
            FeatureItem(
              icon: Icons.insights,
              title: '数据洞察',
              description: '通过数据分析发现规划中的问题，优化目标设定',
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  /// 构建空状态分析页面
  Widget _buildEmptyAnalysisState() {
    return Column(
      children: [
        GuidanceWidgets.buildHelpTipCard(
          title: '开始数据分析',
          description: '前往"目标"页面创建您的第一个财务目标，然后回到这里查看分析图表',
          icon: Icons.lightbulb_outline,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 24),
        
        // 空状态的图表预览
        _buildEmptyChartPreviews(),
      ],
    );
  }

  /// 构建空状态图表预览
  Widget _buildEmptyChartPreviews() {
    return Column(
      children: [
        // 空的饼图
        _buildEmptyPieChart(),
        const SizedBox(height: 32),
        
        // 空的折线图
        _buildEmptyLineChart(),
      ],
    );
  }

  Widget _buildEmptyPieChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '目标分配概览',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '设定目标后查看各目标的金额分配情况',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(List<Goal> goals) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    double totalAmount = goals.fold(0.0, (sum, goal) => sum + (goal.targetAmount ?? 0.0));
    
    if (totalAmount == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey[300],
          value: 1,
          title: '无数据',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ];
    }

    return goals.asMap().entries.map((entry) {
      final index = entry.key;
      final goal = entry.value;
      final amount = goal.targetAmount ?? 0.0;
      final percentage = (amount / totalAmount * 100);
      
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: amount,
        title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: _selectedGoalId == goal.goalId ? 70 : 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildPieLegend(List<Goal> goals) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: goals.asMap().entries.map((entry) {
        final index = entry.key;
        final goal = entry.value;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedGoalId = _selectedGoalId == goal.goalId ? null : goal.goalId;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _selectedGoalId == goal.goalId 
                  ? colors[index % colors.length].withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.goalName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '¥${goal.targetAmount?.toStringAsFixed(0) ?? '0'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> _buildSubGoalPieSections(List<Goal> goals) {
    final selectedGoal = goals.firstWhere((g) => g.goalId == _selectedGoalId);
    final subGoals = selectedGoal.subGoals;
    
    final colors = [
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
    ];

    if (subGoals.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey[300],
          value: 1,
          title: '无子目标',
          radius: 60,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ];
    }

    double totalSubGoalAmount = subGoals.fold(0.0, (sum, subGoal) => sum + (subGoal.subGoalAmount ?? 0.0));
    double targetAmount = selectedGoal.targetAmount ?? 0.0;
    double remainingAmount = targetAmount - totalSubGoalAmount;

    List<PieChartSectionData> sections = [];

    // 添加子目标部分
    for (int i = 0; i < subGoals.length; i++) {
      final subGoal = subGoals[i];
      final amount = subGoal.subGoalAmount ?? 0.0;
      
      if (amount > 0) {
        final percentage = targetAmount > 0 ? (amount / targetAmount * 100) : 0.0;
        sections.add(
          PieChartSectionData(
            color: colors[i % colors.length],
            value: amount,
            title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }

    // 添加未分配部分
    if (remainingAmount > 0) {
      final percentage = targetAmount > 0 ? (remainingAmount / targetAmount * 100) : 0.0;
      sections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: remainingAmount,
          title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // 如果没有有效的子目标，显示整个目标
    if (sections.isEmpty) {
      sections.add(
        PieChartSectionData(
          color: Colors.blue,
          value: targetAmount > 0 ? targetAmount : 1,
          title: '100%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildSubGoalLegend(List<Goal> goals) {
    final selectedGoal = goals.firstWhere((g) => g.goalId == _selectedGoalId);
    final subGoals = selectedGoal.subGoals;
    
    final colors = [
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.red.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
    ];

    if (subGoals.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '该目标暂无子目标',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    double totalSubGoalAmount = subGoals.fold(0.0, (sum, subGoal) => sum + (subGoal.subGoalAmount ?? 0.0));
    double targetAmount = selectedGoal.targetAmount ?? 0.0;
    double remainingAmount = targetAmount - totalSubGoalAmount;

    List<Widget> legendItems = [];

    // 添加子目标图例
    for (int i = 0; i < subGoals.length; i++) {
      final subGoal = subGoals[i];
      final amount = subGoal.subGoalAmount ?? 0.0;
      
      if (amount > 0) {
        legendItems.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subGoal.subGoalName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '¥${amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // 添加未分配图例
    if (remainingAmount > 0) {
      legendItems.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '未分配',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '¥${remainingAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: legendItems,
    );
  }

  Widget _buildSubGoalDetails(String goalId) {
    return Consumer<GoalService>(
      builder: (context, goalService, child) {
        final goal = goalService.goals.firstWhere((g) => g.goalId == goalId);
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${goal.goalName} - 详细信息',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '目标总额: ¥${goal.targetAmount?.toStringAsFixed(0) ?? '0'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '已完成: ¥${goal.completedAmount.toStringAsFixed(0)} / ${((goal.completedAmount / (goal.targetAmount ?? 1)) * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[600],
                ),
              ),
              if (goal.subGoals.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '子目标数量: ${goal.subGoals.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              if (goal.subTasks.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  '子任务: ${goal.subTaskCompletedNum}/${goal.subTaskNum} 已完成',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLineChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '完成进度趋势',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                _buildTimeRangeSelector(),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _chartData.isEmpty
                      ? _buildEmptyLineChart()
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              horizontalInterval: _getMaxAmount() / 5,
                              verticalInterval: 1,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Colors.grey[300]!,
                                  strokeWidth: 1,
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return FlLine(
                                  color: Colors.grey[300]!,
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget: _getBottomTitles,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: _getMaxAmount() / 5,
                                  getTitlesWidget: _getLeftTitles,
                                  reservedSize: 60,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(color: Colors.grey[300]!, width: 1),
                            ),
                            minX: 0,
                            maxX: _chartData.length - 1.0,
                            minY: 0,
                            maxY: _getMaxAmount(),
                            lineBarsData: [
                              // 预计完成金额 (虚线)
                              LineChartBarData(
                                spots: _chartData.asMap().entries.map((entry) {
                                  return FlSpot(entry.key.toDouble(), entry.value['planned'] ?? 0.0);
                                }).toList(),
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                dashArray: [5, 5], // 虚线
                              ),
                              // 实际完成金额 (实线)
                              LineChartBarData(
                                spots: _chartData.asMap().entries.map((entry) {
                                  return FlSpot(entry.key.toDouble(), entry.value['completed'] ?? 0.0);
                                }).toList(),
                                isCurved: true,
                                color: Colors.green,
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
            ),
            const SizedBox(height: 16),
            _buildLineLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLineChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '完成进度趋势',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '完成任务后查看预计进度与实际进度的对比趋势',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).primaryColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['周', '月'].map((range) {
          final isSelected = _timeRange == range;
          return GestureDetector(
            onTap: () async {
              if (_timeRange != range) {
                setState(() {
                  _timeRange = range;
                  _isLoading = true;
                });
                await _loadChartData();
                setState(() {
                  _isLoading = false;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                range,
                style: TextStyle(
                  color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('预计完成', Colors.blue, true),
        const SizedBox(width: 24),
        _buildLegendItem('实际完成', Colors.green, false),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDashed) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? CustomPaint(
                  painter: DashedLinePainter(color),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  double _getMaxAmount() {
    if (_chartData.isEmpty) {
      debugPrint('图表数据为空，使用默认最大值');
      return 100.0;
    }
    
    double maxPlanned = _chartData.fold(0.0, (max, data) => 
        (data['planned'] ?? 0.0) > max ? (data['planned'] ?? 0.0) : max);
    double maxCompleted = _chartData.fold(0.0, (max, data) => 
        (data['completed'] ?? 0.0) > max ? (data['completed'] ?? 0.0) : max);
    
    double maxAmount = maxPlanned > maxCompleted ? maxPlanned : maxCompleted;
    debugPrint('计算最大金额: planned=$maxPlanned, completed=$maxCompleted, max=$maxAmount');
    return maxAmount > 0 ? maxAmount * 1.1 : 100.0; // 加10%的边距
  }

  Widget _getBottomTitles(double value, TitleMeta meta) {
    if (value.toInt() >= _chartData.length) return Container();
    
    final data = _chartData[value.toInt()];
    final date = data['date'] as DateTime;
    
    String text;
    switch (_timeRange) {
      case '周':
        text = '${date.month}/${date.day}';
        break;
      case '月':
        text = '${date.day}日';
        break;
      default:
        text = '${date.month}/${date.day}';
        break;
    }
    
    return Text(
      text,
      style: const TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    );
  }

  Widget _getLeftTitles(double value, TitleMeta meta) {
    return Text(
      '${(value / 1000).toStringAsFixed(0)}K',
      style: const TextStyle(
        color: Colors.grey,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
      textAlign: TextAlign.left,
    );
  }
}

// 自定义虚线绘制器
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3;

    const dashWidth = 3.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
} 