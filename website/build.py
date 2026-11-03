"""Build the HipLab website into website/dist (zh at /, English at /en/).

python3 website/build.py            # renders HTML, subsets the CJK font to used glyphs, copies images
Font source: NOTO_TTF env (default /workspace/work/sites/fonts/NotoSansSC.ttf, variable Noto Sans SC).
If the TTF is missing, the committed src/fonts/hl.woff2 is reused as-is.
"""
import os, re, shutil, html, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, 'src'); DIST = os.path.join(HERE, 'dist')
PLAY = 'https://play.google.com/apps/testing/com.ugk.hiplab'
MAIL = 'mhgd3250905@gmail.com'

# Drill posters: real ids, zh names from assets/hip/hip-content.json, en names from assets/coach/catalog.json
WALL = [
 ('s-pigeon', '鸽子式（直立扶砖版）', 'Pigeon Pose', 'stretch', False),
 ('s-lizard', '蜥蜴式低弓步（扶砖）', 'Lizard Lunge', 'stretch', False),
 ('s-frog', '青蛙式', 'Frog Stretch', 'stretch', False),
 ('h-couch-stretch', '沙发拉伸（后脚搭矮凳）', 'Couch Stretch', 'stretch', False),
 ('o-seated-fig4', '坐姿四字前压', 'Seated Figure-4 Stretch', 'stretch', True),
 ('n-half-split', '半跪半劈叉', 'Half-Kneeling Half Split', 'stretch', False),
 ('w-clamshell', '侧卧蚌式开合', 'Side-Lying Clamshell', 'strength', False),
 ('h-9090-liftoff', '90/90 后腿主动抬起', '90/90 Back-Leg Lift-Off', 'mobility', False),
 ('n-windshield', '仰卧雨刷式', 'Supine Windshield Wipers', 'mobility', False),
 ('h-hip-gate', '扶椅站姿开髋门', 'Chair-Supported Hip Gate Opener', 'mobility', True),
 ('n-chair-wiper', '坐椅雨刷（膝内倒）', 'Seated Knee Drop-In', 'mobility', True),
 ('glute-max-a', '单腿臀桥', 'Single-Leg Glute Bridge', 'strength', False),
 ('s-butterfly', '蝴蝶式', 'Seated Butterfly Stretch', 'stretch', False),
 ('s-9090', '90/90 坐姿换髋', '90/90 Hip Stretch', 'mobility', False),
 ('s-seated-fold', '坐姿体前屈', 'Seated Forward Fold', 'stretch', False),
]
CAT = {'stretch': ('拉伸', 'Stretch'), 'mobility': ('灵活性', 'Mobility'), 'strength': ('力量', 'Strength')}
# The 6 check-up moves (assets/hip/hip-content.json assessment.items)
TESTS = [('s-butterfly', '蝴蝶式', 'Butterfly', 12, False), ('s-9090', '90/90', '90/90 sit', 15, True),
         ('n-thomas-test', '屈髋肌测试', 'Hip flexor test', 15, True), ('supine-cross', '仰卧横跨', 'Supine cross-over', 15, True),
         ('s-seated-fold', '坐姿体前屈', 'Seated forward fold', 12, False), ('h-squat', '深蹲到底', 'Deep squat', 12, False)]

