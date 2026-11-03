import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/db/vocabulary_list.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/utils/otg_config.dart';

class ConfigurationPage extends StatefulWidget {
  const ConfigurationPage({super.key, required this.destination});

  final Destination destination;

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {
  int _autoPlayAudio = OTGConfig.get(OTGConfig.keyAutoPlayAudio, 0);
  int _playAudioInGame = OTGConfig.get(OTGConfig.keyPlayAudioInGame, 1);

  Future<void> _clearLearningHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空學習紀錄'),
        content: const Text('所有學過的單詞紀錄都會被清除，確定嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final vp = VocabularyProvider();
    await vp.open();
    final vs = await vp.getVocabularyList(
        limit: 1000000, where: '$columnLearnt > ?', whereArgs: [0]);
    for (final v in vs) {
      v.learnt = 0;
    }
    await vp.updateAll(vs);
    final vlp = VocabularyListProvider();
    await vlp.open();
    await vlp.deleteAll();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('學習紀錄已清空')));
  }

  Widget _settingRow(String label, String value, Color color,
      VoidCallback onPressed) {
    final style = Theme.of(context).textTheme.titleLarge;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.all(8.0),
            shape: const RoundedRectangleBorder(),
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll(Colors.cyanAccent),
          ),
          onPressed: onPressed,
          child: Text(value, style: style),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        backgroundColor: widget.destination.color,
      ),
      body: Container(
        padding: const EdgeInsets.all(5.0),
        child: ListView(
          children: [
            _settingRow(
              '自動播放/預載語音',
              OTGConfig.valueAutoPlayAudio[_autoPlayAudio],
              _autoPlayAudio < 2 ? Colors.cyan : Colors.grey,
              () {
                setState(() {
                  _autoPlayAudio =
                      (_autoPlayAudio + 1) % OTGConfig.valueAutoPlayAudio.length;
                });
                OTGConfig.setKeyInt(OTGConfig.keyAutoPlayAudio, _autoPlayAudio);
              },
            ),
            _settingRow(
              '翻牌遊戲播放語音',
              OTGConfig.valuePlayAudioInGame[_playAudioInGame],
              Colors.cyan,
              () {
                setState(() {
                  _playAudioInGame = (_playAudioInGame + 1) %
                      OTGConfig.valuePlayAudioInGame.length;
                });
                OTGConfig.setKeyInt(
                    OTGConfig.keyPlayAudioInGame, _playAudioInGame);
              },
            ),
            _settingRow('清空學習紀錄', '清空', Colors.cyan, _clearLearningHistory),
          ],
        ),
      ),
    );
  }
}
