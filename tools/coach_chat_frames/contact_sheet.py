"""Arrange the ten review screenshots; no image or pixel comparison."""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, default=Path(
        'test/_shots/coach-chat'))
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    states = ['empty', 'waiting', 'plan-card', 'recommendations', 'failure']
    labels = ['\u7a7a\u6001', '\u7b49\u5f85', '\u8ba1\u5212\u5361',
              '\u63a8\u8350\u5361', '\u5931\u8d25\uff08\u6a21\u62df\uff09']
    thumb_size = (234, 506)
    gap, header, label_height = 20, 78, 42
    cell_width, cell_height = thumb_size[0], thumb_size[1] + label_height
    width = gap + len(states) * (cell_width + gap)
    height = header + gap + 2 * (cell_height + gap)
    sheet = Image.new('RGB', (width, height), '#e9eeeb')
    draw = ImageDraw.Draw(sheet)
    font_path = Path(__file__).resolve().parents[2] / 'assets/fonts/NotoSansSC.ttf'
    title_font = ImageFont.truetype(str(font_path), 24)
    label_font = ImageFont.truetype(str(font_path), 17)
    draw.text((gap, 13), 'HipLab - SDK chat review', font=title_font, fill='#143d31')
    draw.text((gap, 46), 'Light / Dark - simulated UI states, no pixel comparison',
              font=label_font, fill='#496357')
    for row, mode in enumerate(['light', 'dark']):
        for column, (state, label) in enumerate(zip(states, labels)):
            x = gap + column * (cell_width + gap)
            y = header + gap + row * (cell_height + gap)
            draw.rounded_rectangle((x - 2, y - 2, x + cell_width + 2,
                                    y + cell_height + 2),
                                   radius=7, fill='white', outline='#c5d5cc')
            draw.text((x + 8, y + 8), f'{mode} - {label}',
                      font=label_font, fill='#193a2b')
            with Image.open(args.input / f'{mode}-{state}.png') as image:
                thumb = ImageOps.contain(image.convert('RGB'), thumb_size,
                                         method=Image.Resampling.LANCZOS)
                sheet.paste(thumb, (x, y + label_height))
    target = args.output or args.input / 'contact-sheet.png'
    sheet.save(target)
    print(target)


if __name__ == '__main__':
    main()
