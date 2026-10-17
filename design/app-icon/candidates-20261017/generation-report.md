# HipLab App Icon 候选生成记录

制作日期：2026-10-17（Asia/Shanghai）。

## 产品与本轮范围

HipLab 是中文离线的髋部灵活度、开胯、柔韧性与主动控制训练 App，面向久坐人群、舞者及希望循序改善活动度的人。视觉优先传达好看、有生命力、轻松舒展、稳定与温和陪练。

本轮交付 A「舒展精灵」、B「灵活小水獭」、C「萌芽伙伴」各两张，共六个独立光栅候选。每张调用一次内置生成器，无图片参考，全部原样保留，不重试、不替换、不后期修图、不缩放。未制作矢量源文件、Adaptive Icon 分层或 Monochrome；选定后再进行 Android 工程化资产制作和遮罩验证。

## 真实工具与模型信息

- 生成通道：Codex 内置 `image_gen.imagegen`（运行时函数 `image_gen__imagegen`）。
- 工具只返回 `image_url` 与 `output_hint`，未暴露具体模型名称、版本或后端 provider；本报告不推测它们。
- 约束模式：`main-prompt constraints`。每张完整 Prompt 的 `Constraints:` 段就是实际提交的精确约束文本。
- 输出：PNG，原生尺寸均为 1254 × 1254。Prompt 请求约 1536 × 1536，保留服务返回尺寸，未重采样。
- 色值为生成提示中的设计目标；生成结果中的轻微色调与明暗变化按原图保留，不将其声明为逐像素精确色值。
- 构图提示已要求识别特征向内留白；本轮为美术探索，尚未宣称通过 Android Adaptive Icon 安全区或系统遮罩验收。

## 候选索引

| 编号 | 方向 | 主体色 | 第二角色色 | 纯背景色 | 原生尺寸 |
|---|---|---|---|---|---|
| A1 | 舒展精灵 · 青玉舒展 | `#3CCFA4` | `#1F6F59` | `#0C0D0F` | 1254 × 1254 |
| A2 | 舒展精灵 · 暖白回弹 | `#3CCFA4` | `#1F6F59` | `#F2F3F5` | 1254 × 1254 |
| B1 | 灵活小水獭 · 稳稳转身 | `#3CCFA4` | `#DDF7EC` | `#16171A` | 1254 × 1254 |
| B2 | 灵活小水獭 · 温和伸展 | `#3CCFA4` | `#1F6F59` | `#F2F3F5` | 1254 × 1254 |
| C1 | 萌芽伙伴 · 青玉生长 | `#3CCFA4` | `#DDF7EC` | `#0C0D0F` | 1254 × 1254 |
| C2 | 萌芽伙伴 · 温和陪伴 | `#3CCFA4` | `#1F6F59` | `#F2F3F5` | 1254 × 1254 |

## A1 — 舒展精灵 · 青玉舒展

柔软连续的身体和轻轻打开的双臂暗示活动度与轻松舒展；下部厚实体块传达稳定。

- 交付文件：[A1-stretch-sprite-graphite.png](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/A1-stretch-sprite-graphite.png)
- 绝对路径：`E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/A1-stretch-sprite-graphite.png`
- 原始生成路径：`C:/Users/29485/.codex/generated_images/01a1487f-b397-70b3-8597-8146bd141c6d/exec-aa2f4fc2-7e90-4103-9461-8e78bcb7e1c3.png`
- 实际尺寸：1254 × 1254；文件大小：1,293,249 bytes。
- 颜色映射：主体 `#3CCFA4`；a single broad deep-jade #1F6F59 inner belly region that follows the torso curve; use the same deep-jade color for two small widely spaced simple eyes；纯背景 `#0C0D0F`。双眼及必要面部标记复用两种角色色，不引入额外语义色。
- 真实模型信息：内置 image_gen；具体模型名称及 provider 未由工具暴露。
- 约束交付：main-prompt constraints。

