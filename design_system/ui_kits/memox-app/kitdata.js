// One recursive tree. Every level is the same shape, because the app renders
// every level with the same screen: a deck is a deck whether it sits at the root
// or six levels down.
//
// The redesign adds one field, `learned`, because progress is what the interface
// is now organised around and a count of cards does not answer "how far am I"
// without the reader doing arithmetic.
function deck(id, name, cards, learned, due, scheduler, children) {
  return { id, name, cards, learned, due, scheduler, children: children || [] };
}

window.MEMOX_TREE = deck('root', 'Library', 868, 421, 15, null, [
  deck('awl', 'Academic Word List', 570, 354, 12, '8 boxes', [
    deck('awl1', 'Sublist 1 — analyse, approach, area', 60, 44, 5, '8 boxes', [
      deck('awl1a', 'Nouns', 24, 18, 3, '8 boxes'),
      deck('awl1b', 'Verbs', 21, 16, 2, '8 boxes'),
      deck('awl1c', 'Adjectives', 15, 15, 0, '8 boxes'),
    ]),
    deck('awl2', 'Sublist 2 — achieve, acquire, administrate', 60, 60, 0, '8 boxes'),
    deck('awl3', 'Sublist 3 — alternative, circumstance, comment', 60, 22, 7, '8 boxes'),
  ]),
  deck('ielts', 'IELTS Writing Task 2', 210, 67, 3, 'SM-2', [
    deck('ielts-link', 'Linking phrases', 84, 51, 3, 'SM-2'),
    deck('ielts-topic', 'Topic vocabulary', 126, 16, 0, 'SM-2'),
  ]),
  deck('phrasal', 'Phrasal verbs', 88, 88, 0, '8 boxes'),
  deck('email', 'Business email', 0, 0, 0, 'SM-2'),
]);

window.MEMOX_STATS = { streakDays: 7, reviewedThisWeek: 214, bestStreak: 23, minutesToday: 12 };

window.MEMOX_CARDS = [
  { front: 'ephemeral', part: 'adjective · lasting for a very short time', example: '“Fashions are ephemeral: new ones regularly displace the old.”' },
  { front: 'ubiquitous', part: 'adjective · present everywhere at once', example: '“Smartphones are ubiquitous in the classroom.”' },
  { front: 'salient', part: 'adjective · most noticeable or important', example: '“She summarised the salient points of the paper.”' },
  { front: 'tenuous', part: 'adjective · very weak or slight', example: '“The link between the two studies is tenuous.”' },
];
