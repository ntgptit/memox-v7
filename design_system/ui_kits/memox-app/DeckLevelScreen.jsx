const { MxContentShell, MxIconButton, MxIcon, MxCard, MxBreadcrumb, MxPillButton, MxEmptyState, MxProgressBar, MxActionButton, MxSearchField, MxActionSheet, MxTextButton } = window.MemoxDesignSystem_3a620f;

/** The four orders, and the glyph each gets in the sheet. */
const SORT_LABELS = { recent: 'Recently studied', name: 'Name', cardsDue: 'Cards due', progress: 'Progress' };
/** The same orders, named in the room a heading row has — under 96px with the glyph. */
const SORT_SHORT = { recent: 'Recent', name: 'Name', cardsDue: 'Due', progress: 'Progress' };
const SORT_ICONS = { recent: 'schedule', name: 'sort_by_alpha', cardsDue: 'event_available', progress: 'donut_small' };

/**
 * The deck list — ONE screen, used at every depth of the tree. The root is not a
 * special case: it is this screen with an empty ancestor path.
 *
 * Three things make a nested library usable, and all three live here:
 *   - a breadcrumb, pinned under the app bar, that folds its middle when deep
 *   - a search that walks the WHOLE subtree, not just the level in view
 *   - a compact summary panel whose resting figures fold behind a chevron
 */