![A1 舒展精灵 · 青玉舒展](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/A1-stretch-sprite-graphite.png)

完整原始 Prompt：

```text
Create one complete full-bleed 1:1 square image, approximately 1536 × 1536.
Background: fill the entire square with solid #0C0D0F. Keep #0C0D0F clearly visible in all four normal square corners and every open area surrounding the character.
Subject: one original soft humanoid stretch sprite, a compact friendly creature with a generous rounded head, a single elastic bean-like torso and two thick short round-ended arms gently opening outward at unequal heights. Keep both arms visible and merge them naturally into one flowing body contour. Suggest an easy morning stretch without depicting an exercise lesson, complex human anatomy, separate fingers, joints or clothing. Its single defining feature is the graceful open arc formed by its unified torso and arms; broad grounded lower-body mass gives a stable relaxed feeling.
Complexity: use only 4–7 large basic shapes and at most two broad internal character color regions. Use two simple eyes and one tiny mouth only if essential for expression. Remove every nonessential line, outline, anatomical detail, texture and decoration. Keep the character unmistakable at 32 × 32.
Color behavior: use exactly three semantic colors in the entire image: jade green #3CCFA4 for the dominant character body, #1F6F59 for a single broad deep-jade #1F6F59 inner belly region that follows the torso curve; use the same deep-jade color for two small widely spaced simple eyes, plus #0C0D0F only for the background. Use only these two character color families for facial marks.
Composition: keep the character upright, emerging visually from the lower-left, filling approximately 75–80% of the square while preserving breathing room around every identifying feature. Let only the nonessential lower base approach the bottom edge. Keep the entire face and paired identifying features safely inward from the canvas edges so later circular cropping can preserve their identity. Do not tilt the image or main mark.
Style: prioritize first-glance beauty, lively character appeal, endearing mature cuteness, and a harmonious strong silhouette. Use large soft forms, compact proportions, thick rounded contours and ultra-clean graphic color masses. The head remains upright; the body may gently curve as part of its natural anatomy. Calm, quietly happy, ready to encourage a gentle practice. Prefer one decisive shape over explanatory details. Add an extremely, extremely subtle, almost imperceptible sense of depth through a barely-there neo-skeuomorphic treatment.
Finish: show only this one complete character on the full-canvas background, with clean surfaces and normal square outer corners.
Constraints: Use no text, letters, watermark, border, frame, card, presentation mask, medical cross, anatomical pelvis, bones, unclothed human anatomy, exercise equipment, instructional pose diagram, extra subject, scenery, fragile lines, sharp tips, narrow gaps, unnecessary outlines, tiny details, decorative marks, photorealistic material, metal, glass, dramatic bevel, glossy hotspot, deep occlusion, extrusion, strong three-dimensional rendering, or external cast shadow. Keep the background solid and uniform, with no texture, halo, vignette, or lighting variation.
```

## A2 — 舒展精灵 · 暖白回弹

偏梨形的弹性身体与环抱式圆臂表现温和回弹和主动控制，暖白底带来更轻松的日常感。

- 交付文件：[A2-stretch-sprite-ivory.png](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/A2-stretch-sprite-ivory.png)
- 绝对路径：`E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/A2-stretch-sprite-ivory.png`
- 原始生成路径：`C:/Users/29485/.codex/generated_images/01a1487f-b397-70b3-8597-8146bd141c6d/exec-32f36eb9-765a-4911-a39d-6b285c918ab4.png`
- 实际尺寸：1254 × 1254；文件大小：1,249,635 bytes。
- 颜色映射：主体 `#3CCFA4`；one broad deep-jade #1F6F59 inner torso crescent that follows the curved body; reuse this deep-jade for two tiny widely spaced simple eyes；纯背景 `#F2F3F5`。双眼及必要面部标记复用两种角色色，不引入额外语义色。
- 真实模型信息：内置 image_gen；具体模型名称及 provider 未由工具暴露。
- 约束交付：main-prompt constraints。