ZH = dict(
 lang='zh-CN', root='', other='en/', other_label='EN', here_label='中文',
 title='HipLab 开胯训练助手 · 给久坐人群的髋部灵活性训练 App',
 desc='HipLab 开胯训练助手：3 分半髋部自测、六方向灵活度雷达图、按结果推荐训练，210 个动作都有 3D 示范。Android 内测中，免费。',
 nav=['功能', '动作库', '内测', '常见问题'], cta_sm='加入内测',
 sub='开胯训练助手', what='给久坐人群的髋部灵活性训练 App',
 lead='用 3 分半做一次髋部自测，App 找出你最紧的方向，再按结果排好训练。210 个动作都有 3D 人体示范，跟着做就行。',
 cta='加入 Android 内测', mail_q='没收到测试邀请？', mail_a='发邮件报名', ios='iOS 版准备中',
 badge='Android 内测中 · 免费',
 stats=[('210', '个 3D 示范动作'), ('6', '个自测动作'), ('6', '个方向的灵活度雷达图'), ('0', '网络也能练，数据存在手机上')],
 f1h='3 分半髋部自测',
 f1p='跟着 App 做 6 个动作，每个 12–15 秒，单侧动作左右各做一次。每一步都有示意图，选出最接近你的姿势就行，不用量角度。',
 sec='秒', sided='左右各一次',
 f2h='六方向灵活度雷达图',
 f2p='自测结果画成屈、伸、外展、内收、内旋、外旋六个方向的雷达图，最弱的方向会单独标出。总分 12 分，对应三个等级：',
 levels=[('入门', '0–5 分'), ('基础', '6–9 分'), ('进阶', '10–12 分')],
 f2n='App 保留上次的结果和日期，隔几周重测一次，就能看到哪个方向松开了。',
 radar=['屈', '外展', '外旋', '伸 · 最弱', '内旋', '内收'], radar_score='本次结果', radar_lv='基础 · 7/12',
 f3h='按自测结果推荐训练',
 f3p='自测完，App 按最紧的方向推荐训练套路：髋前侧紧，推荐久坐解压；内旋差，推荐内旋补强。每个套路都写清楚每一步做多久、做几次。',
 f3l='内置套路', routines=['办公室（椅子可做）', '睡前放松', '晨起唤醒', '久坐解压', '训练前激活', 'Breaking 开胯', '久坐提醒 · 椅边 2 分钟'],
 f4h='210 个 3D 示范动作',
 f4p='每个动作都有 3D 人体示范动画和动作要点。可以按部位和器械筛选，中英文都能搜；在椅子上就能做的动作单独标出来。',
 filters=['全部', '臀部', '大腿后侧', '髋前侧', '内收肌', '椅子可做'], chair='椅子可做',
 f4m='动作库共 210 个动作，以上是其中一部分。',
 f5h='自建训练组',
 f5p='从动作库里挑动作，组成自己的训练组，最多 20 个动作。按住拖动调整顺序，动作之间的休息可选 10、15、20 或 30 秒，App 自动算出总时长。推荐套路也能一键复制成自己的训练组再改。',
 f6h='训练记录与连续打卡',
 f6p='每次练完自动记一笔：连续天数，累计天数、次数和时长，本周打卡，近 16 周训练日历，以及 3、7、14、30、60、100 天里程碑。',
 extras_h='另外还有', extras=[('久坐提醒', '每 45 或 60 分钟提醒一次，点开就是 2 分钟椅边放松。'), ('语音口令', '动作预告、倒数、换边都有人声提示，中文和英文可选。'), ('浅色 / 深色', '外观可跟随系统，也可以手动切换。')],
 how_h='使用流程', how=[('安装', '加入 Google Play 内测，安装 HipLab。'), ('自测', '花 3 分半做 6 个动作，得到六方向雷达图。'), ('跟练', '打开推荐套路，跟着 3D 示范和语音练。'), ('记录', '练完自动记录，连续打卡，隔几周重测。')],
 beta_h='加入 Android 内测',
 beta_p='HipLab 正在 Google Play 做封闭测试。按 Google Play 的要求，正式上架前需要至少 12 位测试者连续 14 天保持参与。想帮忙的话：点下面的按钮加入测试并安装 App，14 天内别卸载，有空练几分钟；遇到问题或有建议，发邮件告诉我们。',
 facts=[('平台', 'Android · Google Play'), ('需要', '一个 Google 账号'), ('时长', '连续 14 天'), ('费用', '免费')],
 beta_mail='如果页面提示无法加入，把你的 Google 账号邮箱发到 ' + MAIL + '，我们把你加进测试名单。',
 faq_h='常见问题', faq=[
  ('HipLab 免费吗？', '内测版免费使用，所有功能都可以用。'),
  ('需要联网吗？', '不需要。自测、动作示范、训练和记录都在手机本地运行，动作视频随 App 内置，训练数据保存在你的设备上。'),
  ('适合谁？', '久坐的上班族和学生，觉得髋紧、盘腿或深蹲困难的人，跑步或健身前想做激活的人，以及练 Breaking 等需要开胯的舞者。'),
  ('能代替医生或康复治疗吗？', '不能。HipLab 是运动练习工具，不做诊断或治疗。如果你有髋、膝、腰部伤病，刚做过手术或正在怀孕，请先咨询医生；练习中出现疼痛请立即停止。'),
  ('有 iPhone 版吗？', 'iOS 版正在准备中，目前只有 Android 内测。'),
  ('怎么反馈问题？', '发邮件到 ' + MAIL + '，写上手机型号和遇到的问题，有截图更好。')],
 foot_disc='HipLab 是运动练习工具，不提供医疗诊断或治疗建议。如有伤病或不适，请先咨询医生。',
 foot_contact='联系', mail_subject='HipLab 内测报名',
 alt_check='HipLab 髋部自测页面', alt_routine='推荐套路页面', alt_lib='动作库页面', alt_groups='我的训练组', alt_editor='编辑训练组', alt_records='训练记录页面',
)

