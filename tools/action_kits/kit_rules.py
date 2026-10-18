"""Explicit rhythm mapping for every HipLab action kit (action-kit v1).

Most numbers are *measured* from the Pose-Hub spec timeline by
build_action_kits.py (rise start / top / fall start / bottom of the main
track, 10 % / 90 % thresholds). This table only says what the spec cannot:
which kind of training the action is, which spoken words go on which phase,
the default dose, and – where the main track does not describe one rep – an
explicit phase list taken from the spec's own header comment.

Every entry lists `why` so a reviewer can see where a number came from.
Phase ids: go (move into the position), hold (stay), back (return),
rest (pause before the next rep). A phase `cue` is a word key (w.*) or a
list of keys that rotate with the count (alternating sides / directions).
"""

# ── shared spoken words (key → (zh, en)) ─────────────────────────────────
# Short on purpose: each must fit inside the phase it announces (checked by
# build_action_kits.py --check and test/hip/action_kit_test.dart).
WORDS = {
    'w.up': ('起', 'Up'),
    'w.down': ('落', 'Down'),
    'w.lift': ('抬起', 'Lift'),
    'w.lower': ('放下', 'Lower'),
    'w.open': ('打开', 'Open'),
    'w.close': ('合拢', 'Close'),
    'w.hold': ('停住', 'Hold'),
    'w.hips_up': ('臀部抬起', 'Hips up'),
    'w.squat_down': ('蹲下', 'Squat down'),
    'w.stand_up': ('站起', 'Stand up'),
    'w.sit_back': ('往后坐', 'Sit back'),
    'w.come_forward': ('回来', 'Come forward'),
    'w.slide_out': ('滑出去', 'Slide out'),
    'w.pull_in': ('收回来', 'Pull it in'),
    'w.center': ('回正', 'Back to center'),
    'w.right_knee_in': ('右膝向内', 'Right knee in'),
    'w.left_knee_in': ('左膝向内', 'Left knee in'),
    'w.knees_right': ('倒向右边', 'Knees right'),
    'w.knees_left': ('倒向左边', 'Knees left'),
    'w.shift_left': ('移到左边', 'Shift left'),
    'w.shift_right': ('移到右边', 'Shift right'),
    'w.gate_open': ('开门', 'Open the gate'),
    'w.gate_close': ('关门', 'Close the gate'),
    'w.circle_fwd': ('向前画圈', 'Circle forward'),
    'w.circle_rev': ('反着画回来', 'Now reverse'),
    'w.pelvis_one_way': ('顺着画一圈', 'Circle one way'),
    'w.pelvis_other_way': ('反着画一圈', 'Now the other way'),
    'w.two_circles': ('画两圈', 'Two circles'),
    'w.cross_over': ('跨过去', 'Cross over'),
    'w.come_back': ('回来', 'Come back'),
    'w.exhale_hug': ('呼气，抱紧', 'Breathe out, hug in'),
    'w.inhale_release': ('吸气，放松', 'Breathe in, let go'),
    'w.turn_out': ('转出去', 'Turn out'),
    'w.squeeze': ('夹紧', 'Squeeze'),
    'w.relax': ('放松', 'Relax'),
}

# Session-level phrases the rhythm model adds (kept with the other fixed
# phrases in tools/voice/voice_lines.py; listed here for the spec doc).
SESSION_WORDS = ['p.last_rep', 'p.release', 'p.again', 'p.right_first']

# ── kinds ────────────────────────────────────────────────────────────────
# rep_updown    计数-双相起落: count + "go" word, "back" word at the return.
# rep_cycle     计数-循环：one count = one full loop with two directions
#               (forward circle then reverse) – a word on each half.
# rep_alternate 计数-左右交替：each count is one side / direction; the go
#               word rotates (右/左, 开门/关门), "回正" on the return.
# rep_hold      计数-停留：a rep with a timed hold at the top (dose says
#               "停 N 秒"); hold word, a 3-2-1 inside long holds.
# rep_breath    呼吸配合：the phases are an exhale and an inhale.
# hold          保持计时：static hold; start, halfway, last 10 s, 5-4-3-2-1,
#               then "慢慢还原". Sided holds get the side switch.

R = 'right'
L = 'left'

