import 'package:dnd/classes/wiki_classes.dart';
import 'package:dnd/configs/colours.dart';
import 'package:dnd/views/wiki/background_view.dart';
import 'package:dnd/views/wiki/classes_view.dart';
import 'package:dnd/views/wiki/feat_view.dart';
import 'package:dnd/views/wiki/races_view.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:dnd/l10n/app_localizations.dart';

class RacePage extends StatelessWidget {
  final List<RaceData> races;

  const RacePage({super.key, required this.races});

  @override
  Widget build(BuildContext context) {
    final List<RaceData> sortedRaces = List.from(races)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.chooserace)),
      body: ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: sortedRaces.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final race = sortedRaces[index];
          return ListTile(
            title: Text(race.name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      RaceDetailPage(raceData: race, characterCreator: true),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ClassPage extends StatelessWidget {
  final List<ClassData> classes;

  const ClassPage({super.key, required this.classes});

  @override
  Widget build(BuildContext context) {
    final List<ClassData> sortedClasses = List.from(classes)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.chooseclass)),
      body: ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: sortedClasses.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final classData = sortedClasses[index];
          return ListTile(
            title: Text(classData.name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClassDetailPage(
                    classData: classData,
                    characterCreator: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BackgroundPage extends StatelessWidget {
  final List<BackgroundData> backgrounds;

  const BackgroundPage({super.key, required this.backgrounds});

  @override
  Widget build(BuildContext context) {
    final List<BackgroundData> sortedBackgrounds = List.from(backgrounds)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar:
          AppBar(title: Text(AppLocalizations.of(context)!.choosebackground)),
      body: ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: sortedBackgrounds.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          if (index == 0) {}
          final background = sortedBackgrounds[index];
          return ListTile(
            title: Text(background.name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BackgroundDetailPage(
                    backgroundData: background,
                    characterCreator: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FeatPage extends StatelessWidget {
  final List<FeatData> feats;

  const FeatPage({super.key, required this.feats});

  @override
  Widget build(BuildContext context) {
    final List<FeatData> sortedFeats = List.from(feats)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.choosefeat)),
      body: ListView.separated(
        padding: const EdgeInsets.all(12.0),
        itemCount: sortedFeats.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final feat = sortedFeats[index];
          return ListTile(
            title: Text(feat.name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FeatDetailPage(
                    featData: feat,
                    characterCreator: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AbilityScoresPage extends StatefulWidget {
  final String bonusInput;
  const AbilityScoresPage({super.key, this.bonusInput = ""});

  @override
  State<AbilityScoresPage> createState() => _AbilityScoresPageState();
}

class _AbilityScoresPageState extends State<AbilityScoresPage> {
  final List<String> abilities = ["STR", "DEX", "CON", "INT", "WIS", "CHA"];
  final List<int> standardArray = [15, 14, 13, 12, 10, 8];
  final Map<String, int> abilityScores = {};
  String selectedMethod = "Standard Array";
  List<int> rolledValues = [];

  final List<String> methods = [
    "Standard Array",
    "Point Buy",
    "Roll 4d6 Drop Lowest",
    "Custom"
  ];

  // Point Buy
  int pointBuyPool = 27;
  final Map<String, int> pointBuyScores = {
    "STR": 8,
    "DEX": 8,
    "CON": 8,
    "INT": 8,
    "WIS": 8,
    "CHA": 8,
  };

  int calculatePointCost(int score) {
    if (score < 8 || score > 15) return 0;
    return [0, 1, 2, 3, 4, 5, 7, 9][score - 8];
  }

  int roll4d6DropLowest() {
    List<int> rolls = List.generate(4, (_) => Random().nextInt(6) + 1);
    rolls.sort();
    return rolls.sublist(1).reduce((a, b) => a + b);
  }

  void rollStats() {
    setState(() {
      rolledValues = List.generate(6, (_) => roll4d6DropLowest());
      abilityScores.clear();
      for (var ability in abilities) {
        abilityScores[ability] = -1;
      }
    });
  }

  List<int> parsedBonuses = [];
  Map<int, String> bonusAssignments = {};

  void parseBonuses(String input) {
    final regex = RegExp(r'([a-zA-Z]{3})\s*(\d)');
    final matches = regex.allMatches(input);

    parsedBonuses.clear();
    for (var match in matches) {
      int bonus = int.parse(match.group(2)!);
      parsedBonuses.add(bonus);
    }

    bonusAssignments.clear();
  }

  @override
  void initState() {
    super.initState();
    parseBonuses(widget.bonusInput);

    if (selectedMethod == "Standard Array") {
      for (int i = 0; i < abilities.length; i++) {
        abilityScores[abilities[i]] = standardArray[i];
      }
    }
  }

  int getBonusForAbility(String ability) {
    int totalBonus = 0;
    bonusAssignments.forEach((index, assignedAbility) {
      if (assignedAbility == ability) {
        totalBonus += parsedBonuses[index];
      }
    });
    return totalBonus;
  }

  Widget buildStandardArray() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: abilities.map((ability) {
        int baseScore = abilityScores[ability] ?? 0;
        int bonus = getBonusForAbility(ability);
        int total = baseScore + bonus;

        final dropdownOptions = List<int>.from(standardArray)..sort();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: screenWidth * 0.15,
                child: Text(getLocalizedAbilityName(ability)),
              ),
              SizedBox(width: screenWidth * 0.05),
              SizedBox(
                width: screenWidth * 0.25,
                child: DropdownButton<int>(
                  dropdownColor: AppColors.cardColor,
                  isExpanded: true,
                  value: baseScore == 0 ? null : baseScore,
                  hint: Text("Select value"),
                  items: dropdownOptions
                      .map((val) => DropdownMenuItem<int>(
                            value: val,
                            child: Text(val.toString()),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        abilityScores.forEach((key, value) {
                          if (key != ability && value == val) {
                            abilityScores[key] = 0;
                          }
                        });
                        abilityScores[ability] = val;
                      });
                    }
                  },
                ),
              ),
              SizedBox(width: screenWidth * 0.05),
              SizedBox(
                width: screenWidth * 0.1,
                child: Text("+$bonus", textAlign: TextAlign.right),
              ),
              SizedBox(width: screenWidth * 0.05),
              SizedBox(
                width: screenWidth * 0.15,
                child: Text("= $total", textAlign: TextAlign.right),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildPointBuy() {
    int usedPoints = pointBuyScores.values
        .map((s) => calculatePointCost(s))
        .reduce((a, b) => a + b);

    return Column(
      children: abilities.map((ability) {
        int baseScore = pointBuyScores[ability] ?? 8;
        int bonus = getBonusForAbility(ability);
        int total = baseScore + bonus;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text("${getLocalizedAbilityName(ability)}: $baseScore"),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      if (pointBuyScores[ability]! > 8) {
                        setState(() {
                          pointBuyScores[ability] =
                              pointBuyScores[ability]! - 1;
                        });
                      }
                    },
                    icon: const Icon(Icons.remove),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                  IconButton(
                    onPressed: () {
                      int current = pointBuyScores[ability]!;
                      int newCost = calculatePointCost(current + 1);
                      int oldCost = calculatePointCost(current);
                      if (current < 15 &&
                          (usedPoints - oldCost + newCost) <= pointBuyPool) {
                        setState(() {
                          pointBuyScores[ability] = current + 1;
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 40,
                child: Text("+$bonus", textAlign: TextAlign.right),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 60,
                child: Text("= $total", textAlign: TextAlign.right),
              ),
            ],
          ),
        );
      }).toList()
        ..add(
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!
                    .usedpoints(usedPoints, pointBuyPool)),
              ],
            ),
          ),
        ),
    );
  }

  Widget buildCustom() {
    return Column(
      children: abilities.map((ability) {
        int baseScore = abilityScores[ability] ?? 0;
        int bonus = getBonusForAbility(ability);
        int total = baseScore + bonus;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: baseScore == 0 ? "" : baseScore.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: getLocalizedAbilityName(ability)),
                onChanged: (val) {
                  setState(() {
                    abilityScores[ability] = int.tryParse(val) ?? 0;
                  });
                },
              ),
            ),
            Text("+$bonus"),
            Text("= $total"),
          ],
        );
      }).toList(),
    );
  }

  Widget buildRolled() {
    final screenWidth = MediaQuery.of(context).size.width;
    final loc = AppLocalizations.of(context)!;

    String rolledDisplay =
        rolledValues.isEmpty ? loc.notrolledyet : rolledValues.join(", ");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.casino),
              tooltip: loc.rollAllTooltip,
              onPressed: rollStats,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                loc.rolledstats(rolledDisplay),
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          loc.assignRolledValues,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...abilities.map((ability) {
          int assignedRoll = abilityScores[ability] ?? -1;
          int bonus = getBonusForAbility(ability);
          int total = (assignedRoll == -1) ? 0 : assignedRoll + bonus;

          List<int> assignedRolls = abilityScores.entries
              .where((entry) => entry.key != ability && entry.value != -1)
              .map((entry) => entry.value)
              .toList();

          final dropdownOptionsSet = <int>{};
          if (assignedRoll != -1) dropdownOptionsSet.add(assignedRoll);
          dropdownOptionsSet.addAll(
            rolledValues.where(
                (val) => !assignedRolls.contains(val) || val == assignedRoll),
          );
          final dropdownOptions = List<int>.from(rolledValues)..sort();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: screenWidth * 0.15,
                  child: Text(getLocalizedAbilityName(ability)),
                ),
                SizedBox(width: screenWidth * 0.05),
                SizedBox(
                  width: screenWidth * 0.25,
                  child: DropdownButton<int>(
                    dropdownColor: AppColors.cardColor,
                    isExpanded: true,
                    value: assignedRoll == -1 ? null : assignedRoll,
                    hint: Text(loc.roll),
                    items: dropdownOptions.map((val) {
                      return DropdownMenuItem<int>(
                        value: val,
                        child: Text(val.toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          abilityScores.forEach((key, value) {
                            if (key != ability && value == val) {
                              abilityScores[key] = -1;
                            }
                          });
                          abilityScores[ability] = val;
                        });
                      }
                    },
                  ),
                ),
                SizedBox(width: screenWidth * 0.05),
                SizedBox(
                  width: screenWidth * 0.1,
                  child: Text("+$bonus", textAlign: TextAlign.right),
                ),
                SizedBox(width: screenWidth * 0.05),
                SizedBox(
                  width: screenWidth * 0.15,
                  child: Text("= $total", textAlign: TextAlign.right),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget buildBonusAssignment() {
    if (parsedBonuses.isEmpty) return const SizedBox();

    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth * 0.6;
    final loc = AppLocalizations.of(context)!;

    return Center(
      child: SizedBox(
        width: contentWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              loc.assignRacialBonuses,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...parsedBonuses.asMap().entries.map((entry) {
              int index = entry.key;
              int bonus = entry.value;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: contentWidth * 0.15,
                      child: Text(
                        "+$bonus",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    SizedBox(width: contentWidth * 0.05),
                    SizedBox(
                      width: contentWidth * 0.4,
                      child: DropdownButtonFormField<String>(
                        dropdownColor: AppColors.cardColor,
                        value: bonusAssignments[index],
                        hint: Text(loc.bonus),
                        isExpanded: true,
                        items: abilities
                            .map((a) =>
                                DropdownMenuItem(value: a, child: Text(a)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              bonusAssignments[index] = val;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget buildMethodWidget() {
    final loc = AppLocalizations.of(context)!;
    switch (selectedMethod) {
      case "Standard Array":
        return buildStandardArray();
      case "Point Buy":
        return buildPointBuy();
      case "Roll 4d6 Drop Lowest":
        return buildRolled();
      case "Custom":
        return buildCustom();
      default:
        return Text(loc.selectMethodHint);
    }
  }

  void confirmScores() {
    final loc = AppLocalizations.of(context)!;
    Map<String, int> finalScores = selectedMethod == "Point Buy"
        ? Map<String, int>.from(pointBuyScores)
        : Map<String, int>.from(abilityScores);

    for (var entry in bonusAssignments.entries) {
      finalScores.update(
          entry.value, (value) => value + parsedBonuses[entry.key],
          ifAbsent: () => parsedBonuses[entry.key]);
    }

    if (finalScores.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseAssignAll)),
      );
      return;
    }

    Navigator.pop(context, finalScores);
  }

  String getLocalizedAbilityName(String ability) {
    final loc = AppLocalizations.of(context)!;
    switch (ability) {
      case "STR":
        return loc.strengthShort;
      case "DEX":
        return loc.dexterityShort;
      case "CON":
        return loc.constitutionShort;
      case "INT":
        return loc.intelligenceShort;
      case "WIS":
        return loc.wisdomShort;
      case "CHA":
        return loc.charismaShort;
      default:
        return ability;
    }
  }

  String getLocalizedMethodName(String method) {
    final loc = AppLocalizations.of(context)!;
    switch (method) {
      case "Standard Array":
        return loc.standardArray;
      case "Point Buy":
        return loc.pointBuy;
      case "Roll 4d6 Drop Lowest":
        return loc.roll4d6;
      case "Custom":
        return loc.custom;
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.setabilityscores),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: confirmScores,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              dropdownColor: AppColors.cardColor,
              value: selectedMethod,
              items: methods
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(getLocalizedMethodName(m)),
                      ))
                  .toList(),
              onChanged: (val) => setState(() {
                selectedMethod = val!;
                if (selectedMethod == "Standard Array") {
                  for (int i = 0; i < abilities.length; i++) {
                    abilityScores[abilities[i]] = standardArray[i];
                  }
                }
                if (selectedMethod == "Point Buy") {
                  for (var ability in abilities) {
                    pointBuyScores[ability] = 8;
                  }
                }
                if (selectedMethod == "Custom" ||
                    selectedMethod == "Roll 4d6 Drop Lowest") {
                  abilityScores.clear();
                }
                bonusAssignments.clear();
              }),
            ),
            const SizedBox(height: 16),
            buildMethodWidget(),
            buildBonusAssignment(),
          ],
        ),
      ),
    );
  }
}
