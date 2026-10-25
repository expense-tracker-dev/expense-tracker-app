import 'package:flutter/material.dart';

class MyMoneyHelpScreen extends StatelessWidget {
  const MyMoneyHelpScreen({super.key});

  static const Color backgroundColor = Color(0xFFFCF8EF);
  static const Color appBarColor = Color(0xFFE5E2D8);
  static const Color goldColor = Color(0xFFD9AA2B);
  static const Color darkGoldColor = Color(0xFF795900);
  static const Color textColor = Color(0xFF211F19);
  static const Color secondaryTextColor = Color(0xFF514939);
  static const Color mutedColor = Color(0xFF887D67);
  static const Color dividerColor = Color(0xFFE8E1D4);
  static const Color cardColor = Colors.white;

  static const List<Map<String, String>> faqs = [
    {
      'question': 'How can I export my DailyDhan reports?',
      'answer':
      'Open Export Reports from the app menu to access your financial report options. Select the report you want and choose the available date range. You can then generate your report and use the available export or sharing options to keep a copy of your financial information for personal reference.',
    },
    {
      'question': 'How does Money Forecast work in DailyDhan?',
      'answer':
      'Money Forecast helps you understand how your balance may change in the future based on your financial information. It uses available balance, income, expenses, and spending patterns to provide an estimate. The forecast is intended to support planning and should not be treated as a guarantee of your future balance.',
    },
    {
      'question': 'How can I use Cash Calculator?',
      'answer':
      'Open Cash Calculator and enter the quantity of each currency note you have. The calculator multiplies each denomination by its quantity and adds the results to calculate your total cash amount. Check the quantities before completing the calculation so that the displayed total matches the cash you have counted.',
    },
    {
      'question': 'How can I manage my accounts in DailyDhan?',
      'answer':
      'Open the Accounts section to view your available money sources, including Card, Cash, and Savings. The screen displays balances calculated from transactions associated with those accounts. You can also view any previously saved custom accounts. Account balances help you understand how your money is distributed across different sources.',
    },
  ];

  static const List<Map<String, String>> basics = [
    {
      'question': 'What do budgets mean in DailyDhan?',
      'answer':
      'Budgets help you plan and monitor your spending over a selected period or category. A budget allows you to set a spending limit and compare your expenses against that amount. Reviewing your budget regularly can help you understand how much you have spent, how much remains, and where you may need to control your spending.',
    },
    {
      'question': 'What does a category mean in DailyDhan?',
      'answer':
      'A category groups similar transactions so that your income and expenses are easier to understand. For example, expenses may belong to Food, Shopping, Travel, or Bills, while income may belong to Salary or other income categories. Choosing an appropriate category when recording a transaction helps you review your spending patterns and understand where your money goes.',
    },
    {
      'question': 'What does an account represent in DailyDhan?',
      'answer':
      'An account represents a source from which your money is available or managed. DailyDhan includes sources such as Card, Cash, and Savings, and the balance shown for each source depends on its associated transactions. Selecting the correct account while recording income or expenses helps you keep account balances organised and understand how money moves between your available sources.',
    },
    {
      'question': 'What is a transaction record in DailyDhan?',
      'answer':
      'A transaction record stores the details of a financial activity entered into DailyDhan. It can represent either income, such as money received, or an expense, such as money spent. A record includes details such as the amount, category, account, date, and description, depending on the information entered. These records help you review your financial activity and analyse your income and expenses.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        foregroundColor: darkGoldColor,
        elevation: 0,
        title: const Text(
          'DailyDhan Help',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          _buildSectionTitle('FAQs'),
          const SizedBox(height: 8),
          ...faqs.map(_buildQuestionTile),
          const SizedBox(height: 32),
          _buildSectionTitle('Basics'),
          const SizedBox(height: 8),
          ...basics.map(_buildQuestionTile),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: textColor,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildQuestionTile(Map<String, String> item) {
    return Column(
      children: [
        Theme(
          data: ThemeData(
            dividerColor: Colors.transparent,
            splashColor: goldColor.withValues(alpha: 0.08),
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            key: PageStorageKey<String>(item['question']!),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 5,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(60, 0, 12, 18),
            leading: const Icon(
              Icons.help_outline_rounded,
              color: darkGoldColor,
              size: 34,
            ),
            iconColor: darkGoldColor,
            collapsedIconColor: mutedColor,
            title: Text(
              item['question']!,
              style: const TextStyle(
                color: textColor,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item['answer']!,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.65,
                    letterSpacing: 0.05,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(
          color: dividerColor,
          thickness: 1,
          height: 1,
        ),
      ],
    );
  }
}