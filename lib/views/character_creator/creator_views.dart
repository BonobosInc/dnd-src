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
  final Map<String, int>? initialAbilityScores;
  final String? initialMethod;
  final List<int>? initialRolledValues;
  final Map<String, int>? initialRolledAssignments;
  final Map<int, String>? initialBonusAssignments;
  final Map<String, int>? initialPointBuyScores;

  const AbilityScoresPage({
    super.key,
    this.bonusInput = "",
    this.initialAbilityScores,
    this.initialMethod,
    this.initialRolledValues,
    this.initialRolledAssignments,
    this.initialBonusAssignments,
    this.initialPointBuyScores,
  });

  @override
  State<AbilityScoresPage> createState() => _AbilityScoresPageState();
}

class _AbilityScoresPageState extends State<AbilityScoresPage> {
  final List<String> abilities = ["STR", "DEX", "CON", "INT", "WIS", "CHA"];
  final List<int> standardArray = [15, 14, 13, 12, 10, 8];
  late Map<String, int> abilityScores;
  late String selectedMethod;
  late List<int> rolledValues;
  late Map<String, int> rolledAssignments;

  final List<String> methods = [
    "Standard Array",
    "Point Buy",
    "Roll 4d6 Drop Lowest",
    "Custom"
  ];

  // Point Buy
  int pointBuyPool = 27;
  late Map<String, int> pointBuyScores;

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
      rolledAssignments.clear();
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
  }

  @override
  void initState() {
    super.initState();
    parseBonuses(widget.bonusInput);

    selectedMethod = widget.initialMethod ?? "Standard Array";
    abilityScores = widget.initialAbilityScores != null
        ? Map<String, int>.from(widget.initialAbilityScores!)
        : {};
    rolledValues = widget.initialRolledValues != null
        ? List<int>.from(widget.initialRolledValues!)
        : [];
    rolledAssignments = widget.initialRolledAssignments != null
        ? Map<String, int>.from(widget.initialRolledAssignments!)
        : {};
    bonusAssignments = widget.initialBonusAssignments != null
        ? Map<int, String>.from(widget.initialBonusAssignments!)
        : {};
    pointBuyScores = widget.initialPointBuyScores != null
        ? Map<String, int>.from(widget.initialPointBuyScores!)
        : {
            for (var ability in abilities) ability: 8,
          };

    if (widget.initialAbilityScores == null &&
        selectedMethod == "Standard Array") {
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
          int assignedIndex = rolledAssignments[ability] ?? -1;
          int assignedRoll = assignedIndex != -1 ? rolledValues[assignedIndex] : -1;
          int bonus = getBonusForAbility(ability);
          int total = (assignedRoll == -1) ? 0 : assignedRoll + bonus;

          Set<int> usedIndices = rolledAssignments.entries
              .where((entry) => entry.key != ability)
              .map((entry) => entry.value)
              .toSet();

          List<MapEntry<int, int>> indexedOptions = rolledValues
              .asMap()
              .entries
              .toList()
            ..sort((a, b) => a.value.compareTo(b.value));

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
                    value: assignedIndex == -1 ? null : assignedIndex,
                    hint: Text(loc.roll),
                    items: indexedOptions.map((entry) {
                      bool isUsed = usedIndices.contains(entry.key);
                      return DropdownMenuItem<int>(
                        value: entry.key,
                        enabled: !isUsed,
                        child: Text(
                          entry.value.toString(),
                          style: isUsed
                              ? TextStyle(color: Colors.grey)
                              : null,
                        ),
                      );
                    }).toList(),
                    onChanged: (idx) {
                      if (idx != null) {
                        setState(() {
                          rolledAssignments[ability] = idx;
                          abilityScores[ability] = rolledValues[idx];
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

    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: AppColors.cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.assignRacialBonuses,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColorLight,
                ),
              ),
              const SizedBox(height: 16),
              ...parsedBonuses.asMap().entries.map((entry) {
                int index = entry.key;
                int bonus = entry.value;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          "+$bonus",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.textColorLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          dropdownColor: AppColors.cardColor,
                          value: bonusAssignments[index],
                          hint: Text(
                            loc.bonus,
                            style: TextStyle(
                                color:
                                    AppColors.textColorLight.withOpacity(0.7)),
                          ),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: AppColors.primaryColor,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          items: abilities
                              .map((a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(
                                      a,
                                      style: TextStyle(
                                          color: AppColors.textColorLight),
                                    ),
                                  ))
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

  Map<String, dynamic> _getCurrentState(Map<String, int> finalScores) {
    return {
      'finalScores': finalScores,
      'method': selectedMethod,
      'abilityScores': Map<String, int>.from(abilityScores),
      'rolledValues': List<int>.from(rolledValues),
      'rolledAssignments': Map<String, int>.from(rolledAssignments),
      'bonusAssignments': Map<int, String>.from(bonusAssignments),
      'pointBuyScores': Map<String, int>.from(pointBuyScores),
    };
  }

  void confirmScores() {
    final loc = AppLocalizations.of(context)!;

    if (selectedMethod == "Roll 4d6 Drop Lowest" &&
        abilityScores.values.any((v) => v == -1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseAssignAll)),
      );
      return;
    }

    Map<String, int> finalScores = selectedMethod == "Point Buy"
        ? Map<String, int>.from(pointBuyScores)
        : Map<String, int>.from(abilityScores);

    for (var entry in bonusAssignments.entries) {
      finalScores.update(
          entry.value, (value) => value + parsedBonuses[entry.key],
          ifAbsent: () => parsedBonuses[entry.key]);
    }

    if (finalScores.length != 6 || finalScores.values.any((v) => v < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseAssignAll)),
      );
      return;
    }

    Navigator.pop(context, _getCurrentState(finalScores));
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        Map<String, int> finalScores = selectedMethod == "Point Buy"
            ? Map<String, int>.from(pointBuyScores)
            : Map<String, int>.from(abilityScores);

        for (var entry in bonusAssignments.entries) {
          finalScores.update(
              entry.value, (value) => value + parsedBonuses[entry.key],
              ifAbsent: () => parsedBonuses[entry.key]);
        }

        Navigator.pop(context, _getCurrentState(finalScores));
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.setabilityscores),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: confirmScores,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: AppColors.cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColorLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: AppColors.cardColor,
                        value: selectedMethod,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.primaryColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        items: methods
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    getLocalizedMethodName(m),
                                    style: TextStyle(
                                        color: AppColors.textColorLight),
                                  ),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ability Scores',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColorLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      buildMethodWidget(),
                    ],
                  ),
                ),
              ),
              buildBonusAssignment(),
            ],
          ),
        ),
      ),
    );
  }
}