function DeckLevelScreen({ path, onOpen, onUp, onJumpTo, onNavigate, onActions, onRowActions, onCreate, onStudy, isCompact }) {
  const [dueOnly, setDueOnly] = React.useState(false);
  // One of four orders, chosen from a sheet. It was a boolean behind a pill
  // that advanced on each tap — workable at two options and unusable at four,
  // because the order you want ends up one to three taps away and the list
  // re-sorts under the finger on every one of them.
  const [sort, setSort] = React.useState('recent');
  const [isSortSheetOpen, setSortSheetOpen] = React.useState(false);
  const [query, setQuery] = React.useState('');

  const deck = path[path.length - 1];
  const ancestors = path.slice(0, -1);
  const isRoot = ancestors.length === 0;

  // A new level starts a new search. Carrying the previous query down would show
  // results from a scope the user has already left.
  React.useEffect(() => { setQuery(''); }, [deck.id]);

  const searching = query.trim().length > 0;
  const results = React.useMemo(() => (searching ? searchTree(deck, query.trim()) : []), [deck, query, searching]);

  const all = deck.children || [];
  let rows = dueOnly ? all.filter((r) => r.due > 0) : all;
  rows = [...rows].sort((a, b) => {
    if (sort === 'name') return a.name.localeCompare(b.name);
    if (sort === 'cardsDue') return b.due - a.due;
    // Fraction, not count: a 900-card deck at 90% has more cards left than a
    // 20-card deck at 10% and is nonetheless the one closer to done.
    if (sort === 'progress') return (a.cards ? a.learned / a.cards : 0) - (b.cards ? b.learned / b.cards : 0);
    return 0;
  });

  const totalDue = all.reduce((n, r) => n + r.due, 0);
  // The panel or nothing. The dismiss button and the link that brought a
  // dismissed panel back are both gone (owner decision, 2026-08-25); what is
  // left is the rule the old 'auto' default already followed — a level with
  // work waiting gets the panel, a level without gets the list.
  const summaryOpen = totalDue > 0;

  return (
    <MxContentShell
      title={deck.name}
      leading={isRoot ? null : <MxIconButton icon="arrow_back" filled semanticLabel="Back" onClick={onUp} />}
      actions={
        // **Create is an app-bar action, not a floating one.** A button that
        // hovers over the bottom-right of a scrolling list covers whatever row
        // is there, and on a deck card that is its overflow menu. No inset fixes
        // it: an inset reserves the END of the scroll, not the resting frame.
        // Nothing floats now, so nothing can be covered — at the cost of the
        // primary action leaving the thumb's reach.
        <React.Fragment>
          {searching ? null : <MxIconButton icon="add" filled semanticLabel={isRoot ? 'Create deck' : 'Create sub-deck'} onClick={onCreate} />}
          {isRoot ? null : <MxIconButton icon="more_vert" filled semanticLabel="Deck actions" onClick={onActions} />}
        </React.Fragment>
      }
      subheader={
        <React.Fragment>
          {/* Every level, the library included — where it is the single Root
              step, and not a link, because tapping it would go to the screen you
              are already on. The strip is what answers "where am I", and a
              control that is absent at the top of the tree is a control the
              reader concludes is broken. */}
          <MxBreadcrumb
            semanticLabel="Deck path"
            rootIcon="home"
            // "Root" names the top of the TREE, not the screen that lists it: a
            // first step reading "Decks" under an app bar also reading "Decks"
            // looked like a link back to where the reader already was.
            //
            // The last step is the deck you are standing in and carries no onTap
            // — it is where you already are, so it reads as text. It repeats the
            // app-bar title on purpose: a strip that stopped at the parent left
            // the reader working out whether the title was part of the path.
            items={[
              { label: 'Root', onTap: isRoot ? undefined : () => onJumpTo(0) },
              ...ancestors.slice(1).map((a, i) => ({ label: a.name, onTap: () => onJumpTo(i + 1) })),
              ...(isRoot ? [] : [{ label: deck.name }]),
            ]}
          />
          <MxSearchField
            value={query}
            onChange={setQuery}
            placeholder={isRoot ? 'Search your whole library' : 'Search in ' + deck.name}
            resultCount={searching ? results.length : undefined}
          />
        </React.Fragment>
      }
      isScrollable
      isCompact={isCompact}
    >
      <div style={{ paddingBottom: 96 }}>
        {searching ? (
          <SearchResults results={results} query={query.trim()} scope={isRoot ? 'your library' : deck.name} onNavigate={onNavigate} onClear={() => setQuery('')} />
        ) : (
          <React.Fragment>
            {summaryOpen
              ? <LevelSummary deck={deck} isRoot={isRoot} totalDue={totalDue} onStudy={onStudy} />
              : null}

            {/* The heading and its one control. The sort lost its pill: at
                149.8px on a 393 screen it was 41.5% of the row against an
                88.6px heading, so the adjustment outweighed the thing it
                named (owner review, 2026-08-25). A glyph cannot say
                "recently studied", so the order it is in lives on the
                sheet's tick and in the control's own label. */}
            <div className="mx-deckhead" style={{ margin: (summaryOpen ? 'var(--space-md)' : '0') + ' 0 var(--space-md)' }}>
              <p className="mx-deckhead__label">{isRoot ? 'Your decks' : 'Sub-decks'}</p>
              {/* The filter keeps its pill here and has none in the app, where
                  it moved into the bar's overflow menu. A recorded divergence:
                  this kit has no overflow to move it into, and a control with
                  no way to turn it back ON is worse than one that differs. */}
              <MxPillButton label={dueOnly ? 'Due only' : 'All'} icon="filter_list" isSelected={dueOnly} onClick={() => setDueOnly(!dueOnly)} />
              <span className="mx-deckhead__sort">
                <MxTextButton
                  label={SORT_SHORT[sort]}
                  icon="swap_vert"
                  isCompact
                  semanticLabel={'Sort decks. Currently ' + SORT_SHORT[sort]}
                  onClick={() => setSortSheetOpen(true)}
                />
              </span>
            </div>

            {isSortSheetOpen ? (
              <MxActionSheet
                title="Sort decks by"
                onDismiss={() => setSortSheetOpen(false)}
                actions={Object.keys(SORT_LABELS).map((key) => ({
                  label: SORT_LABELS[key],
                  icon: SORT_ICONS[key],
                  isSelected: key === sort,
                  onPress: () => { setSort(key); setSortSheetOpen(false); },
                }))}
              />
            ) : null}

            {/* `lg`, not `md`: the track seated on each card's base makes the
                bottom boundary loud, so a 12px gap after it reads as part of
                the card rather than the space between two. */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-lg)' }}>
              {rows.length === 0
                ? <LevelEmpty dueOnly={dueOnly} isRoot={isRoot} onShowAll={() => setDueOnly(false)} onCreate={onCreate} />
                : rows.map((r) => <DeckCard key={r.id} summary={r} onOpen={() => onOpen(r)} onActions={onRowActions} onStudy={() => onStudy(r)} />)}
            </div>
          </React.Fragment>
        )}
      </div>
    </MxContentShell>
  );
}

/**
 * Depth-first walk of everything under `root`, returning each match with the
 * path that leads to it. The path is the whole point: in a nested library three
 * sub-decks can be called "Nouns", and a result list of bare names is a list of
 * identical rows.
 *
 * Shallow matches come first, so a deck whose own name matches outranks one
 * buried six levels down.
 */