![A2 舒展精灵 · 暖白回弹](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/A2-stretch-sprite-ivory.png)

完整原始 Prompt：

```text
Create one complete full-bleed 1:1 square image, approximately 1536 × 1536.
Background: fill the entire square with solid #F2F3F5. Keep #F2F3F5 clearly visible in all four normal square corners and every open area surrounding the character.
Subject: one original soft humanoid stretch sprite, a lovable compact pear-shaped character with a large rounded head, a thick gently curved torso and two short broad round-ended arms. One arm opens outward and the other curves softly forward in a gentle self-supporting stretch; both are fully visible, fused into the same continuous silhouette. Its single defining feature is the springy continuous waist-to-arm curve, relaxed and balanced rather than acrobatic. Omit feet detail, fingers, joints, clothing and instructional anatomy.
Complexity: use only 4–7 large basic shapes and at most two broad internal character color regions. Use two simple eyes and one tiny mouth only if essential for expression. Remove every nonessential line, outline, anatomical detail, texture and decoration. Keep the character unmistakable at 32 × 32.
Color behavior: use exactly three semantic colors in the entire image: jade green #3CCFA4 for the dominant character body, #1F6F59 for one broad deep-jade #1F6F59 inner torso crescent that follows the curved body; reuse this deep-jade for two tiny widely spaced simple eyes, plus #F2F3F5 only for the background. Use only these two character color families for facial marks.
Composition: keep the character upright, emerging visually from the lower-right, filling approximately 75–80% of the square while preserving breathing room around every identifying feature. Let only the nonessential lower base approach the bottom edge. Keep the entire face and paired identifying features safely inward from the canvas edges so later circular cropping can preserve their identity. Do not tilt the image or main mark.
Style: prioritize first-glance beauty, lively character appeal, endearing mature cuteness, and a harmonious strong silhouette. Use large soft forms, compact proportions, thick rounded contours and ultra-clean graphic color masses. Use a softly buoyant compact silhouette and charming mature simplicity. Keep the head upright, with the movement contained in the soft body contour. Prefer one decisive shape over explanatory details. Add an extremely, extremely subtle, almost imperceptible sense of depth through a barely-there neo-skeuomorphic treatment.
Finish: show only this one complete character on the full-canvas background, with clean surfaces and normal square outer corners.
Constraints: Use no text, letters, watermark, border, frame, card, presentation mask, medical cross, anatomical pelvis, bones, unclothed human anatomy, exercise equipment, instructional pose diagram, extra subject, scenery, fragile lines, sharp tips, narrow gaps, unnecessary outlines, tiny details, decorative marks, photorealistic material, metal, glass, dramatic bevel, glossy hotspot, deep occlusion, extrusion, strong three-dimensional rendering, or external cast shadow. Keep the background solid and uniform, with no texture, halo, vignette, or lighting variation.
```

## B1 — 灵活小水獭 · 稳稳转身

宽厚水獭身体提供可靠陪练感，头身之间的平缓转向暗示灵活与主动控制。

- 交付文件：[B1-otter-graphite.png](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/B1-otter-graphite.png)
- 绝对路径：`E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/B1-otter-graphite.png`
- 原始生成路径：`C:/Users/29485/.codex/generated_images/01a1487f-c7a1-7e51-ad88-f5d287b19d98/exec-375b3d35-a282-40f2-afea-370e3555054c.png`
- 实际尺寸：1254 × 1254；文件大小：1,253,708 bytes。
- 颜色映射：主体 `#3CCFA4`；one continuous pale mint-ivory #DDF7EC muzzle-to-belly patch; use jade #3CCFA4 for the two simple eyes within the pale face patch；纯背景 `#16171A`。双眼及必要面部标记复用两种角色色，不引入额外语义色。
- 真实模型信息：内置 image_gen；具体模型名称及 provider 未由工具暴露。
- 约束交付：main-prompt constraints。