class HPSelectionPage extends StatefulWidget {
  final ClassData classData;
  final int level;
  final int constitutionModifier;
  final String? initialMethod;
  final List<int>? initialRolledHP;
  final int? initialCustomHP;

  const HPSelectionPage({
    super.key,
    required this.classData,
    required this.level,
    required this.constitutionModifier,
    this.initialMethod,
    this.initialRolledHP,
    this.initialCustomHP,
  });

  @override
  State<HPSelectionPage> createState() => _HPSelectionPageState();
}

class _HPSelectionPageState extends State<HPSelectionPage> {
  late String selectedMethod;
  final List<String> methods = ["Roll", "Median", "Custom"];
  late List<int> rolledHP;
  late int customHP;

  @override
  void initState() {
    super.initState();
    selectedMethod = widget.initialMethod ?? "Median";
    rolledHP = widget.initialRolledHP != null
        ? List<int>.from(widget.initialRolledHP!)
        : [];
    customHP = widget.initialCustomHP ?? 0;

    if (rolledHP.isEmpty && selectedMethod != "Custom") {
      _calculateHP();
    }
  }

  int _getHitDie() {
    // Parse hit die from class data (e.g., "1d8" -> 8)
    final hdMatch = RegExp(r'd(\d+)').firstMatch(widget.classData.hd);
    return hdMatch != null ? int.parse(hdMatch.group(1)!) : 8;
  }