function searchTree(root, query) {
  const q = query.toLowerCase();
  const out = [];
  (function walk(node, trail) {
    for (const child of node.children || []) {
      const nextTrail = [...trail, child];
      if (child.name.toLowerCase().includes(q)) out.push({ deck: child, trail: nextTrail, depth: nextTrail.length });
      walk(child, nextTrail);
    }
  })(root, []);
  return out.sort((a, b) => a.depth - b.depth || a.deck.name.localeCompare(b.deck.name));
}

function SearchResults({ results, query, scope, onNavigate, onClear }) {
  if (results.length === 0) {
    return <MxEmptyState icon="search_off" title={'No decks match “' + query + '”'} message={'Nothing in ' + scope + ' has that in its name.'} actionLabel="Clear search" onAction={onClear} />;
  }
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-sm)' }}>
      <p className="mx-section-label">{results.length} {results.length === 1 ? 'match' : 'matches'} in {scope}</p>
      {results.map((r) => (
        <button type="button" key={r.deck.id} className="mx-result" onClick={() => onNavigate(r.trail)}>
          <MxIcon name={(r.deck.children || []).length ? 'folder' : 'style'} color="var(--color-text-secondary)" style={{ marginTop: 2 }} />
          <span style={{ flex: 1, minWidth: 0 }}>
            {r.trail.length > 1 ? <span className="mx-result__path">{r.trail.slice(0, -1).map((t) => t.name).join(' › ')}</span> : null}
            <span className="mx-result__name">{highlight(r.deck.name, query)}</span>
            <span className="mx-result__meta">
              {r.deck.cards} cards
              {r.deck.due > 0 ? <React.Fragment>{' · '}<b style={{ color: 'var(--color-warning)' }}>{r.deck.due} due</b></React.Fragment> : null}
            </span>
          </span>
          <MxIcon name="north_east" filled size="var(--icon-sm)" color="var(--color-text-secondary)" style={{ marginTop: 4 }} />
        </button>
      ))}
    </div>
  );
}

/** Marks the matched run so the user can see WHY a row came back. */
function highlight(text, query) {
  const i = text.toLowerCase().indexOf(query.toLowerCase());
  if (i < 0) return text;
  return (
    <React.Fragment>
      {text.slice(0, i)}<mark>{text.slice(i, i + query.length)}</mark>{text.slice(i + query.length)}
    </React.Fragment>
  );
}

/**
 * At the root this is "today"; deeper down it is this deck's own progress. Both
 * answer the same question, so they are one block rather than a home screen and
 * a header.
 *
 * **Two rows and a rule** (owner review, 2026-08-25). It was five stacked bands
 * and measured 37.6% of a 393x852 viewport, which left one and a half deck
 * cards above the fold. What went is ranking, not data: the `TODAY` eyebrow
 * said nothing "cards due" does not, and the learned caption is a resting
 * figure that sits one chevron away rather than at the top of every visit.
 *
 * **It is no longer dismissible, and that is the same decision.** The close
 * button existed because the panel was in the way of the list; at 18% it is
 * not, and one chevron cannot mean "hide me" and "show me more".
 */
function LevelSummary({ deck, isRoot, totalDue, onStudy }) {
  const [isExpanded, setIsExpanded] = React.useState(false);
  const learned = deck.cards ? deck.learned / deck.cards : 0;
  return (
    <div className="mx-today">
      <div className="mx-today__row">
        <span className="mx-today__figures">
          <span className="mx-today__figure" style={totalDue ? undefined : { color: 'var(--color-success)' }}>{totalDue ? totalDue : 'All'}</span>
          <span className="mx-today__word">{totalDue ? 'cards due' : 'caught up'}</span>
          {isRoot ? (
            <span className="mx-streak mx-today__sub">
              <MxIcon name="local_fire_department" filled size="var(--icon-sm)" />
              {window.MEMOX_STATS.streakDays}
            </span>
          ) : null}
        </span>
        <button
          type="button"
          className="mx-today__disclose"
          onClick={() => setIsExpanded(!isExpanded)}
          aria-expanded={isExpanded}
          aria-label={isExpanded ? 'Show fewer figures' : 'Show more figures'}
          title={isExpanded ? 'Show fewer figures' : 'Show more figures'}
        >
          <MxIcon name={isExpanded ? 'expand_less' : 'expand_more'} filled size="var(--icon-sm)" />
        </button>
      </div>
      {/* Collapsed it is a bare 4px rule under the figure line — a bar there
          does not need to be told what it measures. The strings are still
          passed: a screen reader has no chevron, so what is painted and what is
          announced are two decisions. */}
      <MxProgressBar value={learned} label={deck.learned + ' of ' + deck.cards + ' learned'} valueLabel={Math.round(learned * 100) + '%'} size="sm" isLabelPainted={isExpanded} />
      {totalDue ? <MxActionButton label="Start studying" icon="play_arrow" isBlock onClick={() => onStudy(deck)} /> : null}
    </div>
  );
}

