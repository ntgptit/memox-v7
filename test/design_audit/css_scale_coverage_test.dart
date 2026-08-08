import 'package:flutter_test/flutter_test.dart';

import 'css_tokens.dart';

/// **The half that catches a token nobody looked at.**
///
/// `css_scale_parity_test.dart` asserts values against a hand-written list, and
/// a hand-written list is silent about what is missing from it. That is how
/// `--text-title-lg-compact`, `--weight-medium`, `--nav-width-per-destination`
/// and all four shadow tokens sat outside parity while the file read as
/// complete — the values happened to agree, so nothing was wrong yet, and
/// nothing would have said so when it became wrong.
///
/// The colour side has had this check since M4.10ao. This is the same one over
/// the other six token files, split into its own file at the 400-line guard.
///
/// Two directions, because they fail for opposite reasons: a token declared in
/// the kit and unaccounted for here is drift arriving, and a name accounted for
/// here that the kit no longer declares is an explanation outliving the thing it
/// explained.
void main() {
  Set<String> declaredIn(String file) => <String>{
    ...CssTokens.names(file),
    ...CssTokens.names(file, scope: '[data-theme="dark"]'),
  };

  test('every scale token is asserted or explained', () {
    final unaccounted = <String>[];

    for (final file in _scaleFiles) {
      unaccounted.addAll(
        declaredIn(file)
            .where((name) => !_asserted.contains(name))
            .where((name) => !_notBroughtOver.containsKey(name))
            .map((name) => '$file $name'),
      );
    }

    unaccounted.sort();
    expect(
      unaccounted,
      isEmpty,
      reason:
          'Declared in design_system/tokens/ and the app has no position on '
          'them. Assert the value in css_scale_parity_test.dart and add the '
          'name to _asserted, or add it to _notBroughtOver with the '
          'reason.\n${unaccounted.join('\n')}',
    );
  });

  test('nothing is asserted or explained that the kit no longer declares', () {
    final declared = <String>{
      for (final file in _scaleFiles) ...declaredIn(file),
    };

    final stale = <String>[
      ..._asserted,
      ..._notBroughtOver.keys,
    ].where((name) => !declared.contains(name)).toList()..sort();

    expect(
      stale,
      isEmpty,
      reason: 'claimed here but no longer in the kit\n${stale.join('\n')}',
    );
  });

  test('the files this check reads are the files that exist', () {
    // Anti-vacuous, and the failure it guards is specific: a token file added
    // to `design_system/tokens/` and not to `_scaleFiles` is a whole file
    // outside parity, which both tests above would report as clean.
    //
    // `colors.css` is owned by `css_token_parity_test.dart`; `fonts.css`
    // declares `@font-face` rules rather than custom properties, so it has no
    // tokens to enumerate — its two families are asserted through
    // `--font-display` / `--font-body` in `typography.css`.
    expect(
      <String>{..._scaleFiles, 'colors.css', 'fonts.css'},
      CssTokens.tokenFileNames(),
      reason:
          'design_system/tokens/ holds a file no parity test has claimed, or '
          'this list names one that has been deleted',
    );

    for (final file in _scaleFiles) {
      expect(
        declaredIn(file),
        isNotEmpty,
        reason: '$file parsed to zero tokens — the parser or the file moved',
      );
    }
  });
}

/// The token files this check owns.
const List<String> _scaleFiles = <String>[
  'spacing.css',
  'radius.css',
  'layout.css',
  'elevation.css',
  'motion.css',
  'typography.css',
];

/// Every token with an assertion in `css_scale_parity_test.dart`.
const Set<String> _asserted = <String>{
  // spacing.css
  '--space-xs',
  '--space-sm',
  '--space-md',
  '--space-lg',
  '--space-xl',
  '--space-xxl',
  '--touch-target-min',
  '--icon-sm',
  '--icon-md',
  '--icon-md-compact',
  '--icon-lg',
  // radius.css
  '--radius-sm',
  '--radius-md',
  '--radius-lg',
  '--radius-xl',
  '--radius-pill',
  // layout.css
  '--breakpoint-compact',
  '--breakpoint-medium',
  '--nav-width-per-destination',
  // elevation.css
  '--elevation-none',
  '--elevation-card',
  '--elevation-raised',
  '--elevation-overlay',
  '--shadow-card',
  '--shadow-raised',
  '--shadow-overlay',
  '--border-hairline',
  '--border-input',
  '--border-focus',
  // motion.css
  '--duration-fast',
  '--duration-normal',
  '--duration-slow',
  '--ease-standard',
  '--ease-decelerate',
  // typography.css — the two faces
  '--font-display',
  '--font-body',
  // typography.css — the rungs
  '--text-display-lg', '--leading-display-lg',
  '--text-display-md', '--leading-display-md',
  '--text-display-sm', '--leading-display-sm',
  '--text-headline-lg', '--leading-headline-lg',
  '--text-card-prompt', '--leading-card-prompt', '--tracking-card-prompt',
  '--text-card-prompt-compact',
  '--text-headline-sm', '--leading-headline-sm',
  '--text-title-lg', '--leading-title-lg', '--text-title-lg-compact',
  '--text-title-md', '--leading-title-md', '--tracking-title-md',
  '--text-title-sm', '--leading-title-sm', '--tracking-title-sm',
  '--text-body-lg', '--leading-body-lg', '--tracking-body-lg',
  '--text-body-md', '--leading-body-md', '--tracking-body-md',
  '--text-body-sm', '--leading-body-sm', '--tracking-body-sm',
  '--text-label-lg', '--leading-label-lg', '--tracking-label-lg',
  '--text-label-md', '--leading-label-md', '--tracking-label-md',
  '--text-label-sm', '--leading-label-sm', '--tracking-label-sm',
  '--tracking-section-label',
  // typography.css — the four weights
  '--weight-regular', '--weight-medium', '--weight-semibold', '--weight-bold',
};

/// Scale tokens with no Dart counterpart, and why.
const Map<String, String> _notBroughtOver = <String, String>{
  '--shadow-none':
      'The absence of a shadow. `shadowsFor` returns an empty list at '
      '`AppElevation.none`, which is the same statement in the form Flutter '
      'takes — there is no value to compare.',
  '--frame-width':
      'The design kit previews its components inside a 420x1040 canvas. The '
      "app's own web frame is `kMobileFrameSize`, 393x852, which is a phone's "
      'logical size rather than a preview canvas — two frames for two jobs. '
      'Equating them would resize the E2E channel to match a design tool.',
  '--frame-height': 'See --frame-width.',
};
