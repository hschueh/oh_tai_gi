import 'package:flutter/material.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'package:oh_tai_gi/destination.dart';
import 'package:oh_tai_gi/ui/component/small_vocabulary_foldable_card.dart';
import 'package:oh_tai_gi/utils/utils.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.destination});

  final Destination destination;

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final List<Vocabulary> vocabularies = [];
  final VocabularyProvider vp = VocabularyProvider();
  final TextEditingController controller = TextEditingController();
  bool shouldReload = true;
  bool toggleSearch = true;
  bool searching = false;
  String keyword = '';

  /// Incremented for every new search so that results of an outdated query
  /// (the user kept typing) are dropped.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    getSearchKeyword().then((value) {
      if (value.isNotEmpty) search(value);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Searches for [newKeyword], e.g. text selected with "揣臺語".
  void search(String newKeyword) {
    if (!mounted) return;
    keyword = newKeyword;
    controller.text = newKeyword;
    refresh();
  }

  void refresh() {
    _generation++;
    setState(() {
      searching = true;
      vocabularies.clear();
    });
    retrieveVocabularyList();
  }

  Future<void> retrieveVocabularyList() async {
    final generation = _generation;
    shouldReload = false;
    await vp.open();
    if (keyword.isEmpty) {
      if (mounted) setState(() => searching = false);
      return;
    }
    final vs = await vp.searchVocabularyWithKeyword(
        keyword, [columnTitle, columnChinese, columnHeteronyms],
        offset: vocabularies.length);
    if (!mounted || generation != _generation) return;
    setState(() {
      vocabularies.addAll(vs);
      if (vs.isNotEmpty) shouldReload = true;
      searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (vocabularies.isNotEmpty) {
      body = NotificationListener<ScrollNotification>(
        child: ListView.builder(
          itemCount: vocabularies.length,
          itemBuilder: (context, position) {
            return SmallVocabularyFoldableCard(vocabularies[position],
                foldable: true, key: ObjectKey(vocabularies[position]));
          },
        ),
        onNotification: (scrollInfo) {
          if (scrollInfo.depth == 0 &&
              shouldReload &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            retrieveVocabularyList();
          }
          return false;
        },
      );
    } else if (keyword.isNotEmpty && searching) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = SingleChildScrollView(
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/launcher/icon_tired.png'),
              Text(keyword.isNotEmpty ? '找不到相關詞彙' : '輸入關鍵字尋找相關詞彙',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }
    final color = widget.destination.color;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.destination.title),
        backgroundColor: color,
      ),
      body: body,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: toggleSearch
            ? FloatingActionButton(
                backgroundColor: color,
                onPressed: () => setState(() {
                  toggleSearch = !toggleSearch;
                  controller.text = keyword;
                }),
                tooltip: '搜尋',
                child: const Icon(Icons.search),
              )
            : SizedBox(
                height: 55,
                width: MediaQuery.sizeOf(context).width * 0.9,
                child: RawMaterialButton(
                  padding: const EdgeInsets.only(left: 25),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(27.5)),
                  fillColor: color[200],
                  splashColor: color[200],
                  elevation: 2.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 7,
                        child: TextField(
                          autofocus: true,
                          controller: controller,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: Colors.white),
                            hintText: '輸入關鍵字',
                          ),
                          onChanged: (text) {
                            keyword = text;
                            refresh();
                          },
                        ),
                      ),
                      const Expanded(
                        flex: 1,
                        child: Icon(Icons.arrow_forward, color: Colors.white),
                      ),
                    ],
                  ),
                  onPressed: () => setState(() => toggleSearch = !toggleSearch),
                ),
              ),
      ),
    );
  }
}
