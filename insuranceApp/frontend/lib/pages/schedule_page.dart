import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';
import '../widgets/schedule_item_card.dart';
import '../widgets/guidance_widgets.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<Goal> _scheduleGoals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 延迟到build完成后再加载数据，避免在build期间触发setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScheduleData();
    });
  }

  Future<void> _loadScheduleData() async {
    setState(() {
      _isLoading = true;
    });
    
    final goalService = Provider.of<GoalService>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    
    try {
      final goals = await goalService.getGoalsByDate(context, dateStr);
      setState(() {
        _scheduleGoals = goals;
      });
    } catch (e) {
      debugPrint('加载日程数据失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _loadScheduleData();
    }
  }

  Future<void> _updateDate({
    required String type,
    required String goalId,
    String? subGoalId,
    String? subTaskId,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      final goalService = Provider.of<GoalService>(context, listen: false);
      final dateStr = DateFormat('yyyy-MM-dd').format(picked);
      
      final success = await goalService.updateDate(
        context,
        type: type,
        goalId: goalId,
        subGoalId: subGoalId,
        subTaskId: subTaskId,
        date: dateStr,
      );
      
      if (success) {
        _loadScheduleData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日期修改成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(goalService.error ?? '日期修改失败')),
        );
      }
    }
  }

  Future<void> _updateSubTaskStatus(String goalId, String subTaskId, bool status) async {
    final goalService = Provider.of<GoalService>(context, listen: false);
    
    final success = await goalService.updateSubTaskStatus(
      context,
      goalId: goalId,
      subTaskId: subTaskId,
      status: status,
    );
    
    if (success) {
      _loadScheduleData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(goalService.error ?? '更新任务状态失败')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // 引导性内容（仅在空状态时显示，且高度受限）
          if (_scheduleGoals.isEmpty && !_isLoading)
            SizedBox(
              height: 180, // 限制引导内容高度
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildScheduleGuidanceHeader(),
              ),
            ),
          
          // 日历组件（始终显示）
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar<Goal>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
                rightChevronIcon: Icon(Icons.chevron_right, color: primaryColor),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: Colors.red),
                outsideDaysVisible: false,
              ),
            ),
          ),
          
          // 选中日期显示
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_selectedDay.year}年${_selectedDay.month}月${_selectedDay.day}日的安排',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 目标列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _scheduleGoals.isEmpty
                    ? _buildEmptyStateWithGuidance()
                    : _buildScheduleList(),
          ),
        ],
      ),
    );
  }


  /// 构建日程页面的头部引导内容
  Widget _buildScheduleGuidanceHeader() {
    return GuidanceWidgets.buildFeaturesCard(
      title: '日程管理功能',
      features: [
        FeatureItem(
          icon: Icons.calendar_month,
          title: '日程查看',
          description: '通过日历选择日期，查看当天的目标和任务安排',
          color: Colors.blue,
        ),
        FeatureItem(
          icon: Icons.edit_calendar,
          title: '日期调整',
          description: '右滑任务可修改截止日期，灵活调整计划',
          color: Colors.green,
        ),
        FeatureItem(
          icon: Icons.check_circle,
          title: '任务完成',
          description: '点击复选框标记任务完成，实时更新进度',
          color: Colors.orange,
        ),
      ],
    );
  }

  /// 构建空状态时的引导
  Widget _buildEmptyStateWithGuidance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 操作指引
          GuidanceWidgets.buildHelpTipCard(
            title: '如何使用日程管理',
            description: '1. 先在"目标"页面创建目标和任务\n2. 选择日历上的日期查看当天安排\n3. 右滑任务可修改日期，点击复选框完成任务',
            icon: Icons.help_outline,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 20),
          
          // 空状态显示
          GuidanceWidgets.buildEmptyStateGuidance(
            icon: Icons.event_busy,
            title: '这一天没有安排',
            subtitle: '选择其他日期查看安排，或者前往"目标"页面添加新的目标和任务',
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList() {
    return RefreshIndicator(
      onRefresh: _loadScheduleData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _scheduleGoals.length,
        itemBuilder: (context, index) {
          final goal = _scheduleGoals[index];
          return ScheduleItemCard(
            goal: goal,
            onUpdateDate: _updateDate,
            onUpdateSubTaskStatus: _updateSubTaskStatus,
          );
        },
      ),
    );
  }
} 