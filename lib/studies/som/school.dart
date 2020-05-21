import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:better_som_today/data/bettersom_options.dart';
import 'package:better_som_today/layout/text_scale.dart';
import 'package:better_som_today/studies/som/colors.dart';
import 'package:better_som_today/studies/som/data.dart';
import 'package:better_som_today/studies/som/charts/vertical_fraction_bar.dart';
class FullRoosterView extends StatelessWidget {
  const FullRoosterView({
    this.heroLabel,
    this.heroAmount,
    this.wholeAmount,
    this.quickRoosterCards,
  });

  /// The amounts to assign each item.
  final String heroLabel;
  final double heroAmount;
  final double wholeAmount;
  final List<QuickItemView> quickRoosterCards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Column(
        children: [
          const SizedBox(height: 24),
          Container(
            height: 1,
            color: RallyColors.inputBackground,
          ),
          Container(
            color: RallyColors.cardBackground,
            child: Column(
              children: quickRoosterCards,
            ),
          ),
        ],
      );
    });
  }
}

class QuickItemView extends StatelessWidget {
  const QuickItemView({
    @required this.indicatorColor,
    @required this.indicatorFraction,
    @required this.title,
    @required this.subtitle,
    @required this.semanticsLabel,
    @required this.amount,
    @required this.suffix,
  });

  final Color indicatorColor;
  final double indicatorFraction;
  final String title;
  final String subtitle;
  final String semanticsLabel;
  final String amount;
  final Widget suffix;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics.fromProperties(
      properties: SemanticsProperties(
        button: true,
        label: semanticsLabel,
      ),
      excludeSemantics: true,
      child: FlatButton(
        onPressed: () {},
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    alignment: Alignment.center,
                    height: 32 + 60 * (cappedTextScale(context) - 1),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: VerticalFractionBar(
                      color: indicatorColor,
                      fraction: indicatorFraction,
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: textTheme.bodyText2.copyWith(fontSize: 16),
                            ),
                            Text(
                              subtitle,
                              style: textTheme.bodyText2
                                  .copyWith(color: RallyColors.gray60),
                            ),
                          ],
                        ),
                        Text(
                          amount,
                          style: textTheme.bodyText1.copyWith(
                            fontSize: 20,
                            color: RallyColors.gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: RallyColors.dividerColor,
            ),
          ],
        ),
      ),
    );
  }
}


QuickItemView buildQuickRoosterViewFromAccountData(
  QuickItemData model,
  int accountDataIndex,
  BuildContext context,
) {
  return QuickItemView(
    suffix: const Icon(Icons.chevron_right, color: Colors.grey),
    title: model.name,
    subtitle: model.subtitle,
    amount: model.caption,
    semanticsLabel: model.name,
    indicatorColor: RallyColors.accountColor(accountDataIndex),
    indicatorFraction: 1,
  );
}

List<QuickItemView> buildQuickRoosterListView(
  List<QuickItemData> items,
  BuildContext context,
) {
  return List<QuickItemView>.generate(
    items.length,
    (i) => buildQuickRoosterViewFromAccountData(items[i], i, context),
  );
}

QuickItemView buildQuickGradeViewFromAccountData(
  QuickItemData model,
  int accountDataIndex,
  BuildContext context,
) {
  return QuickItemView(
    suffix: const Icon(Icons.chevron_right, color: Colors.grey),
    title: model.name,
    amount: model.caption.toString(),
    subtitle: model.subtitle,
    semanticsLabel: model.name,
    indicatorColor: RallyColors.accountColor(accountDataIndex),
    indicatorFraction: 1,
  );
}

List<QuickItemView> buildQuickGradeListView(
  List<QuickItemData> items,
  BuildContext context,
) {
  return List<QuickItemView>.generate(
    items.length,
    (i) => buildQuickGradeViewFromAccountData(items[i], i, context),
  );
}


class FullRoosterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = false;

    return ApplyTextOptions(
      child: Scaffold(
        appBar: AppBar(
          leading: new Container(),
          elevation: 0,
          centerTitle: true,
          title: Text(
            'test',
            style: Theme.of(context).textTheme.bodyText2.copyWith(fontSize: 18),
          ),
        ),
        body: Column(
          children: [

            Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                
                  ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}