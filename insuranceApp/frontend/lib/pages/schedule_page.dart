import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';
import '../widgets/schedule_item_card.dart';

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
          // 日历组件
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
                    ? _buildEmptyState()
                    : _buildScheduleList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '这一天没有安排',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '选择其他日期查看安排',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
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