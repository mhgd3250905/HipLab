# 自测对比图透明版（浅色主题预留）

与 `assets/hip/assessment/` 同名的 1080×1080 直通 alpha PNG（无背景、无光晕/地面阴影），
来自 3D-Body `tools/drill-anim/specs/a-deep-squat-r2.js`、`a-thomas-r2.js`、`a-9090-r2.js`（pr 2 渲染，
原始 RGBA 帧按 `place.json` 以 Lanczos 缩放贴到 1080 画布，与 greenscreen 导出相同）。

- `deep-squat-*` / `thomas-*` / `9090-*`：a=松，b=一般，c=紧；`9090-front`/`9090-back` 为追问图。
- 本目录不在 pubspec 资源列表里，不进安装包；浅色主题接入时按需复制到资源目录或在主题里引用。
