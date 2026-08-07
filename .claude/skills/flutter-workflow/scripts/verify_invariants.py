"""Verify the data invariants specified in docs/data-model.md.

The queries are extracted from the frozen document itself, not copied here, so
this tests the specification rather than a duplicate of it. If someone edits an
invariant query in the doc and breaks it, this fails.

Two things are checked for every query:
  1. it parses, and returns nothing against a valid 3-level fixture tree;
  2. it actually fires when its own violation is introduced.

Check 2 is the one that matters. A query that never returns rows passes check 1
perfectly while enforcing nothing — that is the failure mode of most hand-written
data checks.

Run:  python3 .claude/skills/flutter-workflow/scripts/verify_invariants.py
Exit: 0 all good, 1 otherwise.
"""
import sqlite3, re, sys, pathlib, argparse

SCHEMA = """
CREATE TABLE decks (id TEXT PRIMARY KEY, name TEXT NOT NULL,
 parent_deck_id TEXT NULL REFERENCES decks(id) ON DELETE CASCADE,
 root_deck_id TEXT NOT NULL, content_type TEXT NOT NULL, owner_id TEXT NULL,
 scheduler_type TEXT NULL, scheduler_version INTEGER NULL, scheduler_config TEXT NULL,
 scheduler_generation INTEGER NULL, first_answered_at TEXT NULL,
 source_template_id TEXT NULL, source_template_version INTEGER NULL,
 created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
CREATE TABLE cards (id TEXT PRIMARY KEY, deck_id TEXT NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
 front TEXT NOT NULL, back TEXT NOT NULL, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
CREATE TABLE card_study_states (card_id TEXT PRIMARY KEY REFERENCES cards(id) ON DELETE CASCADE,
 scheduler_type TEXT NOT NULL, scheduler_version INTEGER NOT NULL, scheduler_generation INTEGER NOT NULL,
 due_at TEXT NULL, last_answered_at TEXT NULL, answer_count INTEGER NOT NULL DEFAULT 0,
 lapse_count INTEGER NOT NULL DEFAULT 0, current_box INTEGER NULL, ease_factor REAL NULL,
 interval_days INTEGER NULL, repetitions INTEGER NULL);
CREATE TABLE study_sessions (id TEXT PRIMARY KEY, deck_id TEXT NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
 root_deck_id TEXT NOT NULL, scheduler_generation INTEGER NOT NULL, status TEXT NOT NULL,
 end_reason TEXT NULL, started_at TEXT NOT NULL, ended_at TEXT NULL);
CREATE TABLE study_answers (id TEXT PRIMARY KEY, card_id TEXT NOT NULL REFERENCES cards(id) ON DELETE CASCADE,
 session_id TEXT NOT NULL REFERENCES study_sessions(id), scheduler_type TEXT NOT NULL,
 scheduler_generation INTEGER NOT NULL, kind TEXT NOT NULL, action TEXT NOT NULL,
 answered_at TEXT NOT NULL, next_due_at TEXT NULL, previous_box INTEGER NULL, next_box INTEGER NULL,
 previous_ease_factor REAL NULL, next_ease_factor REAL NULL,
 previous_interval_days INTEGER NULL, next_interval_days INTEGER NULL);
"""

# Extract the invariant queries straight out of the frozen doc, so this test
# verifies the DOCUMENT, not a copy of it.
doc = pathlib.Path("docs/data-model.md").read_text()
blocks = re.findall(r"```sql\n(.*?)```", doc, re.S)
inv_sql = "\n".join(b for b in blocks if re.search(r"^--\s*\d+\.", b, re.M))
queries = {}
for chunk in re.split(r"\n(?=--\s*\d+\.)", inv_sql):
    m = re.match(r"--\s*(\d+)\.\s*(.+)", chunk)
    if not m: continue
    body = "\n".join(l for l in chunk.splitlines() if not l.strip().startswith("--")).strip()
    if body: queries[int(m.group(1))] = (m.group(2).strip(), body)

print(f"Trích được {len(queries)} câu invariant từ docs/data-model.md\n")

def fresh():
    c = sqlite3.connect(":memory:"); c.executescript(SCHEMA); return c

def good(c):
    c.executescript("""
    INSERT INTO decks VALUES('r','Root',NULL,'r','deck',NULL,'eight_box',1,NULL,1,NULL,NULL,NULL,'t','t');
    INSERT INTO decks VALUES('a','A','r','r','deck',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'t','t');
    INSERT INTO decks VALUES('b','B','a','r','card',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'t','t');
    INSERT INTO cards VALUES('c1','b','f','k','t','t');
    INSERT INTO card_study_states VALUES('c1','eight_box',1,1,NULL,NULL,0,0,1,NULL,NULL,NULL);
    INSERT INTO study_sessions VALUES('s1','r','r',1,'completed',NULL,'t','t');
    INSERT INTO study_answers VALUES('h1','c1','s1','eight_box',1,'relearning','forgotten','t',NULL,1,1,NULL,NULL,NULL,NULL);
    """)

