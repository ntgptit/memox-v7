const { MxContentShell, MxIconButton, MxIcon, MxCard, MxBreadcrumb, MxPillButton, MxEmptyState, MxProgressBar, MxActionButton, MxSearchField, MxTextButton } = window.MemoxDesignSystem_3a620f;

/**
 * The deck list — ONE screen, used at every depth of the tree. The root is not a
 * special case: it is this screen with an empty ancestor path.
 *
 * Three things make a nested library usable, and all three live here:
 *   - a breadcrumb, pinned under the app bar, that folds its middle when deep
 *   - a search that walks the WHOLE subtree, not just the level in view
 *   - a summary panel that can be dismissed when it is in the way
 */
function DeckLevelScreen({ path, onOpen, onUp, onJumpTo, onNavigate, onActions, onRowActions, onCreate, onStudy, isCompact }) {
  const [dueOnly, setDueOnly] = React.useState(false);
  const [byName, setByName] = React.useState(true);
  const [query, setQuery] = React.useState('');
  // 'auto' follows the level's due count; 'shown' and 'hidden' are the user
  // overriding it, and neither returns to 'auto' — both are saying "from now on".
  // It defaulted to open, which meant every level with nothing due opened a panel
  // whose only content was that nothing was due, and then asked to be dismissed.
  const [summaryChoice, setSummaryChoice] = React.useState('auto');

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
  rows = [...rows].sort((a, b) => (byName ? a.name.localeCompare(b.name) : b.due - a.due));

  const totalDue = all.reduce((n, r) => n + r.due, 0);
  const summaryOpen = summaryChoice === 'auto' ? totalDue > 0 : summaryChoice === 'shown';

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
              ? <LevelSummary deck={deck} isRoot={isRoot} totalDue={totalDue} onStudy={onStudy} onDismiss={() => setSummaryChoice('hidden')} />
              : null}

            <div style={{ display: 'flex', alignItems: 'center', gap: 'var(--space-sm)', margin: (summaryOpen ? 'var(--space-xl)' : '0') + ' 0 var(--space-md)' }}>
              <p className="mx-section-label" style={{ margin: 0, flex: 1 }}>{isRoot ? 'Your decks' : 'Sub-decks'}</p>
              <MxPillButton label={dueOnly ? 'Due only' : 'All'} icon="filter_list" isSelected={dueOnly} onClick={() => setDueOnly(!dueOnly)} />
              <MxPillButton label={byName ? 'A–Z' : 'Due first'} icon="swap_vert" isSelected={!byName} semanticLabel={byName ? 'Sort by name' : 'Sort by cards due'} onClick={() => setByName(!byName)} />
            </div>

            {summaryOpen ? null : (
              <div style={{ marginBottom: 'var(--space-md)' }}>
                <MxTextButton label="Show today’s summary" trailingIcon="expand_more" onClick={() => setSummaryChoice('shown')} />
              </div>
            )}

            <div style={{ display: 'flex', flexDirection: 'column', gap: 'var(--space-md)' }}>
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
 * a header. Dismissible, because on a day spent reorganising decks it is in the
 * way of the list it sits on top of.
 */
function LevelSummary({ deck, isRoot, totalDue, onStudy, onDismiss }) {
  const learned = deck.cards ? deck.learned / deck.cards : 0;
  return (
    <div className="mx-today">
      <button type="button" className="mx-today__close" onClick={onDismiss} aria-label="Hide summary" title="Hide summary">
        <MxIcon name="close" filled size="var(--icon-sm)" />
      </button>
      <div className="mx-today__row">
        <span style={{ flex: 1, minWidth: 0, paddingRight: 'var(--space-xl)' }}>
          <span className="mx-today__figure" style={totalDue ? undefined : { color: 'var(--color-success)' }}>{totalDue ? totalDue : 'All'}</span>
          <span className="mx-today__sub">
            {totalDue
              ? (isRoot ? 'cards due across your library today' : 'cards due in this deck today')
              : 'caught up — nothing due here today'}
          </span>
        </span>
        {isRoot ? (
          <span className="mx-streak" style={{ marginTop: 28 }}>
            <MxIcon name="local_fire_department" filled size="var(--icon-sm)" />
            {window.MEMOX_STATS.streakDays}
          </span>
        ) : null}
      </div>
      <MxProgressBar value={learned} label={deck.learned + ' of ' + deck.cards + ' learned'} valueLabel={Math.round(learned * 100) + '%'} size="sm" />
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
        {nested ? <MxIcon name="chevron_right" filled size="var(--icon-sm)" color="var(--color-text-secondary)" style={{ marginTop: 4 }} /> : null}
      </div>

      {summary.cards ? (
        <div style={{ padding: '0 var(--space-lg) var(--space-md)' }}>
          <MxProgressBar value={learned} label={summary.learned + ' of ' + summary.cards + ' learned'} valueLabel={Math.round(learned * 100) + '%'} size="sm" />
        </div>
      ) : null}

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
        <span className="mx-deck__menu mx-card__control">
          <MxIconButton icon="more_vert" filled semanticLabel={'Actions for ' + summary.name} onClick={() => onActions(summary)} />
        </span>
      </div>
    </MxCard>
  );
}

Object.assign(window, { DeckLevelScreen, DeckCard, LevelSummary, LevelEmpty, SearchResults, searchTree });
