import 'package:dnd/configs/colours.dart';
import 'package:flutter/material.dart';
import 'package:dnd/classes/profile_manager.dart';
import 'package:dnd/configs/defines.dart';
import 'package:dnd/l10n/app_localizations.dart';

class StatsPage extends StatefulWidget {
  final ProfileManager profileManager;

  const StatsPage({super.key, required this.profileManager});

  @override
  StatsPageState createState() => StatsPageState();
}

class StatsPageState extends State<StatsPage> {
  int strength = 10;
  int dexterity = 10;
  int constitution = 10;
  int intelligence = 10;
  int wisdom = 10;
  int charisma = 10;

  int proficiencyBonus = 0;

  int saveStrProficiency = 0;
  int saveDexProficiency = 0;
  int saveConProficiency = 0;
  int saveIntProficiency = 0;
  int saveWisProficiency = 0;
  int saveChaProficiency = 0;

  int skillProfAcro = 0;
  int skillProfAnim = 0;
  int skillProfArca = 0;
  int skillProfAthl = 0;
  int skillProfDece = 0;
  int skillProfHist = 0;
  int skillProfInsi = 0;
  int skillProfInti = 0;
  int skillProfInve = 0;
  int skillProfMedi = 0;
  int skillProfNatu = 0;
  int skillProfPerc = 0;
  int skillProfPerf = 0;
  int skillProfPers = 0;
  int skillProfReli = 0;
  int skillProfSlei = 0;
  int skillProfStea = 0;
  int skillProfSurv = 0;
  int skillJack = 0;

  int skillExAcro = 0;
  int skillExAnim = 0;
  int skillExArca = 0;
  int skillExAthl = 0;
  int skillExDece = 0;
  int skillExHist = 0;
  int skillExInsi = 0;
  int skillExInti = 0;
  int skillExInve = 0;
  int skillExMedi = 0;
  int skillExNatu = 0;
  int skillExPerc = 0;
  int skillExPerf = 0;
  int skillExPers = 0;
  int skillExReli = 0;
  int skillExSlei = 0;
  int skillExStea = 0;
  int skillExSurv = 0;

  @override
  void initState() {
    super.initState();
    _loadCharacterData();
  }

  Future<void> updateStats(String field, dynamic newScore) async {
    await widget.profileManager.updateStats(field: field, value: newScore);
    setState(() {
      _loadCharacterData();
    });
  }

  Future<void> updateSaves(String field, dynamic newScore) async {
    await widget.profileManager
        .updateSavingThrows(field: field, value: newScore);
    setState(() {
      _loadCharacterData();
    });
  }

  Future<void> updateSkills(
      String field, int proficiency, int? expertise) async {
    await widget.profileManager.updateSkills(
        skill: field, proficiency: proficiency, expertise: expertise);
    setState(() {
      _loadCharacterData();
    });
  }

