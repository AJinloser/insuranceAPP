import 'package:flutter/material.dart';

/// 可滚动的Markdown表格组件
/// 
/// 该组件用于在移动端较窄的屏幕上显示表格内容，
/// 支持横向滚动以确保表格内容的完整展示
class ScrollableMarkdownTable extends StatelessWidget {
  /// 表格数据，第一行通常为表头
  final List<List<String>> tableData;
  
  /// 表格样式配置
  final TableStyle? style;
  
  /// 是否显示边框
  final bool showBorder;
  
  /// 是否启用横向滚动
  final bool enableHorizontalScroll;

  const ScrollableMarkdownTable({
    Key? key,
    required this.tableData,
    this.style,
    this.showBorder = true,
    this.enableHorizontalScroll = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tableData.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final effectiveStyle = style ?? TableStyle.defaultStyle(theme);
    
    final table = _buildTable(context, effectiveStyle);
    
    if (!enableHorizontalScroll) {
      return table;
    }
    
    // 包装在横向滚动视图中
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: table,
    );
  }

  /// 构建表格
  Widget _buildTable(BuildContext context, TableStyle style) {
    return Container(
      decoration: showBorder ? BoxDecoration(
        border: Border.all(
          color: style.borderColor,
          width: style.borderWidth,
        ),
        borderRadius: BorderRadius.circular(style.borderRadius),
      ) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(style.borderRadius),
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          children: tableData.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final rowData = entry.value;
            final isHeader = rowIndex == 0;
            
            return _buildTableRow(
              rowData,
              isHeader: isHeader,
              style: style,
              isEvenRow: rowIndex % 2 == 0,
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建表格行
  TableRow _buildTableRow(
    List<String> rowData, {
    required bool isHeader,
    required TableStyle style,
    required bool isEvenRow,
  }) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader 
            ? style.headerBackgroundColor
            : (isEvenRow ? style.evenRowColor : style.oddRowColor),
      ),
      children: rowData.map((cellData) => _buildTableCell(
        cellData,
        isHeader: isHeader,
        style: style,
      )).toList(),
    );
  }

  /// 构建表格单元格
  Widget _buildTableCell(
    String cellData, {
    required bool isHeader,
    required TableStyle style,
  }) {
    return Container(
      padding: style.cellPadding,
      decoration: showBorder ? BoxDecoration(
        border: Border.all(
          color: style.borderColor,
          width: 0.5,
        ),
      ) : null,
      child: Text(
        cellData.trim(),
        style: isHeader ? style.headerTextStyle : style.cellTextStyle,
        textAlign: TextAlign.left,
      ),
    );
  }
}

/// 表格样式配置类
class TableStyle {
  /// 表头背景色
  final Color headerBackgroundColor;
  
  /// 偶数行背景色
  final Color evenRowColor;
  
  /// 奇数行背景色
  final Color oddRowColor;
  
  /// 边框颜色
  final Color borderColor;
  
  /// 边框宽度
  final double borderWidth;
  
  /// 边框圆角
  final double borderRadius;
  
  /// 单元格内边距
  final EdgeInsets cellPadding;
  
  /// 表头文本样式
  final TextStyle headerTextStyle;
  
  /// 普通单元格文本样式
  final TextStyle cellTextStyle;

  const TableStyle({
    required this.headerBackgroundColor,
    required this.evenRowColor,
    required this.oddRowColor,
    required this.borderColor,
    required this.headerTextStyle,
    required this.cellTextStyle,
    this.borderWidth = 1.0,
    this.borderRadius = 8.0,
    this.cellPadding = const EdgeInsets.all(12.0),
  });

  /// 默认样式，与应用主题保持一致
  factory TableStyle.defaultStyle(ThemeData theme) {
    final primaryColor = theme.primaryColor;
    
    return TableStyle(
      headerBackgroundColor: primaryColor.withAlpha(25),
      evenRowColor: Colors.grey.withAlpha(13),
      oddRowColor: Colors.white,
      borderColor: Colors.grey.withAlpha(51),
      borderWidth: 1.0,
      borderRadius: 8.0,
      cellPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      headerTextStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.4,
      ),
      cellTextStyle: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
        height: 1.4,
      ),
    );
  }

  /// 紧凑样式，适用于数据较多的表格
  factory TableStyle.compactStyle(ThemeData theme) {
    return TableStyle.defaultStyle(theme).copyWith(
      cellPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      headerTextStyle: TableStyle.defaultStyle(theme).headerTextStyle.copyWith(fontSize: 13),
      cellTextStyle: TableStyle.defaultStyle(theme).cellTextStyle.copyWith(fontSize: 13),
    );
  }

  /// 复制并修改样式
  TableStyle copyWith({
    Color? headerBackgroundColor,
    Color? evenRowColor,
    Color? oddRowColor,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    EdgeInsets? cellPadding,
    TextStyle? headerTextStyle,
    TextStyle? cellTextStyle,
  }) {
    return TableStyle(
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      evenRowColor: evenRowColor ?? this.evenRowColor,
      oddRowColor: oddRowColor ?? this.oddRowColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      cellPadding: cellPadding ?? this.cellPadding,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      cellTextStyle: cellTextStyle ?? this.cellTextStyle,
    );
  }
}

/// 表格数据解析工具类
class MarkdownTableParser {
  /// 从Markdown表格文本解析表格数据
  static List<List<String>> parseMarkdownTable(String tableText) {
    final lines = tableText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final List<List<String>> tableData = [];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 跳过分割线（如：|---|---|---|）
      if (line.contains('---') || line.contains(':--') || line.contains('--:')) {
        continue;
      }
      
      // 解析表格行
      if (line.startsWith('|') && line.endsWith('|')) {
        final cells = line
            .substring(1, line.length - 1) // 移除首尾的 |
            .split('|')
            .map((cell) => cell.trim())
            .toList();
        
        if (cells.isNotEmpty) {
          tableData.add(cells);
        }
      }
    }
    
    return tableData;
  }

  /// 检测文本中是否包含Markdown表格
  static bool containsMarkdownTable(String text) {
    final lines = text.split('\n');
    int tableLineCount = 0;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('|') && trimmedLine.endsWith('|')) {
        tableLineCount++;
        if (tableLineCount >= 2) { // 至少需要两行才算表格
          return true;
        }
      } else if (trimmedLine.isEmpty) {
        continue; // 跳过空行
      } else {
        tableLineCount = 0; // 重置计数
      }
    }
    
    return false;
  }

  /// 从文本中提取所有表格
  static List<String> extractMarkdownTables(String text) {
    final List<String> tables = [];
    final lines = text.split('\n');
    List<String> currentTable = [];
    bool inTable = false;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      if (trimmedLine.startsWith('|') && trimmedLine.endsWith('|')) {
        if (!inTable) {
          inTable = true;
          currentTable = [];
        }
        currentTable.add(line);
      } else if (inTable) {
        // 表格结束
        if (currentTable.length >= 2) { // 至少两行才算有效表格
          tables.add(currentTable.join('\n'));
        }
        inTable = false;
        currentTable = [];
      }
    }
    
    // 处理文档末尾的表格
    if (inTable && currentTable.length >= 2) {
      tables.add(currentTable.join('\n'));
    }
    
    return tables;
  }
} 