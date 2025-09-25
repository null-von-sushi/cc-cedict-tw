# CC-CEDICT-TW / 自由詞典

**An attempt to make a dictionary that doesn't ratify the vocabulary or pronounciations of the People's Republic of China, but instead uses vocabulary often found in free areas.**

This project is based on the CC-CEDICT dataset, but it diverges in significant ways to better align with Mandarin pronunciation, usage and vocabulary spoken in the Republic of China (Taiwan), Hong Kong and overseas communities,  Its primary goal is to offer an alternative to the PRC-centric resources that dominate the field of Mandarin dictionaries.

---

## Key Differences and Goals

This dictionary has the following main differences and goals compared to the original CC-CEDICT:

- **Pronunciation from the Republic of China (Taiwan)**: Where applicable, the dictionary uses pronunciation standards from Taiwan, as opposed to the the People's Republic of China (PRC) standard.
- **Incorporation of International Slang and Neologisms**: New terms and slang, especially those used by international communities (e.g., BBC, ABC, or similar), will be included. This may also include loanwords from Cantonese or Japanese.
- **Edited Definitions**: Some definitions have been edited to reflect the Taiwanese usage of words. While most entries remain unchanged, new words have been added and existing ones may have Taiwan-centric definitions as the default, with PRC usage as a sidenote. For specific changes, refer to the commit history.
- **U8 File Format Compatibility**: The file format for this dictionary follows the [CC-CEDICT format](https://cc-cedict.org/wiki/format:syntax), with minor modifications:
  - `lv` for lü, not `lu:`.
  - `nv` for `nü`, not `nv:`.
  - `lve` for `lüe`, not `lu:e`.
  
If you need to convert the file back to be compatible with CC-CEDICT’s upstream format, it’s easy to do using a text editor with a simple search-and-replace operation.

---

## Purpose and Disclaimer

This project is not officially endorsed by any organization or government. It was created out of personal interest as a response to the prevalence of PRC-centric dictionaries and lack of ROC focused ones. This is my attempt to balanced the scales and offer learners of 正題國語 a more useful reference. If this project doesn't align with your interests, feel free to use the upstream CC-CEDICT, Pleco, Hanping, or any of the other many mainland China-focused resources available.

---

## Style Guide and Common Abbreviations

To maintain consistency with existing conventions in CC-CEDICT or similar dictionaries, the following style guidelines are used:

- **Default lowercase**: As is common in CC-CEDICT and similar dictionaries, words are written in lowercase by default.
- **Pronunciation Labels**:
  - `PRC pr.` or `(PRC)` indicates the pronunciation or usage in mainland China (officially the People’s Republic of China).
  - `TW pr.` or `(TW)` indicates the pronunciation used in Taiwan (Republic of China). This should be relatively to see, as Taiwanese pronunciation will be considered standard.
- **Singapore Usage etc.**: The label `(mainly Singapore)` in CC-CEDICT is deprecated. We use `(Singapore)` for consistency with the PRC-related entries (other locations should be labelled `(location name)`).
- **Slang and Neologisms**:
  - `(slang)` denotes informal, colloquial terms.
  - `(neologism)` indicates newly created or coined words.
- **Source Language**: `(from XXX)` is used to indicate terms borrowed from another language (e.g., Cantonese, Japanese, Taiwanese).
- **Counters**: When applicable, counters are placed at the end of the line, separated by a Western comma (e.g., `新聞 新闻 [xin1 wen2] /news/CL:條|条[tiao2],個|个[ge4]/`).

---

## License

This project, due to its use of the [CC-CEDICT](https://www.mdbg.net/chinese/dictionary?page=cc-cedict) dataset, is licensed under the **Creative Commons Attribution-ShareAlike 4.0 International License**. 

### License Details:
- **Attribution**: You are free to use the data for both non-commercial and commercial purposes, but you must attribute the source.
- **ShareAlike**: If you modify or add to the data, you must share these changes under the same license.

For more details, see the [full license](https://creativecommons.org/licenses/by-sa/4.0/).

---

## Acknowledgments

Special thanks to the contributors of [CC-CEDICT](https://www.mdbg.net/chinese/dictionary?page=cc-cedict) for providing the base dataset.
Also a shoutout to pleco for basically being the best dictionary that exists so far. 

---