  Future<void> _loadCharacterData() async {
    // Load character stats
    List<Map<String, dynamic>> stats = await widget.profileManager.getStats();

    // Load saving throws
    List<Map<String, dynamic>> saves =
        await widget.profileManager.getSavingThrows();

    // Load skills
    List<Map<String, dynamic>> skills = await widget.profileManager.getSkills();

    // Loading stats
    if (stats.isNotEmpty) {
      Map<String, dynamic> characterStats = stats.first;
      setState(() {
        strength = characterStats[Defines.statSTR] ?? 10;
        dexterity = characterStats[Defines.statDEX] ?? 10;
        constitution = characterStats[Defines.statCON] ?? 10;
        intelligence = characterStats[Defines.statINT] ?? 10;
        wisdom = characterStats[Defines.statWIS] ?? 10;
        charisma = characterStats[Defines.statCHA] ?? 10;
        proficiencyBonus = characterStats[Defines.statProficiencyBonus] ?? 0;
      });
    }

    // Loading saving throws
    if (saves.isNotEmpty) {
      Map<String, dynamic> characterStats = saves.first;
      setState(() {
        saveStrProficiency = characterStats[Defines.saveStr] ?? 0;
        saveDexProficiency = characterStats[Defines.saveDex] ?? 0;
        saveConProficiency = characterStats[Defines.saveCon] ?? 0;
        saveIntProficiency = characterStats[Defines.saveInt] ?? 0;
        saveWisProficiency = characterStats[Defines.saveWis] ?? 0;
        saveChaProficiency = characterStats[Defines.saveCha] ?? 0;
      });
    }

    // Loading skills and expertise
    if (skills.isNotEmpty) {
      for (var skill in skills) {
        switch (skill['skill']) {
          case Defines.skillAcrobatics:
            setState(() {
              skillProfAcro = skill['proficiency'] ?? 0;
              skillExAcro = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillAnimalHandling:
            setState(() {
              skillProfAnim = skill['proficiency'] ?? 0;
              skillExAnim = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillArcana:
            setState(() {
              skillProfArca = skill['proficiency'] ?? 0;
              skillExArca = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillAthletics:
            setState(() {
              skillProfAthl = skill['proficiency'] ?? 0;
              skillExAthl = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillDeception:
            setState(() {
              skillProfDece = skill['proficiency'] ?? 0;
              skillExDece = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillHistory:
            setState(() {
              skillProfHist = skill['proficiency'] ?? 0;
              skillExHist = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillInsight:
            setState(() {
              skillProfInsi = skill['proficiency'] ?? 0;
              skillExInsi = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillIntimidation:
            setState(() {
              skillProfInti = skill['proficiency'] ?? 0;
              skillExInti = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillInvestigation:
            setState(() {
              skillProfInve = skill['proficiency'] ?? 0;
              skillExInve = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillMedicine:
            setState(() {
              skillProfMedi = skill['proficiency'] ?? 0;
              skillExMedi = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillNature:
            setState(() {
              skillProfNatu = skill['proficiency'] ?? 0;
              skillExNatu = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillPerception:
            setState(() {
              skillProfPerc = skill['proficiency'] ?? 0;
              skillExPerc = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillPerformance:
            setState(() {
              skillProfPerf = skill['proficiency'] ?? 0;
              skillExPerf = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillPersuasion:
            setState(() {
              skillProfPers = skill['proficiency'] ?? 0;
              skillExPers = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillReligion:
            setState(() {
              skillProfReli = skill['proficiency'] ?? 0;
              skillExReli = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillSleightOfHand:
            setState(() {
              skillProfSlei = skill['proficiency'] ?? 0;
              skillExSlei = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillStealth:
            setState(() {
              skillProfStea = skill['proficiency'] ?? 0;
              skillExStea = skill['expertise'] ?? 0;
            });
            break;
          case Defines.skillSurvival:
            setState(() {
              skillProfSurv = skill['proficiency'] ?? 0;
              skillExSurv = skill['expertise'] ?? 0;
            });
          case Defines.skillJackofAllTrades:
            setState(() {
              skillJack = skill['proficiency'] ?? 0;
            });
            break;
        }
      }
    }
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.grey, thickness: 1.5),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatRow(String statName, int abilityScore, String field) {
    int abilityModifier = ((abilityScore - 10) / 2).floor();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => _showEditDialog(statName, abilityScore, field),
              child: Column(
                children: [
                  SizedBox(
                    height: 45,
                    child: Card(
                      color: AppColors.cardColor,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          abilityScore.toString(),
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                SizedBox(
                  height: 45,
                  child: Card(
                    color: AppColors.cardColor,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        statName,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                SizedBox(
                  height: 45,
                  child: Card(
                    color: AppColors.cardColor,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        (abilityModifier >= 0
                            ? "+$abilityModifier"
                            : "$abilityModifier"),
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
      String statName, int currentScore, String field) async {
    final loc = AppLocalizations.of(context)!;
    int newScore = currentScore;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${loc.edit} $statName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${loc.value}:'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (newScore > 0) newScore--;
                              });
                            },
                          ),
                          Text('$newScore'),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                newScore++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.abort),
                ),
                TextButton(
                  onPressed: () async {
                    updateStats(field, newScore);

                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(loc.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSavingThrowDialog(
      String statName, int proficiency, String field) async {
    final loc = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${loc.savingThrowfor} $statName'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text(loc.proficiencyBonus),
                  value: proficiency == 1,
                  onChanged: (bool? value) {
                    setState(() {
                      proficiency = value == true ? 1 : 0;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.abort),
          ),
          TextButton(
            onPressed: () async {
              updateSaves(field, proficiency);
              setState(() {
                _loadCharacterData();
              });
              Navigator.of(context).pop();
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingThrowRow(
      String statName, int proficiency, String field, int abilityScore) {
    int abilityModifier = ((abilityScore - 10) / 2).floor();
    int savingThrowBonus =
        proficiency == 1 ? abilityModifier + proficiencyBonus : abilityModifier;

    String bonusText =
        savingThrowBonus >= 0 ? "+$savingThrowBonus" : "$savingThrowBonus";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => _showSavingThrowDialog(statName, proficiency, field),
              child: SizedBox(
                height: 45,
                child: Card(
                  color: AppColors.cardColor,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      bonusText,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 45,
              child: Card(
                color: AppColors.cardColor,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    statName,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSkillDialog(
      String skillName, int proficiency, int hasExpertise, String field) async {
    final loc = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${loc.editskillfor} $skillName'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text(loc.proficiency),
                  value: proficiency == 1,
                  onChanged: (bool? value) {
                    setState(() {
                      proficiency = value == true ? 1 : 0;
                      if (proficiency == 0) {
                        hasExpertise = 0;
                      }
                    });
                  },
                ),
                CheckboxListTile(
                  title: Text(loc.expertise),
                  value: hasExpertise == 1,
                  onChanged: (bool? value) {
                    if (proficiency == 1) {
                      setState(() {
                        hasExpertise = value == true ? 1 : 0;
                      });
                    }
                  },
                  enabled: proficiency == 1,
                  activeColor: proficiency == 1 ? null : Colors.grey,
                  checkColor: proficiency == 1 ? null : Colors.grey[700],
                ),
                CheckboxListTile(
                  title: Text(loc.jack),
                  value: skillJack == 1,
                  onChanged: (bool? value) {
                    setState(() {
                      skillJack = value == true ? 1 : 0;
                    });
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.abort),
          ),
          TextButton(
            onPressed: () async {
              updateSkills(field, proficiency, hasExpertise);
              updateSkills(Defines.skillJackofAllTrades, skillJack, null);
              setState(() {
                _loadCharacterData();
              });
              Navigator.of(context).pop();
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillRow(String skillName, int proficiency, int hasExpertise,
      String field, int abilityScore) {
    int abilityModifier = ((abilityScore - 10) / 2).floor();

    int skillBonus = abilityModifier;

    if (skillJack == 1 && proficiency != 1 && hasExpertise != 1) {
      skillBonus += 1;
    } else {
      if (proficiency == 1) {
        skillBonus += proficiencyBonus;
        if (hasExpertise == 1) {
          skillBonus += proficiencyBonus;
        }
      }
    }

    String bonusText = skillBonus >= 0 ? "+$skillBonus" : "$skillBonus";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () =>
                  _showSkillDialog(skillName, proficiency, hasExpertise, field),
              child: SizedBox(
                height: 45,
                child: Card(
                  color: AppColors.cardColor,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      bonusText,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 45,
              child: Card(
                color: AppColors.cardColor,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    skillName,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsSection() {
    final loc = AppLocalizations.of(context)!;

    final List<Map<String, dynamic>> skillData = [
      {
        'name': loc.skillAcrobatics,
        'prof': skillProfAcro,
        'ex': skillExAcro,
        'define': Defines.skillAcrobatics,
        'ability': dexterity,
        'description': loc.skillAcrobaticsDescription,
        'attribute': loc.dexterityShort,
      },
      {
        'name': loc.skillAnimalHandling,
        'prof': skillProfAnim,
        'ex': skillExAnim,
        'define': Defines.skillAnimalHandling,
        'ability': wisdom,
        'description': loc.skillAnimalHandlingDescription,
        'attribute': loc.wisdomShort,
      },
      {
        'name': loc.skillArcana,
        'prof': skillProfArca,
        'ex': skillExArca,
        'define': Defines.skillArcana,
        'ability': intelligence,
        'description': loc.skillArcanaDescription,
        'attribute': loc.intelligenceShort,
      },
      {
        'name': loc.skillAthletics,
        'prof': skillProfAthl,
        'ex': skillExAthl,
        'define': Defines.skillAthletics,
        'ability': strength,
        'description': loc.skillAthleticsDescription,
        'attribute': loc.strengthShort,
      },
      {
        'name': loc.skillDeception,
        'prof': skillProfDece,
        'ex': skillExDece,
        'define': Defines.skillDeception,
        'ability': charisma,
        'description': loc.skillDeceptionDescription,
        'attribute': loc.charismaShort,
      },
      {
        'name': loc.skillHistory,
        'prof': skillProfHist,
        'ex': skillExHist,
        'define': Defines.skillHistory,
        'ability': intelligence,
        'description': loc.skillHistoryDescription,
        'attribute': loc.intelligenceShort,
      },
      {
        'name': loc.skillInsight,
        'prof': skillProfInsi,
        'ex': skillExInsi,
        'define': Defines.skillInsight,
        'ability': wisdom,
        'description': loc.skillInsightDescription,
        'attribute': loc.wisdomShort,
      },
      {
        'name': loc.skillIntimidation,
        'prof': skillProfInti,
        'ex': skillExInti,
        'define': Defines.skillIntimidation,
        'ability': charisma,
        'description': loc.skillIntimidationDescription,
        'attribute': loc.charismaShort,
      },
      {
        'name': loc.skillInvestigation,
        'prof': skillProfInve,
        'ex': skillExInve,
        'define': Defines.skillInvestigation,
        'ability': intelligence,
        'description': loc.skillInvestigationDescription,
        'attribute': loc.intelligenceShort,
      },
      {
        'name': loc.skillMedicine,
        'prof': skillProfMedi,
        'ex': skillExMedi,
        'define': Defines.skillMedicine,
        'ability': wisdom,
        'description': loc.skillMedicineDescription,
        'attribute': loc.wisdomShort,
      },
      {
        'name': loc.skillNature,
        'prof': skillProfNatu,
        'ex': skillExNatu,
        'define': Defines.skillNature,
        'ability': intelligence,
        'description': loc.skillNatureDescription,
        'attribute': loc.intelligenceShort,
      },
      {
        'name': loc.skillPerception,
        'prof': skillProfPerc,
        'ex': skillExPerc,
        'define': Defines.skillPerception,
        'ability': wisdom,
        'description': loc.skillPerceptionDescription,
        'attribute': loc.wisdomShort,
      },
      {
        'name': loc.skillPerformance,
        'prof': skillProfPerf,
        'ex': skillExPerf,
        'define': Defines.skillPerformance,
        'ability': charisma,
        'description': loc.skillPerformanceDescription,
        'attribute': loc.charismaShort,
      },
      {
        'name': loc.skillPersuasion,
        'prof': skillProfPers,
        'ex': skillExPers,
        'define': Defines.skillPersuasion,
        'ability': charisma,
        'description': loc.skillPersuasionDescription,
        'attribute': loc.charismaShort,
      },
      {
        'name': loc.skillReligion,
        'prof': skillProfReli,
        'ex': skillExReli,
        'define': Defines.skillReligion,
        'ability': intelligence,
        'description': loc.skillReligionDescription,
        'attribute': loc.intelligenceShort,
      },
      {
        'name': loc.skillSleightOfHand,
        'prof': skillProfSlei,
        'ex': skillExSlei,
        'define': Defines.skillSleightOfHand,
        'ability': dexterity,
        'description': loc.skillSleightOfHandDescription,
        'attribute': loc.dexterityShort,
      },
      {
        'name': loc.skillStealth,
        'prof': skillProfStea,
        'ex': skillExStea,
        'define': Defines.skillStealth,
        'ability': dexterity,
        'description': loc.skillStealthDescription,
        'attribute': loc.dexterityShort,
      },
      {
        'name': loc.skillSurvival,
        'prof': skillProfSurv,
        'ex': skillExSurv,
        'define': Defines.skillSurvival,
        'ability': wisdom,
        'description': loc.skillSurvivalDescription,
        'attribute': loc.wisdomShort,
      },
    ];

    skillData.sort((a, b) => a['name'].compareTo(b['name']));

    return Column(
    children: [
      _buildSkillsLabelRow(),
      ...skillData.map((skill) => GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(skill['name'] + " (${skill['attribute']})"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(skill['description'] ?? ''),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.ok),
                ),
              ],
            ),
          );
        },
        child: _buildSkillRow(
          skill['name'],
          skill['prof'],
          skill['ex'],
          skill['define'],
          skill['ability'],
        ),
      )),
    ],
  );
}

  Widget _buildStatsLabelRow() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                loc.value,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                loc.ability,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                loc.modifier,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingThrowLabelRow() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                loc.bonus,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                loc.ability,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsLabelRow() {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                loc.bonus,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                loc.skill,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return SafeArea(
        child: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader("Stats"),
          _buildStatsLabelRow(),
          _buildStatRow(loc.strength, strength, Defines.statSTR),
          _buildStatRow(loc.dexterity, dexterity, Defines.statDEX),
          _buildStatRow(loc.constitution, constitution, Defines.statCON),
          _buildStatRow(loc.intelligence, intelligence, Defines.statINT),
          _buildStatRow(loc.wisdom, wisdom, Defines.statWIS),
          _buildStatRow(loc.charisma, charisma, Defines.statCHA),
          const SizedBox(height: 24),
          _buildHeader(loc.savingThrows),
          _buildSavingThrowLabelRow(),
          _buildSavingThrowRow(
              loc.strength, saveStrProficiency, Defines.saveStr, strength),
          _buildSavingThrowRow(
              loc.dexterity, saveDexProficiency, Defines.saveDex, dexterity),
          _buildSavingThrowRow(loc.constitution, saveConProficiency,
              Defines.saveCon, constitution),
          _buildSavingThrowRow(loc.intelligence, saveIntProficiency,
              Defines.saveInt, intelligence),
          _buildSavingThrowRow(
              loc.wisdom, saveWisProficiency, Defines.saveWis, wisdom),
          _buildSavingThrowRow(
              loc.charisma, saveChaProficiency, Defines.saveCha, charisma),
          const SizedBox(height: 24),
          _buildHeader(loc.skills),
          _buildSkillsSection(),
        ],
      ),
    ));
  }
}