  void _calculateHP() {
    final hitDie = _getHitDie();
    final conMod = widget.constitutionModifier;

    if (selectedMethod == "Roll") {
      rolledHP.clear();
      // First level is always max
      rolledHP.add(hitDie + conMod);
      // Roll for remaining levels
      for (int i = 1; i < widget.level; i++) {
        final roll = Random().nextInt(hitDie) + 1 + conMod;
        rolledHP.add(roll);
      }
    } else if (selectedMethod == "Median") {
      rolledHP.clear();
      // First level is always max
      rolledHP.add(hitDie + conMod);
      // Use median for remaining levels
      final median = ((hitDie / 2).ceil() + 1) + conMod;
      for (int i = 1; i < widget.level; i++) {
        rolledHP.add(median);
      }
    }
    setState(() {});
  }

  int _getTotalHP() {
    if (selectedMethod == "Custom") {
      return customHP;
    }
    return rolledHP.isEmpty ? 0 : rolledHP.reduce((a, b) => a + b);
  }

  String _getLocalizedMethod(String method, AppLocalizations loc) {
    switch (method) {
      case "Roll":
        return loc.rollHp;
      case "Median":
        return loc.medianHp;
      case "Custom":
        return loc.customHp;
      default:
        return method;
    }
  }

  Map<String, dynamic> _getCurrentState() {
    return {
      'hp': _getTotalHP(),
      'method': selectedMethod,
      'rolledHP': List<int>.from(rolledHP),
      'customHP': customHP,
    };
  }

