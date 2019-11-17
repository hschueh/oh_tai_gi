import 'package:flutter_test/flutter_test.dart';
import 'package:oh_tai_gi/db/vocabulary.dart';
import 'dart:convert';

void main() {
  group('Vocabulary', () {
    test('Test: Parse single vocabulary.', () {
      Vocabulary v = Vocabulary.fromString("""
        {
          "title": "㔂",
          "radical": "刀",
          "heteronyms": [
            {
              "id": "13511",
              "trs": "lân",
              "reading": "替",
              "definitions": [
                {
                  "type": "動",
                  "def": "削掉外皮或突出的枝椏部分。",
                  "example": [
                    "￹㔂甘蔗￺lân kam-tsià￻削掉甘蔗的外皮節眼、籜葉"
                  ]
                }
              ]
            }
          ],
          "stroke_count": 14,
          "non_radical_stroke_count": 12
        }
        """);

        expect(v.title, "㔂");
        expect(v.learnt, 0);
        expect(v.heteronyms.length, 1);
        expect(v.heteronyms[0].definitions.length, 1);
    });

    test('Test: Parse single vocabulary with multiple heteronyms.', () {
      Vocabulary v = Vocabulary.fromString("""
        {
          "title": "世",
          "radical": "一",
          "heteronyms": [
            {
              "id": "1302",
              "trs": "sè",
              "reading": "文",
              "definitions": [
                {
                  "type": "名",
                  "def": "三十年為一世，引申為世代。",
                  "example": [
                    "￹世交￺sè-kau￻兩代以上的交誼"
                  ]
                },
                {
                  "type": "名",
                  "def": "人間。",
                  "example": [
                    "￹世事￺sè-sū￻",
                    "￹世局￺sè-kio̍k￻"
                  ]
                }
              ]
            },
            {
              "id": "1303",
              "trs": "sì",
              "reading": "白",
              "definitions": [
                {
                  "type": "名",
                  "def": "三十年為一世，常引申為一生。",
                  "example": [
                    "￹一世人￺tsi̍t-sì-lâng￻一輩子"
                  ]
                },
                {
                  "type": "名",
                  "def": "人間。",
                  "example": [
                    "￹出世￺tshut-sì￻出生"
                  ]
                }
              ]
            }
          ],
          "stroke_count": 5,
          "non_radical_stroke_count": 4
        }
        """);

        expect(v.title, "世");
        expect(v.learnt, 0);
        expect(v.heteronyms.length, 2);
        expect(v.heteronyms[0].definitions.length, 2);
        expect(v.heteronyms[0].aid, 1302);
        expect(v.heteronyms[1].definitions.length, 2);
        expect(v.heteronyms[1].aid, 1303);
    });

    test('Test: Parse multiple vocabulary.', () {
      List<Vocabulary> vs = json.decode("""
        [
          {
            "title": "㔂",
            "radical": "刀",
            "heteronyms": [
              {
                "id": "13511",
                "trs": "lân",
                "reading": "替",
                "definitions": [
                  {
                    "type": "動",
                    "def": "削掉外皮或突出的枝椏部分。",
                    "example": [
                      "￹㔂甘蔗￺lân kam-tsià￻削掉甘蔗的外皮節眼、籜葉"
                    ]
                  }
                ]
              }
            ],
            "stroke_count": 14,
            "non_radical_stroke_count": 12
          },
          {
            "title": "㤉",
            "radical": "心",
            "heteronyms": [
              {
                "id": "13493",
                "trs": "gê",
                "reading": "替",
                "synonyms": "㤉潲",
                "definitions": [
                  {
                    "type": "動",
                    "def": "討厭、嫌惡。",
                    "example": [
                      "￹看著這款人就㤉。￺Khuànn-tio̍h tsit khuán lâng tō gê. ￻看到這種人就討厭。"
                    ]
                  }
                ]
              }
            ],
            "stroke_count": 7,
            "non_radical_stroke_count": 4
          }
        ]
        """).map<Vocabulary>((json) => Vocabulary.fromJson(json)).toList();

        expect(vs[0].title, "㔂");
        expect(vs[0].learnt, 0);
        expect(vs[0].heteronyms.length, 1);
        expect(vs[0].heteronyms[0].aid, 13511);
        expect(vs[0].heteronyms[0].definitions.length, 1);
        expect(vs[1].title, "㤉");
        expect(vs[1].learnt, 0);
        expect(vs[1].heteronyms.length, 1);
        expect(vs[1].heteronyms[0].aid, 13493);
        expect(vs[1].heteronyms[0].definitions.length, 1);
    });

    test('Test: Parse vocabulary with audio_id.', () {
      Vocabulary v = Vocabulary.fromString("""
        {
          "title": "三",
          "radical": "一",
          "stroke_count": 3,
          "non_radical_stroke_count": 2,
          "heteronyms": [
            {
              "audio_id": "13205",
              "id": "20006",
              "trs": "sàm",
              "reading": "文",
              "definitions": [
                {
                  "def": "介於二和四之間的自然數。如：「二、三、四、五……」。大寫作「参」，阿拉伯數字作「3」。"
                },
                {
                  "def": "姓。如明代有三成志。"
                },
                {
                  "def": "第三位的。"
                },
                {
                  "def": "表多數或多次的。"
                }
              ]
            }
          ]
        }
        """);

        expect(v.title, "三");
        expect(v.learnt, 0);
        expect(v.heteronyms.length, 1);
        expect(v.heteronyms[0].aid, 13205);
        expect(v.heteronyms[0].definitions.length, 4);
    });
  });
}