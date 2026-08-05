import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../../card/domain/failures/card_validation_failure.dart';
import '../../../card/domain/models/card_text_model.dart';
import '../../domain/models/deck_name_model.dart';
import '../../domain/models/deck_template_model.dart';
import '../../domain/models/scheduler_type_model.dart';

/// Where the published templates live. One manifest naming the files, so adding
/// a template is one asset plus one line rather than a code change.
const String kDeckTemplateManifestAsset = 'assets/templates/manifest.json';
const String _templateAssetDirectory = 'assets/templates/';

/// Reads the starter templates the app ships (AD-07, BR-32).
///
/// **It validates rather than trusts.** Every name goes through [DeckName.parse]
/// and every card side through [CardText.parse], so a `DeckTemplate` cannot
/// exist unless it would pass the same rules a user's own input has to. An asset
/// that fails throws [DeckTemplateFormatException] naming the file and the field
/// — this is a build-time mistake by whoever edited the JSON, surfaced where a
/// developer sees it, not a `Failure` for the UI to render.
///
/// **Not a repository, and deliberately not behind the repository contract.**
/// It reads assets the app was built with; there is no database, no stream and
/// nothing to substitute for a backend later. `installDeckTemplates` takes the
/// parsed templates as an argument, which also means a test can install a
/// hand-built tree without an asset at all.
final class DeckTemplateDataSource {
  // Dart forbids a named parameter starting with an underscore, so the
  // initializing formal the lint wants cannot be written while the field
  // stays private — the same trade `DeckRepositoryImpl` documents.
  // ignore: prefer_initializing_formals
  const DeckTemplateDataSource({AssetBundle? bundle}) : _bundle = bundle;

  /// Null uses [rootBundle]. Injected in tests, which supply their own JSON
  /// instead of the shipped files.
  final AssetBundle? _bundle;

  AssetBundle get _assets => _bundle ?? rootBundle;

  /// Every template the manifest names, in manifest order.
  Future<List<DeckTemplate>> loadAll() async {
    final manifest = _decodeObject(
      await _assets.loadString(kDeckTemplateManifestAsset),
      kDeckTemplateManifestAsset,
    );
    final files = _stringList(
      manifest,
      'templates',
      kDeckTemplateManifestAsset,
    );

    final templates = <DeckTemplate>[];
    for (final file in files) {
      templates.add(await _load('$_templateAssetDirectory$file'));
    }

    return templates;
  }

  Future<DeckTemplate> _load(String asset) async {
    final json = _decodeObject(await _assets.loadString(asset), asset);

    return DeckTemplate(
      templateId: _string(json, 'template_id', asset),
      version: _int(json, 'version', asset),
      locale: _string(json, 'locale', asset),
      title: _deckName(_string(json, 'title', asset), asset, 'title'),
      contentSource: _string(json, 'content_source', asset),
      defaultSchedulerType: _scheduler(
        _string(json, 'default_scheduler_type', asset),
        asset,
      ),
      // A root holds sub-decks only (BR-58), so a template with no children
      // would install a root nothing could be added to by the copy path.
      children: _requireChildren(json, asset, 'children'),
    );
  }

  List<DeckTemplateNode> _requireChildren(
    Map<String, Object?> json,
    String asset,
    String field,
  ) {
    final nodes = _nodes(json, asset, field);
    if (nodes.isEmpty) {
      throw DeckTemplateFormatException(asset, '$field must not be empty');
    }

    return nodes;
  }

  List<DeckTemplateNode> _nodes(
    Map<String, Object?> json,
    String asset,
    String field,
  ) {
    final raw = json[field];
    if (raw == null) return const <DeckTemplateNode>[];
    if (raw is! List) {
      throw DeckTemplateFormatException(asset, '$field must be a list');
    }

    return raw
        .map((entry) => _node(_asObject(entry, asset, field), asset))
        .toList(growable: false);
  }

  DeckTemplateNode _node(Map<String, Object?> json, String asset) {
    final name = _deckName(_string(json, 'name', asset), asset, 'name');
    final children = _nodes(json, asset, 'children');
    final cards = _cards(json, asset);
    // BR-61/BR-62: a deck holds one kind of thing. Refusing both here is what
    // lets the install path write the tree without a single content check.
    if (children.isNotEmpty && cards.isNotEmpty) {
      throw DeckTemplateFormatException(
        asset,
        'deck "${name.value}" declares both children and cards',
      );
    }
    if (children.isNotEmpty) {
      return DeckTemplateNode.branch(name: name, children: children);
    }

    return DeckTemplateNode.leaf(name: name, cards: cards);
  }