# each: query-number -> SQL that introduces exactly that violation
BAD = {
 1: "INSERT INTO cards VALUES('cx','r','f','k','t','t');",
 2: "INSERT INTO decks VALUES('u','U','a','r','unset',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'t','t');"
    "INSERT INTO cards VALUES('cu','u','f','k','t','t');",
 3: "INSERT INTO decks VALUES('z','Z','b','r','deck',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'t','t');",
 4: "INSERT INTO cards VALUES('ca','a','f','k','t','t');",
 5: "UPDATE decks SET content_type='card' WHERE id='r';",
 6: "UPDATE decks SET root_deck_id='wrong' WHERE id='b';",
 7: "UPDATE decks SET root_deck_id='nope' WHERE id='r';",
 8: "UPDATE decks SET parent_deck_id='b' WHERE id='a';",
 9: "UPDATE card_study_states SET scheduler_generation=99 WHERE card_id='c1';",
 10:"UPDATE decks SET scheduler_type='sm2' WHERE id='a';",
 11:"UPDATE decks SET scheduler_type=NULL WHERE id='r';",
 12:"INSERT INTO study_sessions VALUES('s2','r','r',1,'completed','user_exit','t','t');",
 13:"INSERT INTO study_sessions VALUES('s3','r','r',1,'abandoned','user_exit','t',NULL);",
 14:"INSERT INTO study_answers VALUES('h2','c1','s1','eight_box',1,'relearning','forgotten','t',NULL,1,5,NULL,NULL,NULL,NULL);",
 # A chain from the valid tree's 'a' (level 2) down to level 11 (BR-55).
 15:"".join(
    "INSERT INTO decks VALUES('x%d','X','%s','r','deck',NULL,NULL,NULL,NULL,"
    "NULL,NULL,NULL,NULL,'t','t');" % (n, 'a' if n == 3 else 'x%d' % (n - 1))
    for n in range(3, 12)
 ),
}

ap = argparse.ArgumentParser(add_help=True)
ap.add_argument("--db", metavar="PATH",
                help="run the invariants against a real database file instead "
                     "of the built-in fixture")
args = ap.parse_args()

if args.db:
    # Same queries, same source. Every invariant is read out of the frozen
    # document rather than copied into the caller — four used to be missing
    # from check_docs.sh precisely BECAUSE they had been hand-copied, and ten
    # of the then-fourteen running still reported success.
    db_path = pathlib.Path(args.db)
    if not db_path.exists():
        print(f"✗ không tìm thấy database: {db_path}")
        sys.exit(1)

    con = sqlite3.connect(str(db_path))
    violated = 0
    for n, (label, sql) in sorted(queries.items()):
        try:
            rows = con.execute(sql).fetchall()
        except sqlite3.Error as e:
            print(f"  ✗ Q{n:<2} SQL LỖI: {e}   [{label[:48]}]")
            violated += 1
            continue
        if rows:
            # Ids only. Never a row's content: card text, notes and learning
            # history are private (AD-08), and a checker's output ends up in
            # logs and CI transcripts.
            ids = ", ".join(str(r[0]) for r in rows[:5])
            print(f"  ✗ Q{n:<2} {label[:56]}  → {len(rows)} dòng: {ids}")
            violated += 1
        else:
            print(f"  ✓ Q{n:<2} {label[:60]}")

    verdict = "SẠCH" if violated == 0 else str(violated) + " VI PHẠM"
    print("")
    print(str(len(queries)) + " invariant chạy trên " + str(db_path) + ": " + verdict)
    sys.exit(1 if violated else 0)

fails = 0
# 1) all queries must parse and return nothing on valid data
c = fresh(); good(c)
for n,(label,sql) in sorted(queries.items()):
    try:
        rows = c.execute(sql).fetchall()
    except sqlite3.Error as e:
        print(f"  ✗ Q{n:<2} SQL LỖI: {e}   [{label[:48]}]"); fails += 1; continue
    if rows:
        print(f"  ✗ Q{n:<2} false positive trên dữ liệu hợp lệ: {rows}   [{label[:48]}]"); fails += 1
print(f"[1] Dữ liệu hợp lệ → {len(queries)-fails} / {len(queries)} câu trả về 0 dòng")

# 2) each query must fire on its own violation
print("\n[2] Mỗi câu phải bắt được vi phạm tương ứng:")
for n,(label,sql) in sorted(queries.items()):
    if n not in BAD:
        print(f"  ? Q{n:<2} chưa có case vi phạm"); continue
    c = fresh(); good(c); c.executescript(BAD[n])
    rows = c.execute(sql).fetchall()
    mark = "✓" if rows else "✗ KHÔNG BẮT ĐƯỢC"
    if not rows: fails += 1
    print(f"  {mark} Q{n:<2} {label[:60]}")

print(f"\n{'TẤT CẢ ĐẠT' if fails==0 else str(fails)+' LỖI'}")
sys.exit(1 if fails else 0)