![B1 灵活小水獭 · 稳稳转身](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/B1-otter-graphite.png)

完整原始 Prompt：

```text
Create one complete full-bleed 1:1 square image, approximately 1536 × 1536.
Background: fill the entire square with solid #16171A. Keep #16171A clearly visible in all four normal square corners and every open area surrounding the character.
Subject: one extremely simplified friendly little otter companion in a compact head-and-upper-body view, with a large soft rounded head, two tiny broad rounded ears both fully visible, and a broad stable curved torso. Give the creature a subtle gentle turn through the torso while its face remains upright toward the viewer. Its single species-defining feature is one broad pale muzzle-and-belly region fused into a continuous soft patch, with an endearing otter-like cheek width. Keep the small forelimbs merged into the sides; omit fur, whiskers, water, props, detailed paws and tail.
Complexity: use only 4–7 large basic shapes and at most two broad internal character color regions. Use two simple eyes and one tiny mouth only if essential for expression. Remove every nonessential line, outline, anatomical detail, texture and decoration. Keep the character unmistakable at 32 × 32.
Color behavior: use exactly three semantic colors in the entire image: jade green #3CCFA4 for the dominant character body, #DDF7EC for one continuous pale mint-ivory #DDF7EC muzzle-to-belly patch; use jade #3CCFA4 for the two simple eyes within the pale face patch, plus #16171A only for the background. Use only these two character color families for facial marks.
Composition: keep the character upright, emerging visually from the lower-left, filling approximately 75–80% of the square while preserving breathing room around every identifying feature. Let only the nonessential lower base approach the bottom edge. Keep the entire face and paired identifying features safely inward from the canvas edges so later circular cropping can preserve their identity. Do not tilt the image or main mark.
Style: prioritize first-glance beauty, lively character appeal, endearing mature cuteness, and a harmonious strong silhouette. Use large soft forms, compact proportions, thick rounded contours and ultra-clean graphic color masses. Express a gentle encouraging coach, stable and unhurried, with wide cheeks and a small compact torso. No dramatic twist or precise teaching pose. Prefer one decisive shape over explanatory details. Add an extremely, extremely subtle, almost imperceptible sense of depth through a barely-there neo-skeuomorphic treatment.
Finish: show only this one complete character on the full-canvas background, with clean surfaces and normal square outer corners.
Constraints: Use no text, letters, watermark, border, frame, card, presentation mask, medical cross, anatomical pelvis, bones, unclothed human anatomy, exercise equipment, instructional pose diagram, extra subject, scenery, fragile lines, sharp tips, narrow gaps, unnecessary outlines, tiny details, decorative marks, photorealistic material, metal, glass, dramatic bevel, glossy hotspot, deep occlusion, extrusion, strong three-dimensional rendering, or external cast shadow. Keep the background solid and uniform, with no texture, halo, vignette, or lighting variation.
```

## B2 — 灵活小水獭 · 温和伸展

一侧轻轻舒展的宽圆身体保留水獭的柔软陪伴感，以深青绿面腹色区提高暖白底的识别。

- 交付文件：[B2-otter-ivory.png](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/B2-otter-ivory.png)
- 绝对路径：`E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/B2-otter-ivory.png`
- 原始生成路径：`C:/Users/29485/.codex/generated_images/01a1487f-c7a1-7e51-ad88-f5d287b19d98/exec-a9efbf59-afd8-4907-9d81-019ef808b75c.png`
- 实际尺寸：1254 × 1254；文件大小：1,258,229 bytes。
- 颜色映射：主体 `#3CCFA4`；one continuous deep-jade #1F6F59 muzzle-to-belly patch; place two small jade #3CCFA4 eyes inside the face portion；纯背景 `#F2F3F5`。双眼及必要面部标记复用两种角色色，不引入额外语义色。
- 真实模型信息：内置 image_gen；具体模型名称及 provider 未由工具暴露。
- 约束交付：main-prompt constraints。

