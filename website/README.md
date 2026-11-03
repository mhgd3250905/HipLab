# HipLab 官网（website/）

- `src/`：样式、图片（WebP，真实 App 截图与动作海报）、子集字体 `fonts/hl.woff2`。
- `build.py`：渲染中文 `/` 与英文 `/en/`，按实际用字子集 Noto Sans SC（`NOTO_TTF`），输出 `dist/`。
- `tools/prep_images.py`：从 UI 截图（`/workspace/work/hiplab-ui-review/r2`）与 `assets/drill_media` 生成 WebP。
- `deploy.py`：预览部署。默认 Cloudflare Pages 直传（`hiplab-preview.pages.dev`）；`TARGET=worker` 走 Workers（需 Workers Scripts:Edit 权限）。不绑定自定义域名。

```
python3 website/build.py && PYTHONPATH=/workspace/work/pylib python3 website/deploy.py
```
文案中的动作名、自测项、套路与数值取自 `assets/hip/hip-content.json`、`assets/coach/catalog.json` 与 App 界面（动作库显示 210 个动作）。
