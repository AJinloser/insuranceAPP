import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'scrollable_markdown_table.dart';

/// 自定义的MarkdownBody包装器
/// 
/// 该组件扩展了标准的MarkdownBody功能，
/// 支持横向滚动的表格渲染，同时保持其他markdown功能不变
class CustomMarkdownBody extends StatelessWidget {
  /// Markdown内容
  final String data;
  
  /// 是否可选择文本
  final bool selectable;
  
  /// Markdown样式表
  final MarkdownStyleSheet? styleSheet;
  
  /// 表格样式配置
  final TableStyle? tableStyle;
  
  /// 是否启用表格横向滚动（默认启用）
  final bool enableTableHorizontalScroll;

  const CustomMarkdownBody({
    Key? key,
    required this.data,
    this.selectable = false,
    this.styleSheet,
    this.tableStyle,
    this.enableTableHorizontalScroll = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 检查是否包含表格
    if (!enableTableHorizontalScroll || !MarkdownTableParser.containsMarkdownTable(data)) {
      // 如果不包含表格或不启用横向滚动，使用标准MarkdownBody
      return MarkdownBody(
        data: data,
        selectable: selectable,
        styleSheet: styleSheet,
      );
    }

    // 处理包含表格的内容
    return _buildMarkdownWithCustomTables(context);
  }

  /// 构建包含自定义表格的Markdown内容
  Widget _buildMarkdownWithCustomTables(BuildContext context) {
    // 提取表格内容
    final tables = MarkdownTableParser.extractMarkdownTables(data);
    
    if (tables.isEmpty) {
      // 没有找到有效表格，使用标准渲染
      return MarkdownBody(
        data: data,
        selectable: selectable,
        styleSheet: styleSheet,
      );
    }

    // 分割内容：将表格与其他内容分开处理
    return _buildMixedContent(context, tables);
  }

  /// 构建混合内容（文本 + 自定义表格）
  Widget _buildMixedContent(BuildContext context, List<String> tables) {
    final List<Widget> widgets = [];
    String remainingText = data;

    // 为每个表格创建占位符
    final Map<String, Widget> tableWidgets = {};
    for (int i = 0; i < tables.length; i++) {
      final tableText = tables[i];
      final placeholder = '___TABLE_PLACEHOLDER_${i}___';
      
      // 解析表格数据
      final tableData = MarkdownTableParser.parseMarkdownTable(tableText);
      if (tableData.isNotEmpty) {
        // 创建自定义表格组件
        tableWidgets[placeholder] = Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ScrollableMarkdownTable(
            tableData: tableData,
            style: tableStyle ?? TableStyle.defaultStyle(Theme.of(context)),
            enableHorizontalScroll: enableTableHorizontalScroll,
          ),
        );
        
        // 替换原文中的表格为占位符
        remainingText = remainingText.replaceFirst(tableText, placeholder);
      }
    }

    // 按占位符分割文本
    final parts = _splitTextByPlaceholders(remainingText, tableWidgets.keys.toList());
    
    for (final part in parts) {
      if (tableWidgets.containsKey(part)) {
        // 这是一个表格占位符
        widgets.add(tableWidgets[part]!);
      } else if (part.trim().isNotEmpty) {
        // 这是文本内容
        widgets.add(
          MarkdownBody(
            data: part,
            selectable: selectable,
            styleSheet: styleSheet,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// 按占位符分割文本
  List<String> _splitTextByPlaceholders(String text, List<String> placeholders) {
    if (placeholders.isEmpty) {
      return [text];
    }

    List<String> result = [text];
    
    for (final placeholder in placeholders) {
      final List<String> newResult = [];
      
      for (final part in result) {
        if (part.contains(placeholder)) {
          final splitParts = part.split(placeholder);
          for (int i = 0; i < splitParts.length; i++) {
            if (splitParts[i].isNotEmpty) {
              newResult.add(splitParts[i]);
            }
            if (i < splitParts.length - 1) {
              newResult.add(placeholder);
            }
          }
        } else {
          newResult.add(part);
        }
      }
      
      result = newResult;
    }
    
    return result.where((part) => part.isNotEmpty).toList();
  }
}

/// 增强版CustomMarkdownBody，支持更多自定义功能
class EnhancedMarkdownBody extends StatelessWidget {
  /// Markdown内容
  final String data;
  
  /// 是否可选择文本
  final bool selectable;
  
  /// Markdown样式表
  final MarkdownStyleSheet? styleSheet;
  
  /// 表格配置
  final TableConfig? tableConfig;
  
  /// 点击链接回调
  final void Function(String text, String? href, String title)? onTapLink;

  const EnhancedMarkdownBody({
    Key? key,
    required this.data,
    this.selectable = false,
    this.styleSheet,
    this.tableConfig,
    this.onTapLink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = tableConfig ?? TableConfig.defaultConfig(context);
    
    return CustomMarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: styleSheet,
      tableStyle: config.style,
      enableTableHorizontalScroll: config.enableHorizontalScroll,
    );
  }
}

/// 表格配置类
class TableConfig {
  /// 表格样式
  final TableStyle style;
  
  /// 是否启用横向滚动
  final bool enableHorizontalScroll;
  
  /// 最大表格宽度（可选）
  final double? maxWidth;

  const TableConfig({
    required this.style,
    this.enableHorizontalScroll = true,
    this.maxWidth,
  });

  /// 默认配置
  factory TableConfig.defaultConfig(BuildContext context) {
    return TableConfig(
      style: TableStyle.defaultStyle(Theme.of(context)),
      enableHorizontalScroll: true,
    );
  }

  /// 紧凑配置
  factory TableConfig.compactConfig(BuildContext context) {
    return TableConfig(
      style: TableStyle.compactStyle(Theme.of(context)),
      enableHorizontalScroll: true,
    );
  }
} 