/** Three different empties, because "filtered out", "nothing created" and "leaf deck" are three different situations. */
function LevelEmpty({ dueOnly, isRoot, onShowAll, onCreate }) {
  if (dueOnly) return <MxEmptyState title="Nothing due here" message="Every deck at this level is up to date." actionLabel="Show all" onAction={onShowAll} />;
  if (isRoot) return <MxEmptyState icon="folder" title="No decks yet" message="Create one to start building your library." actionLabel="Create deck" onAction={onCreate} />;
  return <MxEmptyState icon="style" title="No sub-decks" message="This deck holds its cards directly." actionLabel="Create sub-deck" onAction={onCreate} />;
}

/**
 * The redesigned deck card. The whole card opens the deck; two controls sit on
 * top of it and mean something else:
 *   open  — the card, all of it
 *   study — an explicit pill, present only when there is something to study
 *   menu  — everything else
 *
 * **It does not wrap its own header in a button.** It did, and the result was a
 * card whose hover lit up only the top band while the progress bar and the foot
 * looked tappable and were not. `MxCard onClick` puts the target under the whole
 * card, which is why that arrangement is possible at all — see its prompt note.
 */
function DeckCard({ summary, onOpen, onActions, onStudy }) {
  const due = summary.due > 0;
  const nested = (summary.children || []).length;
  const learned = summary.cards ? summary.learned / summary.cards : 0;
  const complete = summary.cards > 0 && summary.learned === summary.cards;

  return (
    <MxCard elevation="none" padding="0" onClick={onOpen} actionLabel={'Open ' + summary.name}>
      <div className="mx-deck__open">
        <span className="mx-deck__well" style={complete ? { background: 'var(--color-surface-muted)', color: 'var(--color-success)' } : undefined}>
          <MxIcon name={complete ? 'check_circle' : (nested ? 'folder' : 'style')} filled={complete} />
        </span>
        <span style={{ flex: 1, minWidth: 0 }}>
          <span className="mx-deck__name">{summary.name}</span>
          <span className="mx-deck__meta">
            {nested ? nested + ' sub-decks · ' : ''}{summary.cards} cards · {summary.scheduler}
          </span>
        </span>
        <span className="mx-deck__menu mx-card__control">
          <MxIconButton icon="more_vert" filled semanticLabel={'Actions for ' + summary.name} onClick={() => onActions(summary)} />
        </span>
      </div>

      {/* The verbs, and only the verbs. The menu sits with the deck's identity
          above; this row carries what a user DOES with the deck, so it is a
          32px pill row rather than a 48px icon-button row. */}
      <div className="mx-deck__foot">
        <span className="mx-deck__bar">
          {due
            ? <span className="mx-deck__due"><MxIcon name="schedule" filled size={14} />{summary.due} due now</span>
            : <span style={{ fontSize: 'var(--text-label-sm)', letterSpacing: 'var(--tracking-label-sm)', color: 'var(--color-text-secondary)' }}>{summary.cards ? 'Nothing due' : 'No cards yet'}</span>}
        </span>
        {due ? (
          <button type="button" className="mx-deck__study mx-card__control" onClick={onStudy} aria-label={'Study ' + summary.due + ' cards in ' + summary.name} title="Study now">
            <MxIcon name="play_arrow" filled size={16} />Study
          </button>
        ) : null}
        {/* The slot Study leaves empty is filled by a fact, never by a disabled
            button: "nothing due" is good news (BR-29), and a greyed control
            says you cannot do the thing when there is nothing to do. */}
        {!due && summary.cards ? (
          <span className={'mx-deck__figure' + (complete ? ' mx-deck__figure--complete' : '')}>{Math.round(learned * 100)}%</span>
        ) : null}
      </div>

      {/* The track is the card's BASE, not a rule across its middle. In the
          middle it cut the card in two; on the edge it is what the card stands
          on. `--flush` squares its ends so the card's own corner is the only
          rounding — a pill end inside a 16px corner reads as a lozenge tucked
          into it. */}
      {summary.cards ? (
        <MxProgressBar value={learned} size="sm" shape="flush" />
      ) : null}
    </MxCard>
  );
}

Object.assign(window, { DeckLevelScreen, DeckCard, LevelSummary, LevelEmpty, SearchResults, searchTree });
