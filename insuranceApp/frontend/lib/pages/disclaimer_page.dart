import 'package:flutter/material.dart';

class DisclaimerPage extends StatelessWidget {
  const DisclaimerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('免责声明'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildIntroduction(),
                const SizedBox(height: 24),
                _buildSection('一、平台性质', _getPlatformNature()),
                const SizedBox(height: 20),
                _buildSection('二、信息内容与局限性', _getInformationLimitations()),
                const SizedBox(height: 20),
                _buildSection('三、用户责任与风险自担', _getUserResponsibility()),
                const SizedBox(height: 20),
                _buildSection('四、责任限制', _getLiabilityLimitation()),
                const SizedBox(height: 20),
                _buildSection('五、建议与确认', _getSuggestionsAndConfirmation()),
                const SizedBox(height: 24),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.gavel_outlined,
          size: 32,
          color: Colors.orange.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '免责声明',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '最后更新：${DateTime.now().year}年${DateTime.now().month}月${DateTime.now().day}日',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntroduction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Text(
        '欢迎使用本金融知识智能体（以下简称"本平台"）。在您使用本平台之前，请您仔细阅读并充分理解以下免责声明。您对本平台的访问、咨询或使用即代表您已阅读、知悉并完全同意本声明的所有条款。',
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green.shade600,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '感谢您的理解与使用。请您理性判断，审慎决策。',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPlatformNature() {
    return '''本平台是一个旨在普及金融知识、提供信息参考的公益性、非营利性人工智能工具。本平台由技术团队独立开发与维护，与任何金融机构、产品发行方、投资顾问公司等商业实体均无任何股权关联、商业合作或经济利益关系。我们的首要和核心目标是保持内容的客观性与中立性，不倾向于任何特定的商业机构或其产品。''';
  }

  String _getInformationLimitations() {
    return '''本平台基于公开可得的金融信息、市场数据及算法模型生成回答，所提供的所有信息，包括但不限于对金融产品的解读、分析、比较、示例或策略，仅供您作为金融知识学习和投资决策的参考依据之一，并不构成以下任何形式的建议：

1. 对任何金融产品或服务的购买、出售、持有或其他任何交易行为的明确推荐或要约；

2. 任何形式的投资建议、财务规划建议或法律建议；

3. 对任何投资策略或产品未来表现的保证或承诺。

金融市场存在固有风险，信息动态变化且可能延迟。尽管我们力求信息的准确与客观，但本平台无法保证所有信息的绝对准确性、完整性、及时性或有效性。''';
  }

  String _getUserResponsibility() {
    return '''金融投资决策涉及个人风险偏好、资产状况、投资目标等多重因素，是一项高度个人化的行为。您基于本平台提供的信息所做出的任何决策和行为，均应是您独立判断和审慎考虑的结果。

您必须意识到，所有投资理财活动均存在风险，包括但不限于本金损失的风险。市场的波动性意味着投资价值可能上涨也可能下跌。

您应自行承担由您的投资决策和行为所引致的全部后果和风险。''';
  }

  String _getLiabilityLimitation() {
    return '''本平台及其开发团队、所有者、运营方均不对您因使用或无法使用本平台提供的信息而导致的任何形式的直接或间接损失承担法律责任，包括但不限于利润损失、数据丢失、交易中断、或其他经济损害。

对于任何依赖本平台信息所作出的投资决策、采取的行动或造成的后果，本平台及相关各方均不承担任何法律责任、担保责任或补偿责任。''';
  }

  String _getSuggestionsAndConfirmation() {
    return '''我们强烈建议您：

• 将本平台的信息作为多种信息来源之一进行交叉验证。

• 在进行任何投资决策前，咨询独立的、持牌的专业金融顾问，以获得符合您个人情况的专业意见。

• 仔细阅读相关金融产品的官方法律文件（如产品说明书、募集说明书、合同条款等）。''';
  }
}