  void _confirmHP() {
    final loc = AppLocalizations.of(context)!;
    final hp = _getTotalHP();
    if (hp <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseSetValidHp)),
      );
      return;
    }
    Navigator.pop(context, _getCurrentState());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hitDie = _getHitDie();
    final totalHP = _getTotalHP();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _getCurrentState());
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.setHitPoints),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _confirmHP,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: AppColors.cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColorLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        dropdownColor: AppColors.cardColor,
                        value: selectedMethod,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.primaryColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        items: methods
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    _getLocalizedMethod(m, loc),
                                    style: TextStyle(
                                        color: AppColors.textColorLight),
                                  ),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedMethod = val!;
                            _calculateHP();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: AppColors.cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hit Points',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColorLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (selectedMethod == "Roll" ||
                          selectedMethod == "Median") ...[
                        Text(
                          'Hit Die: d$hitDie',
                          style: TextStyle(
                            color: AppColors.textColorLight,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Constitution Modifier: ${widget.constitutionModifier >= 0 ? '+' : ''}${widget.constitutionModifier}',
                          style: TextStyle(
                            color: AppColors.textColorLight,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (selectedMethod == "Roll")
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _calculateHP,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentTeal,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.casino, size: 20),
                                label: Text(loc.reroll),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        ...List.generate(widget.level, (index) {
                          final hp =
                              index < rolledHP.length ? rolledHP[index] : 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Level ${index + 1}: $hp HP${index == 0 ? ' (Max)' : ''}',
                              style: TextStyle(
                                color: AppColors.textColorLight,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }),
                      ],
                      if (selectedMethod == "Custom")
                        TextFormField(
                          initialValue: customHP == 0 ? "" : customHP.toString(),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: loc.totalHp,
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: AppColors.primaryColor,
                          ),
                          onChanged: (val) {
                            setState(() {
                              customHP = int.tryParse(val) ?? 0;
                            });
                          },
                        ),
                      const SizedBox(height: 16),
                      Divider(color: AppColors.textColorLight.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        loc.totalHpValue(totalHP),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentTeal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SkillSelectionPage extends StatefulWidget {
  final ClassData classData;
  final FeatData? featData;
  final BackgroundData? backgroundData;
  final RaceData? raceData;
  final Map<String, bool>? initialSelectedSkills;
  final Map<String, bool>? initialSelectedExpertise;

  const SkillSelectionPage({
    super.key,
    required this.classData,
    this.featData,
    this.backgroundData,
    this.raceData,
    this.initialSelectedSkills,
    this.initialSelectedExpertise,
  });

  @override
  State<SkillSelectionPage> createState() => _SkillSelectionPageState();
}

class _SkillSelectionPageState extends State<SkillSelectionPage> {
  late Map<String, bool> selectedSkills;
  late Map<String, bool> selectedExpertise;
  int maxSkillChoices = 0;
  int maxExpertiseChoices = 0;
  List<Map<String, String>> availableSkills = [];
  List<String> allowedSavingThrows = [];
  Set<String> backgroundSkills = {};
  Set<String> raceSkills = {};

  final List<Map<String, String>> allSkills = [
    {'name': 'Acrobatics', 'define': 'acrobatics'},
    {'name': 'Animal Handling', 'define': 'animal_handling'},
    {'name': 'Arcana', 'define': 'arcana'},
    {'name': 'Athletics', 'define': 'athletics'},
    {'name': 'Deception', 'define': 'deception'},
    {'name': 'History', 'define': 'history'},
    {'name': 'Insight', 'define': 'insight'},
    {'name': 'Intimidation', 'define': 'intimidation'},
    {'name': 'Investigation', 'define': 'investigation'},
    {'name': 'Medicine', 'define': 'medicine'},
    {'name': 'Nature', 'define': 'nature'},
    {'name': 'Perception', 'define': 'perception'},
    {'name': 'Performance', 'define': 'performance'},
    {'name': 'Persuasion', 'define': 'persuasion'},
    {'name': 'Religion', 'define': 'religion'},
    {'name': 'Sleight of Hand', 'define': 'sleight_of_hand'},
    {'name': 'Stealth', 'define': 'stealth'},
    {'name': 'Survival', 'define': 'survival'},
  ];

  final List<String> savingThrowAbilities = [
    'Strength',
    'Dexterity',
    'Constitution',
    'Intelligence',
    'Wisdom',
    'Charisma'
  ];

  @override
  void initState() {
    super.initState();

    // Parse background proficiencies to gray them out
    _parseBackgroundProficiencies();

    // Parse race proficiencies to gray them out
    _parseRaceProficiencies();

    // Parse proficiency string to get allowed skills and saving throws
    _parseProficiencies();

    // Parse the number of skills from class
    final numSkillsStr = widget.classData.numSkills.trim();
    maxSkillChoices = int.tryParse(numSkillsStr) ?? 0;

    // Check if feat provides expertise (e.g., Rogue's Expertise feature)
    if (widget.featData != null) {
      // Parse feat for additional proficiencies or expertise
      if (widget.featData!.name.toLowerCase().contains('expertise')) {
        maxExpertiseChoices = 2; // Typical expertise grants 2 skills
      }
    }

    selectedSkills = widget.initialSelectedSkills != null
        ? Map<String, bool>.from(widget.initialSelectedSkills!)
        : {};
    selectedExpertise = widget.initialSelectedExpertise != null
        ? Map<String, bool>.from(widget.initialSelectedExpertise!)
        : {};

    // Initialize available skills as unselected if not already in initial state
    for (var skill in availableSkills) {
      selectedSkills.putIfAbsent(skill['define']!, () => false);
      selectedExpertise.putIfAbsent(skill['define']!, () => false);
    }
  }

  void _parseBackgroundProficiencies() {
    if (widget.backgroundData == null) return;

    final proficiencyStr = widget.backgroundData!.proficiency;
    if (proficiencyStr.isEmpty) return;

    // Split by comma and trim
    final proficiencies = proficiencyStr
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Add background skills to the set
    for (final prof in proficiencies) {
      final skill = allSkills.firstWhere(
        (s) => s['name'] == prof,
        orElse: () => {'name': '', 'define': ''},
      );
      if (skill['name']!.isNotEmpty) {
        backgroundSkills.add(skill['define']!);
      }
    }
  }

  void _parseRaceProficiencies() {
    if (widget.raceData == null) return;

    final proficiencyStr = widget.raceData!.proficiency;
    if (proficiencyStr.isEmpty) return;

    // Split by comma and trim
    final proficiencies = proficiencyStr
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Add race skills to the set
    for (final prof in proficiencies) {
      final skill = allSkills.firstWhere(
        (s) => s['name'] == prof,
        orElse: () => {'name': '', 'define': ''},
      );
      if (skill['name']!.isNotEmpty) {
        raceSkills.add(skill['define']!);
      }
    }
  }

  void _parseProficiencies() {
    final proficiencyStr = widget.classData.proficiency;

    if (proficiencyStr.isEmpty) {
      availableSkills = List.from(allSkills);
      return;
    }

    // Split by comma and trim
    final proficiencies = proficiencyStr
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Separate saving throws from skills
    for (final prof in proficiencies) {
      if (savingThrowAbilities.contains(prof)) {
        allowedSavingThrows.add(prof);
      } else {
        // This is a skill - find it in allSkills
        final skill = allSkills.firstWhere(
          (s) => s['name'] == prof,
          orElse: () => {'name': '', 'define': ''},
        );
        if (skill['name']!.isNotEmpty) {
          availableSkills.add(skill);
        }
      }
    }

    // If no skills were found in proficiency string, allow all skills
    if (availableSkills.isEmpty) {
      availableSkills = List.from(allSkills);
    }
  }

  String getLocalizedSkillName(String skillName) {
    final loc = AppLocalizations.of(context)!;
    switch (skillName) {
      case 'Acrobatics':
        return loc.skillAcrobatics;
      case 'Animal Handling':
        return loc.skillAnimalHandling;
      case 'Arcana':
        return loc.skillArcana;
      case 'Athletics':
        return loc.skillAthletics;
      case 'Deception':
        return loc.skillDeception;
      case 'History':
        return loc.skillHistory;
      case 'Insight':
        return loc.skillInsight;
      case 'Intimidation':
        return loc.skillIntimidation;
      case 'Investigation':
        return loc.skillInvestigation;
      case 'Medicine':
        return loc.skillMedicine;
      case 'Nature':
        return loc.skillNature;
      case 'Perception':
        return loc.skillPerception;
      case 'Performance':
        return loc.skillPerformance;
      case 'Persuasion':
        return loc.skillPersuasion;
      case 'Religion':
        return loc.skillReligion;
      case 'Sleight of Hand':
        return loc.skillSleightOfHand;
      case 'Stealth':
        return loc.skillStealth;
      case 'Survival':
        return loc.skillSurvival;
      default:
        return skillName;
    }
  }

  int get selectedProficiencyCount =>
      selectedSkills.values.where((selected) => selected).length;

  int get selectedExpertiseCount =>
      selectedExpertise.values.where((selected) => selected).length;

  bool canSelectMoreProficiencies() =>
      selectedProficiencyCount < maxSkillChoices;

  bool canSelectMoreExpertise() =>
      selectedExpertiseCount < maxExpertiseChoices;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop({
          'proficiencies': Map<String, bool>.from(selectedSkills),
          'expertise': Map<String, bool>.from(selectedExpertise),
          'savingThrows': List<String>.from(allowedSavingThrows),
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.chooseskills),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () {
                // Return the selected skills, expertise, and saving throws
                Navigator.of(context).pop({
                  'proficiencies': Map<String, bool>.from(selectedSkills),
                  'expertise': Map<String, bool>.from(selectedExpertise),
                  'savingThrows': List<String>.from(allowedSavingThrows),
                });
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (maxSkillChoices > 0) ...[
                Card(
                  color: AppColors.cardColor,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.selectSkillProficiencies,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.selectUpToSkills(maxSkillChoices),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textColorLight.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.availableSkillChoices(
                              maxSkillChoices - selectedProficiencyCount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: selectedProficiencyCount >= maxSkillChoices
                                ? AppColors.warningColor
                                : AppColors.accentTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...availableSkills.map((skill) {
                  final skillDefine = skill['define']!;
                  final skillName = skill['name']!;
                  final isSelected = selectedSkills[skillDefine] ?? false;
                  final isFromBackground = backgroundSkills.contains(skillDefine);
                  final isFromRace = raceSkills.contains(skillDefine);
                  final isAutoGranted = isFromBackground || isFromRace;

                  String? sourceLabel;
                  if (isFromBackground) {
                    sourceLabel = loc.fromBackground;
                  } else if (isFromRace) {
                    sourceLabel = loc.fromRace;
                  }

                  return Card(
                    color: isAutoGranted
                        ? AppColors.appBarColor.withOpacity(0.5)
                        : isSelected
                            ? AppColors.accentTeal.withOpacity(0.2)
                            : AppColors.cardColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      title: Text(
                        getLocalizedSkillName(skillName),
                        style: TextStyle(
                          color: isAutoGranted
                              ? AppColors.textColorDark
                              : AppColors.textColorLight,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: sourceLabel != null
                          ? Text(
                              sourceLabel,
                              style: TextStyle(
                                color: AppColors.textColorDark,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : null,
                      value: isAutoGranted ? true : isSelected,
                      onChanged: isAutoGranted
                          ? null
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  if (canSelectMoreProficiencies()) {
                                    selectedSkills[skillDefine] = true;
                                  }
                                } else {
                                  selectedSkills[skillDefine] = false;
                                  // If removing proficiency, also remove expertise
                                  selectedExpertise[skillDefine] = false;
                                }
                              });
                            },
                      activeColor: isAutoGranted
                          ? AppColors.textColorDark
                          : AppColors.accentTeal,
                    ),
                  );
                }).toList(),
              ],
              if (maxExpertiseChoices > 0) ...[
                const SizedBox(height: 24),
                Card(
                  color: AppColors.cardColor,
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.selectSkillExpertise,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.selectUpToSkills(maxExpertiseChoices),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textColorLight.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.availableSkillChoices(
                              maxExpertiseChoices - selectedExpertiseCount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: selectedExpertiseCount >= maxExpertiseChoices
                                ? AppColors.warningColor
                                : AppColors.accentPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...availableSkills.map((skill) {
                  final skillDefine = skill['define']!;
                  final skillName = skill['name']!;
                  final isProficient = selectedSkills[skillDefine] ?? false;
                  final hasExpertise = selectedExpertise[skillDefine] ?? false;

                  return Card(
                    color: hasExpertise
                        ? AppColors.accentPurple.withOpacity(0.2)
                        : AppColors.cardColor,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      title: Text(
                        getLocalizedSkillName(skillName),
                        style: TextStyle(
                          color: isProficient
                              ? AppColors.textColorLight
                              : AppColors.textColorDark,
                          fontWeight:
                              hasExpertise ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: !isProficient
                          ? Text(
                              loc.proficiency,
                              style: TextStyle(
                                color: AppColors.textColorDark,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      value: hasExpertise,
                      onChanged: isProficient
                          ? (value) {
                              setState(() {
                                if (value == true) {
                                  if (canSelectMoreExpertise()) {
                                    selectedExpertise[skillDefine] = true;
                                  }
                                } else {
                                  selectedExpertise[skillDefine] = false;
                                }
                              });
                            }
                          : null,
                      activeColor: AppColors.accentPurple,
                    ),
                  );
                }).toList(),
              ],
              if (maxSkillChoices == 0 && maxExpertiseChoices == 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'No skill selections available for this class.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textColorLight.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpellSelectionPage extends StatefulWidget {
  final List<SpellData> allSpells;
  final ClassData classData;
  final int characterLevel;
  final List<SpellData> initialSelection;

  const SpellSelectionPage({
    super.key,
    required this.allSpells,
    required this.classData,
    required this.characterLevel,
    this.initialSelection = const [],
  });

  @override
  State<SpellSelectionPage> createState() => _SpellSelectionPageState();
}

class _SpellSelectionPageState extends State<SpellSelectionPage> {
  late Map<String, bool> selectedSpells;
  late int maxSpellLevel;

  @override
  void initState() {
    super.initState();
    selectedSpells = {
      for (var spell in widget.initialSelection) spell.name: true
    };
    maxSpellLevel = _calculateMaxSpellLevel();
  }

  int _calculateMaxSpellLevel() {
    // Find the autolevel entry with slots for the character's level
    final autolevel = widget.classData.autolevels.firstWhere(
      (al) => int.parse(al.level) == widget.characterLevel && al.slots != null,
      orElse: () => widget.classData.autolevels.firstWhere(
        (al) => al.slots != null,
        orElse: () => widget.classData.autolevels.first,
      ),
    );

    // Get slots
    final slotsObj = autolevel.slots;
    if (slotsObj == null || slotsObj.slots.isEmpty) return -1;

    final slots = slotsObj.slots;

    // Find the highest spell level with available slots
    int maxLevel = -1;
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] > 0) {
        maxLevel = i;
      }
    }

    return maxLevel;
  }

  List<SpellData> _getFilteredSpells() {
    // Filter spells by class and level
    return widget.allSpells.where((spell) {
      // Check if spell is available to this class
      if (!spell.classes.contains(widget.classData.name)) {
        return false;
      }

      // Check spell level
      final spellLevel = int.tryParse(spell.level) ?? 0;
      return spellLevel <= maxSpellLevel;
    }).toList()
      ..sort((a, b) {
        // Sort by level first, then by name
        final levelCompare = int.parse(a.level).compareTo(int.parse(b.level));
        if (levelCompare != 0) return levelCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

  List<SpellData> _getSelectedSpells() {
    return widget.allSpells
        .where((spell) => selectedSpells[spell.name] == true)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final filteredSpells = _getFilteredSpells();

    // Group spells by level
    final Map<int, List<SpellData>> spellsByLevel = {};
    for (var spell in filteredSpells) {
      final level = int.parse(spell.level);
      spellsByLevel.putIfAbsent(level, () => []).add(spell);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.choosespells),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_getSelectedSpells());
            },
            child: Text(
              loc.done,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: filteredSpells.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  loc.nospellsavailable,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textColorLight.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    '${loc.maximumspelllevel}: $maxSpellLevel',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...spellsByLevel.entries.map((entry) {
                  final level = entry.key;
                  final spells = entry.value;
                  final levelText = level == 0 ? loc.cantrip : '${loc.level} $level';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          levelText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentPurple,
                          ),
                        ),
                      ),
                      ...spells.map((spell) {
                        final isSelected = selectedSpells[spell.name] == true;
                        return CheckboxListTile(
                          title: Text(spell.name),
                          subtitle: Text('${spell.school} • ${spell.time}'),
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              selectedSpells[spell.name] = value ?? false;
                            });
                          },
                          activeColor: AppColors.accentPurple,
                        );
                      }).toList(),
                      const Divider(),
                    ],
                  );
                }).toList(),
              ],
            ),
    );
  }
}