EN = dict(
 lang='en', root='../', other='../', other_label='中文', here_label='EN',
 title='HipLab · Hip mobility training app for people who sit all day',
 desc='HipLab: a 3½-minute hip check-up, a six-direction mobility radar, workouts matched to your results, and 210 moves with 3D demos. Free Android beta.',
 nav=['Features', 'Moves', 'Beta', 'FAQ'], cta_sm='Join the beta',
 sub='Hip mobility trainer', what='A hip mobility training app for people who sit all day',
 lead='Take a 3½-minute hip check-up, see which direction is tightest, and get workouts picked for your results. All 210 moves come with a 3D demo you can follow.',
 cta='Join the Android beta', mail_q='No invite yet?', mail_a='Sign up by email', ios='iOS coming later',
 badge='Android beta · Free',
 stats=[('210', 'moves with 3D demos'), ('6', 'check-up moves'), ('6', 'directions on your mobility radar'), ('0', 'internet needed — data stays on your phone')],
 f1h='3½-minute hip check-up',
 f1p='Do six moves with the app, 12–15 seconds each, both sides for one-sided moves. Every step shows reference pictures — just pick the one that looks most like you. No angles to measure.',
 sec='s', sided='each side',
 f2h='Six-direction mobility radar',
 f2p='Your results are drawn as a radar across flexion, extension, abduction, adduction, internal and external rotation, with the weakest direction highlighted. The total score is out of 12:',
 levels=[('Starter', '0–5'), ('Basic', '6–9'), ('Advanced', '10–12')],
 f2n='The app keeps your last result and its date, so a retest a few weeks later shows what has opened up.',
 radar=['Flex', 'Abd', 'ER', 'Ext · weakest', 'IR', 'Add'], radar_score='This check-up', radar_lv='Basic · 7/12',
 f3h='Workouts matched to your check-up',
 f3p='After the check-up, the app recommends routines for your tightest direction — tight hip flexors get the desk-recovery routine, limited internal rotation gets internal-rotation work. Each routine lists how long and how many reps for every step.',
 f3l='Built-in routines', routines=['Office (chair-friendly)', 'Bedtime unwind', 'Morning wake-up', 'After-sitting reset', 'Pre-workout activation', 'Breaking hip opener', 'Sitting break · 2 min at your chair'],
 f4h='210 moves with 3D demos',
 f4p='Every move has a 3D demo animation and form cues. Filter by body area and equipment, and search in English or Chinese. Moves you can do in a chair are marked.',
 filters=['All', 'Glutes', 'Hamstrings', 'Hip flexors', 'Adductors', 'Chair'], chair='Chair',
 f4m='A few of the 210 moves in the library.',
 f5h='Build your own workouts',
 f5p='Pick moves from the library and save them as your own workout, up to 20 moves. Drag to reorder, set rest between moves to 10, 15, 20 or 30 seconds, and the app adds up the total time. You can also copy any built-in routine and edit it.',
 f6h='Training log and streaks',
 f6p='Every finished session is logged: your current streak, total days, sessions and minutes, this week\'s check-ins, a 16-week calendar, and milestones at 3, 7, 14, 30, 60 and 100 days.',
 extras_h='Also included', extras=[('Sitting reminders', 'A nudge every 45 or 60 minutes that opens a 2-minute routine at your chair.'), ('Voice cues', 'Spoken previews, countdowns and side switches, in English or Chinese.'), ('Light / dark', 'Follow the system setting or pick one.')],
 how_h='How it works', how=[('Install', 'Join the Google Play beta and install HipLab.'), ('Check', 'Spend 3½ minutes on six moves and get your radar.'), ('Train', 'Open a recommended routine and follow the 3D demo and voice cues.'), ('Track', 'Sessions log automatically. Keep your streak and retest in a few weeks.')],
 beta_h='Join the Android beta',
 beta_p='HipLab is in closed testing on Google Play. Before it can go public, Google Play requires at least 12 testers to stay opted in for 14 days in a row. If you\'d like to help: tap the button below to join and install the app, keep it installed for 14 days, and train a few minutes when you can. If something breaks or feels off, email us.',
 facts=[('Platform', 'Android · Google Play'), ('You need', 'A Google account'), ('Duration', '14 days in a row'), ('Price', 'Free')],
 beta_mail='If the page says you can\'t join, email your Google account address to ' + MAIL + ' and we\'ll add you to the tester list.',
 faq_h='FAQ', faq=[
  ('Is HipLab free?', 'The beta is free, with every feature included.'),
  ('Does it need an internet connection?', 'No. The check-up, demos, workouts and log all run on your phone. Demo videos ship with the app and your training data stays on your device.'),
  ('Who is it for?', 'Office workers and students who sit a lot, anyone whose hips feel tight or who struggles to sit cross-legged or squat deep, people warming up for runs or the gym, and dancers working on hip mobility for Breaking.'),
  ('Does it replace a doctor or physio?', 'No. HipLab is an exercise tool and doesn\'t diagnose or treat anything. If you have a hip, knee or back injury, recent surgery, or are pregnant, check with your doctor first, and stop if anything hurts.'),
  ('Is there an iPhone version?', 'iOS is in the works. For now there is only the Android beta.'),
  ('How do I report a problem?', 'Email ' + MAIL + ' with your phone model and what happened — screenshots help.')],
 foot_disc='HipLab is an exercise tool and does not provide medical diagnosis or treatment. If you have an injury or feel pain, see a doctor first.',
 foot_contact='Contact', mail_subject='HipLab beta sign-up',
 alt_check='HipLab hip check-up screen', alt_routine='Recommended routine screen', alt_lib='Move library screen', alt_groups='My workouts', alt_editor='Editing a workout', alt_records='Training log screen',
)