RULES = {
    # ── counted, two-phase ──
    'glute-max-A': dict(kind='rep_updown', sided=True, go='w.hips_up', back='w.lower',
                        reps=6, why='spec: 2 reps / 8 s with a 1.6 s squeeze at the top'),
    'w-feet-on-chair-bridge': dict(kind='rep_updown', sided=False, go='w.hips_up', back='w.lower',
                                   reps=8, why='spec: 2 reps / 8 s'),
    'h-squat': dict(kind='rep_updown', sided=False, go='w.squat_down', back='w.stand_up', reps=8,
                    why='spec: 2 reps / 8 s, 1 s hold at the bottom'),
    'h-reverse-clam': dict(kind='rep_updown', sided=True, go='w.lift', back='w.lower', reps=8,
                           why='spec: 2 reps / 8 s, top foot lifts, hold, lower'),
    'w-clamshell': dict(kind='rep_updown', sided=True, go='w.open', back='w.close', reps=10,
                        why='spec: 2 reps / 8 s'),
    'h-9090-liftoff': dict(kind='rep_updown', sided=True, go='w.lift', back='w.lower', reps=6,
                           why='spec: 2 reps / 8 s, lift, hold a beat, lower slowly'),
    'hip-flexors-A': dict(kind='rep_updown', sided=False, go='w.lift', back='w.lower', reps=8,
                          why='spec: legs lift, hold, lower; 2 reps / 8 s'),
    'h-adductor-rock': dict(kind='rep_updown', sided=True, go='w.sit_back', back='w.come_forward',
                            reps=5, why='spec: 2 rocks / 8 s: 1.8 s back, 0.8 s hold, 1.4 s forward'),
    'n-slider-lateral': dict(kind='rep_updown', sided=True, go='w.slide_out', back='w.pull_in',
                             reps=6, why='spec: 2 reps / 8 s: 1.5 s out, 0.6 s hold, 1.4 s in'),
    'h-butterfly-active': dict(kind='rep_updown', sided=False, go='w.open', back='w.close', reps=6,
                               why='spec: 2 reps / 8 s: 1.8 s open, 0.6 s hold, 1.2 s close'),
    't-seated-straddle-lift-1leg': dict(
        kind='rep_updown', sided=True, reps=6,
        phases=[('go', .8, 'w.lift'), ('hold', 1.0, None), ('back', .6, 'w.lower'), ('rest', .1, None)],
        why='spec liftL: two quick lifts per side (0–1.3 s, 1.7–3.0 s) then the hands switch sides; '
            'one count = one lift, slowed to 2.5 s so the cue fits',
        flag='voice lift (2.5 s) is slower than the demo lift (≈1.3 s); demo alternates sides every 5 s'),
    'h-band-hip-ir': dict(kind='rep_updown', sided=True, go='w.turn_out', back='w.come_back', reps=8,
                          why='spec: 2 reps / 8 s: 1.2 s out, 0.8 s hold, 1.4 s back'),
    'n-prone-hip-ext': dict(kind='rep_updown', sided=True, go='w.lift', back='w.lower', reps=8,
                            why='spec: 2 reps / 8 s: 1 s up, 2 s hold, 0.8 s down'),
    'n-prone-ir': dict(kind='rep_updown', sided=False, go='w.turn_out', back='w.come_back', reps=8,
                       why='spec: 2 reps / 8 s'),
    'n-seated-squeeze': dict(kind='rep_updown', sided=False, go='w.squeeze', back='w.relax', reps=8,
                             why='spec: 2 squeezes / 8 s'),
    # ── counted, loop with two directions ──
    'h-quad-cars': dict(kind='rep_cycle', sided=True, reps=3,
                        phases=[('go', 3.6, 'w.circle_fwd'), ('rest', .4, None),
                                ('back', 3.6, 'w.circle_rev'), ('rest', .4, None)],
                        why='spec: forward circle 0.5–3.9 s, reverse 4.3–7.7 s; one count = both'),
    'n-pelvis-circle': dict(kind='rep_cycle', sided=False, reps=4,
                            phases=[('go', 3.6, 'w.pelvis_one_way'), ('rest', .4, None),
                                    ('back', 3.6, 'w.pelvis_other_way'), ('rest', .4, None)],
                            why='spec: circle 0.2–3.8 s, other way 4.2–7.8 s; "正反各 N 圈" = N counts'),
    'n-leg-circles': dict(kind='rep_cycle', sided=True, reps=2,
                          phases=[('go', 7.2, 'w.two_circles'), ('hold', 2.4, 'w.cross_over'),
                                  ('back', 2.4, 'w.come_back')],
                          why='spec: one cycle / 12 s: 0–7.2 s two circles, 7.2–12 s cross-over and back',
                          flag='dose 「每侧 正反各 4 圈」 vs animation (2 circles + cross-over per 12 s): '
                               'voice follows the animation, 2 rounds = 4 circles; dose text needs a decision'),
    # ── counted, alternating sides / directions ──
    'n-chair-wiper': dict(kind='rep_alternate', sided=False, go=['w.right_knee_in', 'w.left_knee_in'],
                          back='w.center', reps=6,
                          why='spec: right knee in 0.3–1.7 s, hold to 2.6, back by 3.8; then left'),
    'n-windshield': dict(kind='rep_alternate', sided=False, go=['w.knees_right', 'w.knees_left'],
                         back='w.center', reps=8, why='spec: one cycle (both sides) / 8 s, right first'),
    'n-squat-shift': dict(kind='rep_alternate', sided=False, go=['w.shift_left', 'w.shift_right'],
                          back='w.center', reps=8, why='spec: one cycle (both sides) / 8 s, left first'),
    'h-hip-gate': dict(kind='rep_alternate', sided=True, go=['w.gate_open', 'w.gate_close'],
                       back='w.lower', reps=6,
                       phases=[('go', .5, ['w.gate_open', 'w.gate_close']), ('hold', 1.35, None),
                               ('back', 1.25, 'w.lower'), ('rest', .9, None)],
                       why='spec: 1 open + 1 close / 8 s (knee up 0.4–0.9 s, out to 2.3 s, down by 3.6 s); '
                           '"开 3 + 关 3" = 6 alternating counts'),
    # ── counted with a timed hold ──
    'n-seated-knee-lift': dict(kind='rep_hold', sided=True, go='w.lift', hold_cue='w.hold',
                               back='w.lower', reps=3, hold=5,
                               why='spec: each side 0.8 s up, 1.8 s hover, 0.9 s down, 0.5 s rest; '
                                   'dose holds 5 s'),
    'h-sumo-pry': dict(kind='rep_hold', sided=False, go='w.squat_down', hold_cue='w.hold',
                       back='w.up', reps=3, hold=10,
                       why='spec: 1.6 s down, 1.4 s hold, 1.0 s up; dose holds 10–15 s'),
    # ── breathing ──
    'h-knee-hug': dict(kind='rep_breath', sided=False, go='w.exhale_hug', back='w.inhale_release',
                       reps=6, why='spec r2: 8 s / two breaths – hug on the exhale, release on the inhale'),
    'n-thomas-test': dict(kind='hold', sided=True, seconds=30, why='test pose held'),
    # ── holds ──
    'o-stand-lunge': dict(kind='hold', sided=True, seconds=30, why='static stretch; spec shows one slow entry'),
    'o-seated-fig4': dict(kind='hold', sided=True, seconds=25, why='static stretch'),
    's-figure4': dict(kind='hold', sided=True, seconds=40, why='static stretch'),
    'h-band-leg-out': dict(kind='hold', sided=True, seconds=40,
                           why='dose is a timed hold; spec shows lower-out, 4 s hold, back up'),
    'h-supine-twist': dict(kind='hold', sided=True, seconds=40, why='dose is a timed hold'),
    'h-wall-straddle': dict(kind='hold', sided=False, seconds=60, why='static stretch'),
    's-kneel-hipflex': dict(kind='hold', sided=True, seconds=30, why='static stretch'),
    's-lizard': dict(kind='hold', sided=True, seconds=35, why='static stretch'),
    's-9090': dict(kind='hold', sided=True, seconds=35, why='static stretch'),
    'n-seated-ir-drop': dict(kind='hold', sided=True, seconds=30,
                             why='dose is a timed hold per side (spec alternates sides every 4 s)',
                             flag='animation alternates sides while the dose holds one side'),
    's-pigeon': dict(kind='hold', sided=True, seconds=35, why='static stretch'),
    's-seated-fold': dict(kind='hold', sided=False, seconds=40, why='static stretch'),
    's-frog': dict(kind='hold', sided=False, seconds=60, why='static stretch'),
    'n-straddle-fold': dict(kind='hold', sided=False, seconds=75, why='static stretch'),
    'n-half-split': dict(kind='hold', sided=True, seconds=40, why='static stretch'),
    'o-seated-ham': dict(kind='hold', sided=True, seconds=40, why='static stretch'),
    'h-couch-stretch': dict(kind='hold', sided=True, seconds=40, why='static stretch'),
    'n-wide-fold': dict(kind='hold', sided=False, seconds=40, why='static stretch'),
    'o-stand-crossreach': dict(kind='hold', sided=True, seconds=30, why='static stretch'),
    's-butterfly': dict(kind='hold', sided=False, seconds=40, why='static stretch'),
}

# First side of the demonstration for sided kits (the app plays right first,
# 成套训练 编排规则 2; listed for the record and for future mirroring).
FIRST_SIDE = {}
