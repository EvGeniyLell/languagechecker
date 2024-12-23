library;

import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:languagechecker/src/common/common.dart';
import 'package:languagechecker/src/get_localizations_strategies/get_android_xml_localizations_strategy/dtos/dtos.dart';
import 'package:languagechecker/src/get_localizations_strategies/get_localizations_strategy.dart';
import 'package:path/path.dart' as path;
import 'package:xml2json/xml2json.dart';

import '../../common/utils/json_map.dart';

class GetAndroidXmlLocalizationsStrategy extends GetLocalizationsStrategy {
  const GetAndroidXmlLocalizationsStrategy();

  @override
  Task<LocalizationBundle> call(String filepath) {
    return runTaskSafely(() async {
      final jsonMap = await jsonFromFile(filepath);
      final dto = LocalizationDto.fromJson(jsonMap);
      final languageKey = getLanguageKeyFromFileName(filepath);
      final bo = dto.toBo(languageKey: languageKey);
      return [bo];
    });
  }

  /// Load the json map from the file.
  @visibleForTesting
  Future<Map<String, dynamic>> jsonFromFile(String filepath) async {
    final rawContent =
        await File(filepath).toDirectoryCurrentPathRelated().readAsString();
    final xml = Xml2Json()..parse(rawContent);
    final jsonStringContent = xml.toGData();
    final jsonContent = jsonDecode(jsonStringContent);
    makeArray(jsonContent);
    return jsonContent as Map<String, dynamic>;
  }

  /// Make sure that the resources are arrays.
  ///
  /// - Reason: the `toGData` in `xml2json` library
  /// does not convert single elements into arrays,
  /// but the `Android:LocalizationDto` expects them to be arrays.
  @visibleForTesting
  void makeArray(Map<String, dynamic> map) {
    R? get<R>(Map<String, dynamic> m, String key) {
      if (m.containsKey(key)) {
        return m[key] as R;
      }
      return null;
    }

    final Map<String, dynamic> resources = get(map, 'resources');
    final string = get(resources, 'string');
    if (string is! List) {
      resources['string'] = [string];
    }
    final plurals = get(resources, 'plurals');
    if (plurals is! List) {
      resources['plurals'] = [plurals];
    }
  }

  /// Extract the language key from the file name.
  @visibleForTesting
  String getLanguageKeyFromFileName(String filepath) {
    final name = path.basenameWithoutExtension(filepath);
    final language = RegExp(r'_(\w{2})$').firstMatch(name)?.group(1);
    return language ?? 'en';
  }
}