E = html.escape

def shot(L, name, alt, cls='phone', eager=False):
    r = L['root']
    load = 'eager" fetchpriority="high' if eager else 'lazy'
    return (f'<div class="{cls}"><img src="{r}img/{name}-640.webp" srcset="{r}img/{name}-360.webp 360w, {r}img/{name}-640.webp 640w" '
            f'sizes="(max-width:760px) 230px, 300px" width="640" height="1387" alt="{E(alt)}" loading="{load}" decoding="async"></div>')

def radar(L):
    t = L['radar']
    return f'''<svg viewBox="-170 -160 340 320" role="img" aria-label="{E(L['f2h'])}">
  <g fill="none" stroke="rgba(18,32,25,.10)"><polygon points="0,-120 104,-60 104,60 0,120 -104,60 -104,-60"/><polygon points="0,-80 69,-40 69,40 0,80 -69,40 -69,-40"/><polygon points="0,-40 35,-20 35,20 0,40 -35,20 -35,-20"/><path d="M0,-120V120M104,-60L-104,60M104,60L-104,-60"/></g>
  <polygon class="poly" points="0,-96 83,-48 62,36 0,20 -66,38 -70,-40"/><circle cx="0" cy="20" r="5" fill="#d98a2b"/>
  <text x="0" y="-132" text-anchor="middle">{t[0]}</text><text x="116" y="-58">{t[1]}</text><text x="116" y="70">{t[2]}</text>
  <text class="weak" x="0" y="146" text-anchor="middle">{t[3]}</text><text x="-116" y="70" text-anchor="end">{t[4]}</text><text x="-116" y="-58" text-anchor="end">{t[5]}</text></svg>'''