![B2 灵活小水獭 · 温和伸展](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/B2-otter-ivory.png)

完整原始 Prompt：

```text
Create one complete full-bleed 1:1 square image, approximately 1536 × 1536.
Background: fill the entire square with solid #F2F3F5. Keep #F2F3F5 clearly visible in all four normal square corners and every open area surrounding the character.
Subject: one extremely simplified friendly little otter companion in a compact head-and-upper-body view. Use a big rounded head with two broad tiny round ears fully visible, a wide heavy stable torso, and one side of the torso gently lengthening into a short round-ended stretching forelimb while the opposite side remains grounded. Its single species-defining feature is the otter's broad softly rounded muzzle-and-belly patch, connected as one purposeful color region. Keep paired forelimbs visible as simple body lobes. Omit whiskers, fur, water, props, detailed paws and tail.
Complexity: use only 4–7 large basic shapes and at most two broad internal character color regions. Use two simple eyes and one tiny mouth only if essential for expression. Remove every nonessential line, outline, anatomical detail, texture and decoration. Keep the character unmistakable at 32 × 32.
Color behavior: use exactly three semantic colors in the entire image: jade green #3CCFA4 for the dominant character body, #1F6F59 for one continuous deep-jade #1F6F59 muzzle-to-belly patch; place two small jade #3CCFA4 eyes inside the face portion, plus #F2F3F5 only for the background. Use only these two character color families for facial marks.
Composition: keep the character upright, emerging visually from the lower-right, filling approximately 75–80% of the square while preserving breathing room around every identifying feature. Let only the nonessential lower base approach the bottom edge. Keep the entire face and paired identifying features safely inward from the canvas edges so later circular cropping can preserve their identity. Do not tilt the image or main mark.
Style: prioritize first-glance beauty, lively character appeal, endearing mature cuteness, and a harmonious strong silhouette. Use large soft forms, compact proportions, thick rounded contours and ultra-clean graphic color masses. The expression should feel quietly attentive and reassuring. Its movement is only a gentle reaching body curve, never an animal illustration with many limb details. Prefer one decisive shape over explanatory details. Add an extremely, extremely subtle, almost imperceptible sense of depth through a barely-there neo-skeuomorphic treatment.
Finish: show only this one complete character on the full-canvas background, with clean surfaces and normal square outer corners.
Constraints: Use no text, letters, watermark, border, frame, card, presentation mask, medical cross, anatomical pelvis, bones, unclothed human anatomy, exercise equipment, instructional pose diagram, extra subject, scenery, fragile lines, sharp tips, narrow gaps, unnecessary outlines, tiny details, decorative marks, photorealistic material, metal, glass, dramatic bevel, glossy hotspot, deep occlusion, extrusion, strong three-dimensional rendering, or external cast shadow. Keep the background solid and uniform, with no texture, halo, vignette, or lighting variation.
```

## C1 — 萌芽伙伴 · 青玉生长

两片钝圆叶形与厚实芽苗身体传达每天一点点进步，石墨底突出青玉主体的生命力。

- 交付文件：[C1-sprout-graphite.png](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/C1-sprout-graphite.png)
- 绝对路径：`E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/C1-sprout-graphite.png`
- 原始生成路径：`C:/Users/29485/.codex/generated_images/01a1487f-e4d7-7470-aa56-fffead7b92d9/exec-5c762b51-67cb-4303-bd33-3f010a6a5368.png`
- 实际尺寸：1254 × 1254；文件大小：1,279,349 bytes。
- 颜色映射：主体 `#3CCFA4`；one broad pale mint-ivory #DDF7EC oval face-and-belly region; reuse jade #3CCFA4 for two tiny widely spaced simple eyes within that patch；纯背景 `#0C0D0F`。双眼及必要面部标记复用两种角色色，不引入额外语义色。
- 真实模型信息：内置 image_gen；具体模型名称及 provider 未由工具暴露。
- 约束交付：main-prompt constraints。