class ItemSelectionPage extends StatefulWidget {
  final List<ItemData> allItems;
  final List<ItemData> initialSelection;

  const ItemSelectionPage({
    super.key,
    required this.allItems,
    this.initialSelection = const [],
  });

  @override
  State<ItemSelectionPage> createState() => _ItemSelectionPageState();
}

class _ItemSelectionPageState extends State<ItemSelectionPage> {
  late Map<String, bool> selectedItems;
  String searchQuery = '';
  String typeFilter = 'All';

  @override
  void initState() {
    super.initState();
    selectedItems = {
      for (var item in widget.initialSelection) item.name: true
    };
  }

  List<ItemData> _getSelectedItems() {
    return widget.allItems
        .where((item) => selectedItems[item.name] == true)
        .toList();
  }

  List<String> _getItemTypes() {
    final types = widget.allItems.map((item) => item.type).toSet().toList();
    types.sort();
    return ['All', ...types];
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Filter items by search query and type
    final filteredItems = widget.allItems.where((item) {
      final matchesSearch = searchQuery.isEmpty ||
          item.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesType = typeFilter == 'All' || item.type == typeFilter;
      return matchesSearch && matchesType;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Items'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_getSelectedItems());
            },
            child: Text(
              loc.done,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: typeFilter,
                  items: _getItemTypes()
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        typeFilter = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Text(
                      'No items found',
                      style: TextStyle(
                        color: AppColors.textColorLight,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isSelected = selectedItems[item.name] ?? false;

                      return CheckboxListTile(
                        title: Text(item.name),
                        subtitle: Text('${item.type} • ${item.weight} lb • ${item.value} gp'),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            selectedItems[item.name] = value ?? false;
                          });
                        },
                        activeColor: AppColors.accentPurple,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