def page(L):
    zh = L['lang'] == 'zh-CN'; r = L['root']; i = 0 if zh else 1
    mailto = f'mailto:{MAIL}?subject=' + ('HipLab%20%E5%86%85%E6%B5%8B%E6%8A%A5%E5%90%8D' if zh else 'HipLab%20beta%20sign-up')
    nav = ''.join(f'<a class="l" href="#{h}">{E(t)}</a>' for h, t in zip(['features', 'library', 'beta', 'faq'], L['nav']))
    lang = (f'<span class="lang"><b aria-current="true">{L["here_label"]}</b><a href="{L["other"]}" hreflang="{"en" if zh else "zh-CN"}">{L["other_label"]}</a></span>'
            if zh else f'<span class="lang"><a href="{L["other"]}" hreflang="zh-CN">{L["other_label"]}</a><b aria-current="true">{L["here_label"]}</b></span>')
    stats = ''.join(f'<div><b>{a}</b><span>{E(b)}</span></div>' for a, b in L['stats'])
    tests = ''.join(f'<figure><img src="{r}img/p-{d}-280.webp" width="280" height="280" alt="" loading="lazy"><figcaption><b>{E(z if zh else e)}</b>'
                    f'<span>{s} {L["sec"]}{" · " + L["sided"] if sd else ""}</span></figcaption></figure>' for d, z, e, s, sd in TESTS)
    levels = ''.join(f'<li><b>{E(a)}</b><span>{E(b)}</span></li>' for a, b in L['levels'])
    routines = ''.join(f'<li>{E(x)}</li>' for x in L['routines'])
    filters = ''.join(f'<span{" class=on" if k == 0 else ""}>{E(x)}</span>' for k, x in enumerate(L['filters']))
    cards = ''
    for k, (d, z, e, c, chair) in enumerate(WALL):
        big = k == 0; w = 540 if big else 280
        tag = CAT[c][i] + (' · ' + L['chair'] if chair else '')
        cards += (f'<figure class="card{" big" if big else ""}"><img src="{r}img/p-{d}-{w}.webp" width="{w}" height="{w}" alt="" loading="lazy">'
                  f'<figcaption><b>{E(z if zh else e)}</b><span>{E(tag)}</span></figcaption></figure>')
    extras = ''.join(f'<li><b>{E(a)}</b><span>{E(b)}</span></li>' for a, b in L['extras'])
    how = ''.join(f'<li><i>{n + 1}</i><b>{E(a)}</b><span>{E(b)}</span></li>' for n, (a, b) in enumerate(L['how']))
    facts = ''.join(f'<div><span>{E(a)}</span><b>{E(b)}</b></div>' for a, b in L['facts'])
    faq = ''.join(f'<details><summary>{E(q)}</summary><p>{E(a)}</p></details>' for q, a in L['faq'])
    ctas = (f'<div class="cta"><a class="btn" href="{PLAY}" rel="noopener"><i></i>{E(L["cta"])}</a>'
            f'<span class="alt">{E(L["mail_q"])}<a href="{mailto}">{E(L["mail_a"])}</a></span></div>')
    return f'''<!doctype html>
<html lang="{L['lang']}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>{E(L['title'])}</title>
<meta name="description" content="{E(L['desc'])}">
<meta property="og:title" content="{E(L['title'])}"><meta property="og:description" content="{E(L['desc'])}"><meta property="og:type" content="website">
<meta name="theme-color" content="#f3f5f1">
<link rel="alternate" hreflang="zh-CN" href="{'./' if zh else '../'}"><link rel="alternate" hreflang="en" href="{'en/' if zh else './'}">
<link rel="icon" href="{r}img/icon-96.png"><link rel="apple-touch-icon" href="{r}img/icon-192.png">
<link rel="preload" href="{r}fonts/hl.woff2" as="font" type="font/woff2" crossorigin>
<link rel="stylesheet" href="{r}style.css">
</head>
<body class="{'zh' if zh else 'en'}">
<nav>
  <a class="brand" href="./"><img src="{r}img/icon-96.png" width="38" height="38" alt=""><div><b>HipLab</b><span>{E(L['sub'])}</span></div></a>
  <div class="links">{nav}{lang}<a class="btn sm" href="#beta"><i></i>{E(L['cta_sm'])}</a></div>
</nav>

<header class="hero">
  <div class="copy">
    <div class="badge"><i></i>{E(L['badge'])}</div>
    <h1>HipLab<span>{E(L['sub'])}</span></h1>
    <p class="what">{E(L['what'])}</p>
    <p class="lead">{E(L['lead'])}</p>
    {ctas}
    <div class="meta">{E(L['ios'])}</div>
  </div>
  <div class="visual">
    <div class="ring r2"></div><div class="glow"></div><div class="ring"></div>
    {shot(L, 'ui-routine', L['alt_routine'], 'phone ph-b')}
    {shot(L, 'ui-check', L['alt_check'], 'phone ph-a', True)}
  </div>
</header>
<div class="stats">{stats}</div>

<section class="feat" id="features">
  <div class="txt"><h2>{E(L['f1h'])}</h2><p>{E(L['f1p'])}</p></div>
  <div class="tests">{tests}</div>
</section>

<section class="feat rev">
  <div class="txt"><h2>{E(L['f2h'])}</h2><p>{E(L['f2p'])}</p><ul class="levels">{levels}</ul><p class="note">{E(L['f2n'])}</p></div>
  <div class="radar"><div class="score">{E(L['radar_score'])}<b>{E(L['radar_lv'])}</b></div>{radar(L)}</div>
</section>

<section class="feat">
  <div class="txt"><h2>{E(L['f3h'])}</h2><p>{E(L['f3p'])}</p><div class="sub">{E(L['f3l'])}</div><ul class="chips">{routines}</ul></div>
  <div class="solo">{shot(L, 'ui-routine', L['alt_routine'])}</div>
</section>

<section class="lib" id="library">
  <div class="libhead"><h2>{E(L['f4h'])}</h2><p>{E(L['f4p'])}</p></div>
  <div class="filters" aria-hidden="true">{filters}</div>
  <div class="grid">{cards}</div>
  <p class="more">{E(L['f4m'])}</p>
</section>

<section class="feat rev">
  <div class="txt"><h2>{E(L['f5h'])}</h2><p>{E(L['f5p'])}</p></div>
  <div class="duo">{shot(L, 'ui-groups', L['alt_groups'], 'phone d1')}{shot(L, 'ui-editor', L['alt_editor'], 'phone d2')}</div>
</section>

<section class="feat">
  <div class="txt"><h2>{E(L['f6h'])}</h2><p>{E(L['f6p'])}</p><div class="sub">{E(L['extras_h'])}</div><ul class="extras">{extras}</ul></div>
  <div class="solo">{shot(L, 'ui-records', L['alt_records'])}</div>
</section>

<section class="how">
  <h2>{E(L['how_h'])}</h2>
  <ol>{how}</ol>
</section>

<section class="beta" id="beta">
  <div>
    <h2>{E(L['beta_h'])}</h2>
    <p>{E(L['beta_p'])}</p>
    <div class="facts">{facts}</div>
    {ctas}
    <p class="small">{E(L['beta_mail'])}</p>
  </div>
  <div class="visual sm">{shot(L, 'ui-library', L['alt_lib'], 'phone ph-c')}</div>
</section>

<section class="faq" id="faq">
  <h2>{E(L['faq_h'])}</h2>
  <div class="qs">{faq}</div>
</section>

<footer>
  <div class="fbrand"><img src="{r}img/icon-96.png" width="28" height="28" alt=""><b>HipLab</b><span>{E(L['sub'])}</span></div>
  <p>{E(L['foot_disc'])}</p>
  <p>{E(L['foot_contact'])} · <a href="mailto:{MAIL}">{MAIL}</a> · © 2026 HipLab · <a href="{L['other']}">{L['other_label']}</a></p>
</footer>
</body>
</html>
'''

