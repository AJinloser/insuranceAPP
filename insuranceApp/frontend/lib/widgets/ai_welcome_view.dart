import 'package:flutter/material.dart';
import '../models/dify_models.dart';

/// AI模块欢迎界面
/// 展示AI模块的基本信息，包括名称、开场白、开场推荐问题和用户输入表单
class AIWelcomeView extends StatefulWidget {
  final String moduleName;
  final AppParameters parameters;
  final Function(Map<String, String>) onSubmit;

  const AIWelcomeView({
    Key? key,
    required this.moduleName,
    required this.parameters,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<AIWelcomeView> createState() => _AIWelcomeViewState();
}

class _AIWelcomeViewState extends State<AIWelcomeView> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _selectedValues = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    if (widget.parameters.userInputForm != null) {
      for (var formItem in widget.parameters.userInputForm!) {
        if (formItem.textInput != null) {
          final config = formItem.textInput!;
          _controllers[config.variable] = TextEditingController(text: config.defaultValue ?? '');
        } else if (formItem.paragraph != null) {
          final config = formItem.paragraph!;
          _controllers[config.variable] = TextEditingController(text: config.defaultValue ?? '');
        } else if (formItem.select != null) {
          final config = formItem.select!;
          if (config.defaultValue != null && config.options!.contains(config.defaultValue)) {
            _selectedValues[config.variable] = config.defaultValue!;
          } else if (config.options != null && config.options!.isNotEmpty) {
            _selectedValues[config.variable] = config.options!.first;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模块名称
            Text(
              widget.moduleName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A), // 使用紫色主题
              ),
            ),
            const SizedBox(height: 16),
            
            // 开场白 - 只有在有内容时才显示
            if (widget.parameters.openingStatement != null && 
                widget.parameters.openingStatement!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7F6), // 使用浅紫色背景
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.parameters.openingStatement!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            
            // 建议问题
            if (widget.parameters.suggestedQuestions != null && 
                widget.parameters.suggestedQuestions!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '参考问题:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.parameters.suggestedQuestions!.map((question) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: InkWell(
                        onTap: () {
                          final Map<String, String> formData = {'question': question};
                          widget.onSubmit(formData);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF6A1B9A)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(question),
                        ),
                      ),
                    )
                  ).toList(),
                ],
              ),
            const SizedBox(height: 24),
            
            // 用户输入表单
            if (widget.parameters.userInputForm != null && 
                widget.parameters.userInputForm!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '请填写以下信息:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...widget.parameters.userInputForm!.map((formItem) {
                    if (formItem.textInput != null) {
                      return _buildTextInput(formItem.textInput!);
                    } else if (formItem.paragraph != null) {
                      return _buildParagraphInput(formItem.paragraph!);
                    } else if (formItem.select != null) {
                      return _buildSelectInput(formItem.select!);
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                ],
              ),
            
            // 文件上传支持
            if (widget.parameters.fileUpload?.image?.enabled == true)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: const [
                    Icon(Icons.file_upload, color: Color(0xFF6A1B9A)),
                    SizedBox(width: 8),
                    Text('支持文件上传'),
                  ],
                ),
              ),
              
            // 语音转文字支持
            if (widget.parameters.speechToText?.enabled == true)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: const [
                    Icon(Icons.mic, color: Color(0xFF6A1B9A)),
                    SizedBox(width: 8),
                    Text('支持语音输入'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput(TextInputConfig config) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _controllers[config.variable],
        decoration: InputDecoration(
          labelText: config.label,
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF6A1B9A)),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6A1B9A)),
        ),
        maxLength: config.maxLength,
      ),
    );
  }

  Widget _buildParagraphInput(ParagraphConfig config) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _controllers[config.variable],
        decoration: InputDecoration(
          labelText: config.label,
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF6A1B9A)),
          ),
          labelStyle: const TextStyle(color: Color(0xFF6A1B9A)),
        ),
        maxLines: 5,
      ),
    );
  }

  Widget _buildSelectInput(SelectConfig config) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6A1B9A)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedValues[config.variable],
                items: config.options?.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList() ?? [],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedValues[config.variable] = value;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
} 