![C1 萌芽伙伴 · 青玉生长](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/C1-sprout-graphite.png)

完整原始 Prompt：

```text
Create one complete full-bleed 1:1 square image, approximately 1536 × 1536.
Background: fill the entire square with solid #0C0D0F. Keep #0C0D0F clearly visible in all four normal square corners and every open area surrounding the character.
Subject: one original anthropomorphic sprout companion, built from a thick rounded bean-like body and exactly two broad blunt rounded leaf lobes growing directly from the crown without a thin stem. Both leaves are fully visible and form a soft open V with round ends, slightly different in height but balanced. Its single defining feature is this pair of broad rounded leaves. Give the character a compact large-headed upper-body feeling with a grounded soft base. Omit pots, soil, scenery, leaf veins, extra shoots and botanical realism.
Complexity: use only 4–7 large basic shapes and at most two broad internal character color regions. Use two simple eyes and one tiny mouth only if essential for expression. Remove every nonessential line, outline, anatomical detail, texture and decoration. Keep the character unmistakable at 32 × 32.
Color behavior: use exactly three semantic colors in the entire image: jade green #3CCFA4 for the dominant character body, #DDF7EC for one broad pale mint-ivory #DDF7EC oval face-and-belly region; reuse jade #3CCFA4 for two tiny widely spaced simple eyes within that patch, plus #0C0D0F only for the background. Use only these two character color families for facial marks.
Composition: keep the character upright, emerging visually from the lower-left, filling approximately 75–80% of the square while preserving breathing room around every identifying feature. Let only the nonessential lower base approach the bottom edge. Keep the entire face and paired identifying features safely inward from the canvas edges so later circular cropping can preserve their identity. Do not tilt the image or main mark.
Style: prioritize first-glance beauty, lively character appeal, endearing mature cuteness, and a harmonious strong silhouette. Use large soft forms, compact proportions, thick rounded contours and ultra-clean graphic color masses. Feel alive, encouraging and patiently growing, with friendly mature cuteness. Avoid a generic recycling or environmental emblem; the facial character and thick body are the visual center. Prefer one decisive shape over explanatory details. Add an extremely, extremely subtle, almost imperceptible sense of depth through a barely-there neo-skeuomorphic treatment.
Finish: show only this one complete character on the full-canvas background, with clean surfaces and normal square outer corners.
Constraints: Use no text, letters, watermark, border, frame, card, presentation mask, medical cross, anatomical pelvis, bones, unclothed human anatomy, exercise equipment, instructional pose diagram, extra subject, scenery, fragile lines, sharp tips, narrow gaps, unnecessary outlines, tiny details, decorative marks, photorealistic material, metal, glass, dramatic bevel, glossy hotspot, deep occlusion, extrusion, strong three-dimensional rendering, or external cast shadow. Keep the background solid and uniform, with no texture, halo, vignette, or lighting variation.
```

## C2 — 萌芽伙伴 · 温和陪伴

更紧凑的芽苗和舒展开的双叶表达可持续练习，深青绿大色区让暖白背景下的五官与主体层级清楚。

- 交付文件：[C2-sprout-ivory.png](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/C2-sprout-ivory.png)
- 绝对路径：`E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/C2-sprout-ivory.png`
- 原始生成路径：`C:/Users/29485/.codex/generated_images/01a1487f-e4d7-7470-aa56-fffead7b92d9/exec-0da8ff9c-ec06-40ec-aa85-769d549efd3d.png`
- 实际尺寸：1254 × 1254；文件大小：1,230,491 bytes。
- 颜色映射：主体 `#3CCFA4`；one broad deep-jade #1F6F59 rounded inner face-and-belly patch; reuse jade #3CCFA4 for two small widely spaced simple eyes within that patch；纯背景 `#F2F3F5`。双眼及必要面部标记复用两种角色色，不引入额外语义色。
- 真实模型信息：内置 image_gen；具体模型名称及 provider 未由工具暴露。
- 约束交付：main-prompt constraints。