def main():
    if os.path.isdir(DIST): shutil.rmtree(DIST)
    os.makedirs(os.path.join(DIST, 'en')); os.makedirs(os.path.join(DIST, 'fonts'))
    pages = {'index.html': page(ZH), 'en/index.html': page(EN)}
    for p, h in pages.items(): open(os.path.join(DIST, p), 'w', encoding='utf-8').write(h)
    shutil.copytree(os.path.join(SRC, 'img'), os.path.join(DIST, 'img'))
    shutil.copy(os.path.join(SRC, 'style.css'), DIST)
    # subset font to glyphs actually used
    text = ''.join(re.sub(r'<[^>]+>', ' ', html.unescape(h)) for h in pages.values())
    text += open(os.path.join(SRC, 'style.css'), encoding='utf-8').read()
    chars = ''.join(sorted(set(text) | set(' 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ·–—…→（）、，。：；？！“”‘’%/+-.,:;?!\'"()&')))
    ttf = os.environ.get('NOTO_TTF', '/workspace/work/sites/fonts/NotoSansSC.ttf')
    out = os.path.join(SRC, 'fonts', 'hl.woff2'); os.makedirs(os.path.dirname(out), exist_ok=True)
    if os.path.exists(ttf):
        tf = os.path.join(HERE, '.chars.txt'); open(tf, 'w', encoding='utf-8').write(chars)
        env = dict(os.environ); env['PYTHONPATH'] = os.pathsep.join(filter(None, [env.get('PYTHONPATH'), '/workspace/work/pylib']))
        subprocess.run([sys.executable, '-m', 'fontTools.subset', ttf, f'--text-file={tf}', '--flavor=woff2',
                        '--layout-features=*', '--no-hinting', '--desubroutinize', f'--output-file={out}'], check=True, env=env)
        os.remove(tf)
    shutil.copy(out, os.path.join(DIST, 'fonts', 'hl.woff2'))
    tot = sum(os.path.getsize(os.path.join(a, f)) for a, _, fs in os.walk(DIST) for f in fs)
    print('chars', len(chars), 'font', os.path.getsize(out), 'dist bytes', tot)

if __name__ == '__main__':
    main()
