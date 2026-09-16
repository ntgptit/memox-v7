/* MemoX v2 — sample data, shaped like API_CONTRACT.md and taken from
   docs/claude-design/SAMPLE_DATA.json (clock: local 2026-09-16 09:30 +07:00).
   Card CONTENT is never localised — only UI copy is. */
(function () {

/* ── A1 · Library · top level (WatchDeckList parentDeckId: null) ── */
const rootDecks = [
  { id: 'd1', name: '한국어 TOPIK I · Từ vựng', contentType: 'deck', sched: 'sm2', gen: 1, locked: true,
    total: 1248, new: 312, due: 86, overdue: 41, overdueDays: 3, dueToday: 45, scheduled: 850, learned: 204, subDecks: 4, status: 'overdue', createdAt: '2025-10-12' },
  { id: 'd2', name: 'Tiếng Anh giao tiếp hằng ngày', contentType: 'deck', sched: 'eight_box', gen: 2, locked: true,
    total: 64, new: 0, due: 12, overdue: 0, overdueDays: 0, dueToday: 12, scheduled: 52, learned: 0, subDecks: 3, status: 'dueToday', createdAt: '2026-03-04' },
  { id: 'd6', name: 'IELTS Academic Word List', contentType: 'deck', sched: 'eight_box', gen: 1, locked: true,
    total: 10000, new: 7400, due: 1260, overdue: 1100, overdueDays: 47, dueToday: 160, scheduled: 1340, learned: 350, subDecks: 12, status: 'overdue', createdAt: '2025-11-02' },
  { id: 'd5', name: 'Korean Basics', contentType: 'deck', sched: 'sm2', gen: 2, locked: true,
    total: 10, new: 0, due: 0, overdue: 0, overdueDays: 0, dueToday: 0, scheduled: 10, learned: 10, subDecks: 2, status: 'notDue', fullyLearned: true, createdAt: '2025-12-01' },
  { id: 'd3', name: 'IT', contentType: 'deck', sched: 'eight_box', gen: 1, locked: false,
    total: 5, new: 5, due: 0, overdue: 0, overdueDays: 0, dueToday: 0, scheduled: 0, learned: 0, subDecks: 1, status: 'notDue', createdAt: '2026-09-15' },
  { id: 'd4', name: 'Thuật ngữ Kinh tế – Tài chính – Ngân hàng cho kỳ thi chứng chỉ quốc tế: kế toán, kiểm toán, thị trường chứng khoán, bảo hiểm và cụm từ thường gặp trong báo cáo thường niên của doanh nghiệp niêm yết',
    contentType: 'deck', sched: 'sm2', gen: 1, locked: false,
    total: 0, new: 0, due: 0, overdue: 0, overdueDays: 0, dueToday: 0, scheduled: 0, learned: 0, subDecks: 0, status: 'notDue', createdAt: '2026-09-01' }
];

const rootTotals = { new: 7717, due: 1358, overdue: 1141, dueToday: 217, scheduled: 2252, overdueDays: 47, status: 'overdue', total: 11327 };

/* ── Inside d1: sub-decks holding cards, holding sub-decks, and one unset ── */
const level2 = [
  { id: 'd11', name: 'Động từ · 동사', contentType: 'card', sched: 'sm2',
    total: 420, new: 100, due: 40, overdue: 20, overdueDays: 3, dueToday: 20, scheduled: 280, learned: 80, subDecks: 0, status: 'overdue' },
  { id: 'd12', name: 'Danh từ · 명사', contentType: 'deck', sched: 'sm2',
    total: 800, new: 200, due: 46, overdue: 21, overdueDays: 2, dueToday: 25, scheduled: 554, learned: 124, subDecks: 4, status: 'overdue' },
  { id: 'd13', name: 'Tính từ · 형용사', contentType: 'unset', sched: 'sm2',
    total: 0, new: 0, due: 0, overdue: 0, overdueDays: 0, dueToday: 0, scheduled: 0, learned: 0, subDecks: 0, status: 'notDue' },
  { id: 'd14', name: 'Ngữ pháp sơ cấp', contentType: 'card', sched: 'sm2',
    total: 28, new: 12, due: 0, overdue: 0, overdueDays: 0, dueToday: 0, scheduled: 16, learned: 4, subDecks: 0, status: 'notDue' }
];
const level2Totals = { new: 312, due: 86, overdue: 41, dueToday: 45, scheduled: 850, overdueDays: 3, status: 'overdue', total: 1248 };
const level2Ancestors = [{ id: 'd1', name: '한국어 TOPIK I · Từ vựng' }];

/* ── Level 10, the deepest allowed ── */
const level10Ancestors = [
  { id: 'dp1', name: 'Deep' }, { id: 'dp2', name: 'L2' }, { id: 'dp3', name: 'L3' }, { id: 'dp4', name: 'L4' },
  { id: 'dp5', name: 'L5' }, { id: 'dp6', name: 'L6' }, { id: 'dp7', name: 'L7' }, { id: 'dp8', name: 'L8' },
  { id: 'dp9', name: 'Level 9 · 아홉' }
];
const level10 = [
  { id: 'dp10', name: 'Level 10 · 열 (deepest)', contentType: 'card', sched: 'eight_box',
    total: 12, new: 4, due: 3, overdue: 0, overdueDays: 0, dueToday: 3, scheduled: 5, learned: 2, subDecks: 0, status: 'dueToday' }
];

/* ── A15 · Study home (WatchStudyHome) ── */
const studyHome = [
  { id: 'd6', name: 'IELTS Academic Word List', overdue: 1100, dueToday: 160, new: 7400, total: 10000, sched: 'eight_box' },
  { id: 'd1', name: '한국어 TOPIK I · Từ vựng', overdue: 41, dueToday: 45, new: 312, total: 1248, sched: 'sm2' },
  { id: 'd2', name: 'Tiếng Anh giao tiếp hằng ngày', overdue: 0, dueToday: 12, new: 0, total: 64, sched: 'eight_box' },
  { id: 'd3', name: 'IT', overdue: 0, dueToday: 0, new: 5, total: 5, sched: 'eight_box' },
  { id: 'd5', name: 'Korean Basics', overdue: 0, dueToday: 0, new: 0, total: 10, sched: 'sm2' },
  { id: 'd4', name: 'Thuật ngữ Kinh tế – Tài chính – Ngân hàng cho kỳ thi chứng chỉ quốc tế: kế toán, kiểm toán, thị trường chứng khoán, bảo hiểm và cụm từ thường gặp trong báo cáo thường niên của doanh nghiệp niêm yết', overdue: 0, dueToday: 0, new: 0, total: 0, sched: 'sm2' }
];
const resume = { deckId: 'd1', deckName: '한국어 TOPIK I · Từ vựng', kind: 'reviewing', mode: 'self_assess', remaining: 18, of: 30 };

/* ── A16 · Study entry ── */
const entrySm2 = { deckId: 'd1', deckName: '한국어 TOPIK I · Từ vựng', sched: 'sm2', new: 312, due: 86, overdue: 41, dueToday: 45, limit: 20, order: 'created', isOverride: true };
const entryEightBox = { deckId: 'd2', deckName: 'Tiếng Anh giao tiếp hằng ngày', sched: 'eight_box', new: 0, due: 12, overdue: 0, dueToday: 12, limit: 20, order: 'created', isOverride: false };
/* GetReviewOptions — eight_box: guess unavailable (4 distinct meanings), fill limited to 3 */
const reviewModes = [
  { mode: 'match', capacity: 12 },
  { mode: 'guess', capacity: 0, reason: 'needsFiveMeanings' },
  { mode: 'recall', capacity: 12 },
  { mode: 'fill', capacity: 3 }
];

/* ── A8 · Cards of a deck (WatchCardListItems) ── */
const cards = [
  { id: 'c1', front: '기억하다', back: 'ghi nhớ, nhớ được', state: 'new', flagged: false, tags: ['동사', 'TOPIK I'], due: null },
  { id: 'c2', front: '공부', back: 'việc học · studying', state: 'beginning', flagged: false, tags: ['명사'], due: 'today',
    example: '매일 한국어 공부를 합니다.' },
  { id: 'c3', front: '눈치', back: 'sự nhạy cảm trong giao tiếp — khả năng đọc không khí và cảm xúc của người khác mà không cần ai nói ra',
    state: 'reviewing', flagged: true, tags: ['명사', 'nâng cao', 'TOPIK II'], due: 'in 6 days',
    example: '그는 눈치가 빠르다.', hint: 'đọc không khí', pron: '[nun.tɕʰi]' },
  { id: 'c4', front: '사회적 거리 두기 · giãn cách xã hội · social distancing 방침', back: 'chính sách giữ khoảng cách vật lý giữa người với người nhằm làm chậm sự lây lan của dịch bệnh; thường đi kèm quy định về số người tụ tập tối đa và khoảng cách tối thiểu',
    state: 'reviewing', flagged: false, due: '30 days overdue', overdue: true,
    tags: ['명사', 'thời sự', 'COVID', 'TOPIK II', 'nâng cao', 'y tế', '사회', 'collocation', 'ghi chú dài', 'ôn tập'] },
  { id: 'c5', front: '물', back: 'nước', state: 'new', flagged: true, tags: [], due: null },
  { id: 'c6', front: '선택하다', back: 'lựa chọn', state: 'mastered', flagged: false, tags: ['동사'], due: 'in 128 days' }
];
const cardCounts = { all: 420, due: 40, new: 100, flagged: 12 };
const cardDistribution = { total: 420, isNew: 100, beginning: 90, reviewing: 150, mastered: 80 };
const deckContext = { deckId: 'd11', name: 'Động từ · 동사', path: ['한국어 TOPIK I · Từ vựng', 'Động từ · 동사'], sched: 'sm2' };

/* ── A10 · Card detail + history ── */
const cardDetail = {
  id: 'c3', front: '눈치', back: 'sự nhạy cảm trong giao tiếp — khả năng đọc không khí và cảm xúc của người khác mà không cần ai nói ra',
  example: '그는 눈치가 빠르다. — Anh ấy rất nhanh nhạy.', hint: 'đọc không khí', pron: '[nun.tɕʰi]',
  flagged: true, tags: ['명사', 'nâng cao', 'TOPIK II'],
  state: 'beginning', sched: 'eight_box', gen: 2, box: 2,
  dueAt: '2026-09-18 00:00', learnedAt: '2026-09-14 20:12', lastAnsweredAt: '2026-09-16 09:12', answers: 14, lapses: 3
};
const history = [
  { id: 'h1', at: '2026-09-16 09:12', gen: 2, sched: 'eight_box', mode: 'recall', kind: 'scheduled', action: 'remembered', before: { box: 1 }, after: { box: 2 }, nextDue: '2026-09-18 00:00' },
  { id: 'h2', at: '2026-09-16 09:10', gen: 2, sched: 'eight_box', mode: 'fill', kind: 'relearning', action: 'forgotten', hintUsed: true, before: { box: 1 }, after: { box: 1 }, nextDue: '2026-09-17 00:00' },
  { id: 'h3', at: '2026-09-14 20:12', gen: 2, sched: 'eight_box', mode: 'recall', kind: 'learning', action: 'forgotten', timeout: true, before: null, after: { box: 1 }, nextDue: '2026-09-15 00:00' },
  { id: 'h4', at: '2026-09-14 20:10', gen: 2, sched: 'eight_box', mode: 'match', kind: 'learning', action: 'remembered', before: null, after: null, nextDue: null },
  { id: 'h5', at: '2026-02-02 14:40', gen: 1, sched: 'sm2', mode: 'self_assess', kind: 'scheduled', action: 'good', before: { ease: 2.5, interval: 6, reps: 2 }, after: { ease: 2.5, interval: 15, reps: 3 }, nextDue: '2026-02-17 00:00' },
  { id: 'h6', at: '2026-01-27 13:05', gen: 1, sched: 'sm2', mode: 'self_assess', kind: 'scheduled', action: 'again', before: { ease: 2.6, interval: 10, reps: 3 }, after: { ease: 2.5, interval: 1, reps: 0 }, nextDue: '2026-01-28 00:00' }
];

/* ── A13 · Tags ── */
const tags = [
  { name: '동사', cards: 186 }, { name: 'collocation', cards: 42 }, { name: 'Ghi chú dài để kiểm tra giới hạn năm mươi ký tự nhé', cards: 3 },
  { name: 'nâng cao', cards: 57 }, { name: '명사', cards: 240 }, { name: 'TOPIK I', cards: 128 },
  { name: 'TOPIK II', cards: 96 }, { name: 'thời sự', cards: 0 }, { name: 'y tế', cards: 1 }
];

/* ── A14 · Trash ── */
const trash = [
  { id: 'b1', type: 'card', name: '반짝반짝', deletedAt: '12 minutes ago', daysLeft: 30, from: 'Động từ · 동사', decks: 0, cards: 1 },
  { id: 'b2', type: 'deck', name: 'Mandarin HSK 1–3', deletedAt: '3 days ago', daysLeft: 27, from: 'Top level', decks: 4, cards: 180, isRoot: true },
  { id: 'b3', type: 'deck', name: 'Danh từ · 명사 / Gia đình', deletedAt: '28 days ago', daysLeft: 2, from: 'Danh từ · 명사', decks: 1, cards: 64 },
  { id: 'b4', type: 'card', name: '물', deletedAt: '29 days ago', daysLeft: 0, hoursLeft: 1, from: 'Động từ · 동사', decks: 0, cards: 1 }
];

/* ── A20 · Progress overview ── */
const progress = {
  streak: 5, heldFromYesterday: false, today: { total: 47, learning: 12, reviewing: 35 },
  week: [
    { day: 'Wed', vi: 'T4', total: 32, learning: 8, reviewing: 24 },
    { day: 'Thu', vi: 'T5', total: 0, learning: 0, reviewing: 0 },
    { day: 'Fri', vi: 'T6', total: 58, learning: 20, reviewing: 38 },
    { day: 'Sat', vi: 'T7', total: 41, learning: 0, reviewing: 41 },
    { day: 'Sun', vi: 'CN', total: 26, learning: 6, reviewing: 20 },
    { day: 'Mon', vi: 'T2', total: 63, learning: 18, reviewing: 45 },
    { day: 'Tue', vi: 'T3', total: 47, learning: 12, reviewing: 35 }
  ]
};
/* ── A21 · Progress by deck ── */
const deckActivity = {
  scope7: { activeCards: 214, activeDays: 6, learning: 58, reviewing: 243 },
  scope30: { activeCards: 892, activeDays: 24, learning: 260, reviewing: 1180 },
  children7: [
    { name: 'IELTS Academic Word List', activeCards: 120, activeDays: 6, learning: 30, reviewing: 140 },
    { name: '한국어 TOPIK I · Từ vựng', activeCards: 82, activeDays: 5, learning: 24, reviewing: 88 },
    { name: 'Tiếng Anh giao tiếp hằng ngày', activeCards: 12, activeDays: 2, learning: 4, reviewing: 15 },
    { name: 'IT', activeCards: 0, activeDays: 0, learning: 0, reviewing: 0 },
    { name: 'Korean Basics', activeCards: 0, activeDays: 0, learning: 0, reviewing: 0 }
  ]
};

/* ── A6 · Starter templates (development fixtures) ── */
const templates = [
  { id: 't1', title: 'Everyday English → Tiếng Việt', lang: 'English → Vietnamese', cards: 40, source: 'Development fixture', suggested: 'eight_box', installed: true },
  { id: 't2', title: '한글 기초 · Hangul basics', lang: 'Korean → romanisation', cards: 24, source: 'Development fixture', suggested: 'sm2', installed: false }
];

/* ── A22/A23 · Settings ── */
const settings = { theme: 'system', language: 'system', limit: 20, order: 'created' };
const reminder = { capability: 'available', on: false, minuteOfDay: 1200, permission: 'notRequested' };

Object.assign(window, { MemoXData: {
  rootDecks, rootTotals, level2, level2Totals, level2Ancestors, level10, level10Ancestors,
  studyHome, resume, entrySm2, entryEightBox, reviewModes,
  cards, cardCounts, cardDistribution, deckContext, cardDetail, history,
  tags, trash, progress, deckActivity, templates, settings, reminder
} });
})();