![C2 萌芽伙伴 · 温和陪伴](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/C2-sprout-ivory.png)

完整原始 Prompt：

```text
Create one complete full-bleed 1:1 square image, approximately 1536 × 1536.
Background: fill the entire square with solid #F2F3F5. Keep #F2F3F5 clearly visible in all four normal square corners and every open area surrounding the character.
Subject: one original anthropomorphic sprout companion, a compact soft pear-shaped body with exactly two thick broad rounded leaf lobes merging into its crown, with no narrow stem. Both leaf lobes are complete, one gently opening outward and one curving softly upward; every tip is visibly blunt and round. Its single defining feature is the pair of rounded leaves forming a welcoming stretch-like silhouette. Omit pots, soil, scenery, veins, extra leaves, limbs and botanical realism.
Complexity: use only 4–7 large basic shapes and at most two broad internal character color regions. Use two simple eyes and one tiny mouth only if essential for expression. Remove every nonessential line, outline, anatomical detail, texture and decoration. Keep the character unmistakable at 32 × 32.
Color behavior: use exactly three semantic colors in the entire image: jade green #3CCFA4 for the dominant character body, #1F6F59 for one broad deep-jade #1F6F59 rounded inner face-and-belly patch; reuse jade #3CCFA4 for two small widely spaced simple eyes within that patch, plus #F2F3F5 only for the background. Use only these two character color families for facial marks.
Composition: keep the character upright, emerging visually from the lower-right, filling approximately 75–80% of the square while preserving breathing room around every identifying feature. Let only the nonessential lower base approach the bottom edge. Keep the entire face and paired identifying features safely inward from the canvas edges so later circular cropping can preserve their identity. Do not tilt the image or main mark.
Style: prioritize first-glance beauty, lively character appeal, endearing mature cuteness, and a harmonious strong silhouette. Use large soft forms, compact proportions, thick rounded contours and ultra-clean graphic color masses. Make it charming and composed, a living daily-practice companion with a stable heavy base and open leaf rhythm. Avoid generic ecological-symbol styling. Prefer one decisive shape over explanatory details. Add an extremely, extremely subtle, almost imperceptible sense of depth through a barely-there neo-skeuomorphic treatment.
Finish: show only this one complete character on the full-canvas background, with clean surfaces and normal square outer corners.
Constraints: Use no text, letters, watermark, border, frame, card, presentation mask, medical cross, anatomical pelvis, bones, unclothed human anatomy, exercise equipment, instructional pose diagram, extra subject, scenery, fragile lines, sharp tips, narrow gaps, unnecessary outlines, tiny details, decorative marks, photorealistic material, metal, glass, dramatic bevel, glossy hotspot, deep occlusion, extrusion, strong three-dimensional rendering, or external cast shadow. Keep the background solid and uniform, with no texture, halo, vignette, or lighting variation.
```

## 品牌配色应用说明

青玉绿 `#3CCFA4` 是共同的 IP 识别锚点，表达轻松舒展与身体活力；深青绿 `#1F6F59` 承担面腹或内侧的大色区，强调稳定与控制；浅薄荷白 `#DDF7EC` 在石墨底上提供柔和亲近的陪练感。石墨底探索当前深色环境，暖近白 `#F2F3F5` 探索后续浅色环境。选定后宜固定角色的主体色和五官关系，再适配背景。详见 [brand-color-notes.md](E:/AII/ugk-icons/output/hiplab-icon-candidates-20261017/brand-color-notes.md)。