  List<DeckTemplateCard> _cards(Map<String, Object?> json, String asset) {
    final raw = json['cards'];
    if (raw == null) return const <DeckTemplateCard>[];
    if (raw is! List) {
      throw DeckTemplateFormatException(asset, 'cards must be a list');
    }

    return raw
        .map((entry) {
          final card = _asObject(entry, asset, 'cards');
          final example = card['example'];

          return DeckTemplateCard(
            front: _cardText(
              _string(card, 'front', asset),
              CardSide.front,
              asset,
            ),
            back: _cardText(_string(card, 'back', asset), CardSide.back, asset),
            example: example == null
                ? null
                : _detailText('$example', asset, 'example'),
          );
        })
        .toList(growable: false);
  }

  DeckName _deckName(String raw, String asset, String field) {
    final parsed = DeckName.parse(raw);
    final name = parsed.name;
    if (name == null) {
      throw DeckTemplateFormatException(
        asset,
        '$field "$raw" is not a valid deck name (${parsed.problem})',
      );
    }

    return name;
  }

  CardText _cardText(String raw, CardSide side, String asset) {
    final parsed = CardText.parse(raw, side: side);
    final text = parsed.text;
    if (text == null) {
      throw DeckTemplateFormatException(
        asset,
        '${side.name} "$raw" is not valid card text (${parsed.problem})',
      );
    }

    return text;
  }

  /// Null for an example that is absent *or* blank — `CardDetailText.parse`
  /// reports both as "no text, no problem", and an empty string in the JSON is
  /// the same statement as leaving the key out. Only a real problem throws.
  CardDetailText? _detailText(String raw, String asset, String field) {
    final parsed = CardDetailText.parse(raw, field: CardDetailField.example);
    final problem = parsed.problem;
    if (problem != null) {
      throw DeckTemplateFormatException(
        asset,
        '$field "$raw" is not valid ($problem)',
      );
    }

    return parsed.text;
  }

  SchedulerType _scheduler(String raw, String asset) {
    final type = SchedulerType.fromDbValue(raw);
    // `fromDbValue` tolerates values from newer schemas by answering `unknown`,
    // which is right for reading a database written by a later app version and
    // wrong for an asset this build shipped: nothing can install with it.
    if (type == SchedulerType.unknown) {
      throw DeckTemplateFormatException(
        asset,
        'default_scheduler_type "$raw" is not a scheduler this build knows',
      );
    }

    return type;
  }

  Map<String, Object?> _decodeObject(String source, String asset) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, Object?>) {
      throw DeckTemplateFormatException(asset, 'root must be a JSON object');
    }

    return decoded;
  }

  Map<String, Object?> _asObject(Object? raw, String asset, String field) {
    if (raw is! Map<String, Object?>) {
      throw DeckTemplateFormatException(asset, '$field must hold JSON objects');
    }

    return raw;
  }

  String _string(Map<String, Object?> json, String field, String asset) {
    final value = json[field];
    if (value is! String || value.isEmpty) {
      throw DeckTemplateFormatException(
        asset,
        '$field must be a non-empty string',
      );
    }

    return value;
  }

  int _int(Map<String, Object?> json, String field, String asset) {
    final value = json[field];
    if (value is! int) {
      throw DeckTemplateFormatException(asset, '$field must be an integer');
    }

    return value;
  }

  List<String> _stringList(
    Map<String, Object?> json,
    String field,
    String asset,
  ) {
    final value = json[field];
    if (value is! List || value.isEmpty) {
      throw DeckTemplateFormatException(
        asset,
        '$field must be a non-empty list',
      );
    }

    return value.map((entry) => '$entry').toList(growable: false);
  }
}

/// A shipped asset the loader could not read.
///
/// An exception rather than a `Failure`: a `Failure` is something the UI shows a
/// user, and there is nothing a user can do about a malformed file inside the
/// app bundle. It names the asset and the field so the fix is obvious from the
/// message alone.
final class DeckTemplateFormatException implements Exception {
  const DeckTemplateFormatException(this.asset, this.problem);

  final String asset;
  final String problem;

  @override
  String toString() => 'DeckTemplateFormatException($asset): $problem';
}
