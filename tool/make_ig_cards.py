"""Instagram cards for the latest HKBU Timetable update. 1080x1350."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

W, H = 1080, 1350
NAVY = (12, 60, 109)
DEEP = (8, 41, 82)
GOLD = (244, 176, 64)
PAPER = (244, 245, 247)
WHITE = (255, 255, 255)
INK = (16, 40, 63)
MUTED = (90, 104, 122)
ICE = (231, 238, 245)
BLOCK = (155, 182, 201)
SOFT = (214, 226, 240)
FONT_PATH = r"C:\Windows\Fonts\NotoSansTC-VF.ttf"
OUT = Path(__file__).resolve().parents[1] / "ig-cards"


def font(size, weight):
    face = ImageFont.truetype(FONT_PATH, size)
    face.set_variation_by_axes([weight])
    return face


def text_width(face, value):
    return face.getlength(value)


def tracked(draw, xy, value, face, fill, gap):
    x, y = xy
    for char in value:
        draw.text((x, y), char, font=face, fill=fill)
        x += text_width(face, char) + gap
    return x


def center_text(draw, box, value, face, fill):
    x0, y0, x1, y1 = box
    width = text_width(face, value)
    ascent, descent = face.getmetrics()
    height = ascent + descent
    x = x0 + (x1 - x0 - width) / 2
    y = y0 + (y1 - y0 - height) / 2
    draw.text((x, y), value, font=face, fill=fill)


def header(draw, kicker, title, subtitle, title_size=84):
    draw.rectangle((0, 0, W, 430), fill=NAVY)
    draw.text((72, 64), kicker, font=font(34, 700), fill=GOLD)
    draw.text((72, 140), title, font=font(title_size, 700), fill=WHITE)
    draw.text((72, 250), subtitle, font=font(36, 460), fill=SOFT)
    draw.rectangle((0, 416, W, 434), fill=GOLD)


def footer(draw, value):
    draw.rectangle((0, 1224, W, H), fill=NAVY)
    center_text(draw, (48, 1224, W - 48, H), value, font(34, 500), WHITE)


def card():
    image = Image.new("RGB", (W, H), PAPER)
    return image, ImageDraw.Draw(image)


def chip(draw, xy, label, selected):
    face = font(30, 700)
    width = text_width(face, label) + 48
    x, y = xy
    box = (x, y, x + width, y + 64)
    draw.rounded_rectangle(
        box,
        radius=16,
        fill=NAVY if selected else WHITE,
        outline=None if selected else (210, 220, 230),
        width=2,
    )
    center_text(draw, box, label, face, WHITE if selected else NAVY)
    return width


def course_row(draw, y, code, title, badges):
    draw.rounded_rectangle((72, y, W - 72, y + 168), radius=28, fill=WHITE)
    draw.text((108, y + 32), code, font=font(40, 700), fill=INK)
    draw.text((108, y + 92), title, font=font(28, 450), fill=MUTED)
    x = W - 108
    face = font(26, 700)
    for label in reversed(badges):
        width = text_width(face, label) + 36
        x -= width
        box = (x, y + 52, x + width, y + 108)
        draw.rounded_rectangle(box, radius=16, fill=ICE)
        center_text(draw, box, label, face, NAVY)
        x -= 12


def cover():
    image = Image.new("RGB", (W, H), NAVY)
    draw = ImageDraw.Draw(image)
    tracked(draw, (72, 78), "HKBU TIMETABLE", font(30, 700), GOLD, 3)
    draw.text((72, 140), "今次更新了", font=font(84, 700), fill=WHITE)
    draw.text((72, 250), "選科、講師、桌布，都更好用", font=font(32, 460), fill=SOFT)
    items = [
        "選取無考試/測驗科目",
        "按學系看講師",
        "加入自己的課堂",
        "時間表桌布",
        "課堂顯示講師",
        "避開撞堂班別",
        "網站瀏覽人數",
    ]
    y = 330
    for index, label in enumerate(items, start=1):
        draw.rounded_rectangle((72, y, W - 72, y + 96), radius=24, fill=DEEP)
        draw.text((108, y + 26), f"{index:02d}", font=font(34, 700), fill=GOLD)
        draw.text((210, y + 24), label, font=font(36, 700), fill=WHITE)
        y += 110
    draw.text((72, 1248), "@hkbu_timetable", font=font(34, 700), fill=GOLD)
    image.save(OUT / "01-cover.png")


def no_exam():
    image, draw = card()
    header(draw, "更新 01", "選取無考試/測驗科目", "可以分開選，也可以一起選", 64)
    chip(draw, (72, 490), "無考試", True)
    chip(draw, (280, 490), "無測驗", True)
    course_row(draw, 610, "ACCT4035", "Big Data in Accounting", ["無考試"])
    course_row(draw, 806, "ARTT1006", "Arts Tech Practices", ["無考試", "無測驗"])
    footer(draw, "可以更快知道什麼科目沒有考試/測驗")
    image.save(OUT / "02-no-exam.png")


def lecturers():
    image, draw = card()
    header(draw, "更新 02", "按學系看講師", "點一下，就看到他教的科目")
    draw.rounded_rectangle((72, 486, W - 72, 1060), radius=24, fill=WHITE)
    draw.rounded_rectangle((72, 486, W - 72, 600), radius=24, fill=NAVY)
    draw.rectangle((72, 540, W - 72, 600), fill=NAVY)
    draw.text((104, 514), "計算機科學系", font=font(36, 700), fill=WHITE)
    draw.text((W - 250, 522), "35 人", font=font(28, 500), fill=SOFT)
    people = [("Dr Chan, Chun Pong", "所教科目 · 3 科"), ("Dr Lai, Jean H Y", "所教科目 · 3 科")]
    y = 640
    for name, action in people:
        draw.text((104, y), name, font=font(34, 700), fill=INK)
        label = font(26, 700)
        width = text_width(label, action) + 40
        box = (104, y + 58, 104 + width, y + 118)
        draw.rounded_rectangle(box, radius=14, fill=ICE)
        center_text(draw, box, action, label, NAVY)
        y += 200
    footer(draw, "更方便找你想找的講師")
    image.save(OUT / "03-lecturers.png")


def custom_class():
    image, draw = card()
    header(draw, "更新 03", "加入自己的課堂", "補習、會議，自己加進時間表")
    left, top, right = 72, 490, W - 72
    draw.rounded_rectangle((left, top, right, top + 360), radius=20, fill=WHITE)
    days = ["一", "二", "三", "四", "五", "六"]
    inner = left + 24
    day_w = (right - left - 48) / 6
    draw.rectangle((inner, top + 24, right - 24, top + 84), fill=GOLD)
    face = font(26, 700)
    for index, day in enumerate(days):
        box = (inner + index * day_w, top + 24, inner + (index + 1) * day_w, top + 84)
        center_text(draw, box, day, face, NAVY)
    block = (
        inner + 2 * day_w + 10,
        top + 150,
        inner + 3 * day_w - 10,
        top + 310,
    )
    draw.rounded_rectangle(block, radius=16, fill=BLOCK)
    center_text(draw, block, "補習", font(32, 700), INK)
    draw.rounded_rectangle((72, 890, W - 72, 1100), radius=28, fill=WHITE)
    draw.text((112, 930), "週三", font=font(40, 700), fill=NAVY)
    draw.text((112, 1000), "14:30 – 16:20", font=font(36, 500), fill=INK)
    footer(draw, "更加方便自訂時間表")
    image.save(OUT / "04-custom-class.png")


def wallpaper():
    image, draw = card()
    header(draw, "更新 04", "時間表桌布", "打開手機，就看到這一週")
    phone = (330, 480, 750, 1160)
    draw.rounded_rectangle(phone, radius=48, fill=WHITE, outline=NAVY, width=8)
    screen = (354, 520, 726, 1120)
    draw.rounded_rectangle(screen, radius=28, fill=PAPER)
    draw.rectangle((354, 520, 726, 620), fill=NAVY)
    draw.rectangle((354, 608, 726, 624), fill=GOLD)
    days = ["一", "二", "三", "四", "五", "六"]
    face = font(22, 700)
    for index, day in enumerate(days):
        box = (354 + index * 62, 530, 354 + (index + 1) * 62, 600)
        center_text(draw, box, day, face, WHITE)
    blocks = [
        (372, 680, 470, 820, "COMP"),
        (496, 760, 600, 940, "ISEM"),
        (620, 700, 710, 860, "GCAP"),
    ]
    for box in blocks:
        x0, y0, x1, y1, label = box
        draw.rounded_rectangle((x0, y0, x1, y1), radius=14, fill=BLOCK)
        draw.rectangle((x0, y0, x0 + 8, y1), fill=NAVY)
        center_text(draw, (x0, y0, x1, y1), label, font(22, 700), INK)
    footer(draw, "提供手機桌面")
    image.save(OUT / "05-wallpaper.png")


def show_teacher():
    image, draw = card()
    header(draw, "更新 05", "課堂顯示講師", "色塊裡會寫上講師名字")
    left, top, right = 120, 520, W - 120
    draw.rounded_rectangle((left, top, right, top + 64), radius=12, fill=GOLD)
    face = font(28, 700)
    for index, day in enumerate(["一", "二", "三", "四", "五", "六"]):
        box = (left + index * (right - left) / 6, top, left + (index + 1) * (right - left) / 6, top + 64)
        center_text(draw, box, day, face, NAVY)
    block = (left + 250, top + 130, left + 590, top + 500)
    draw.rounded_rectangle(block, radius=18, fill=BLOCK)
    draw.rectangle((block[0], block[1], block[0] + 12, block[3]), fill=NAVY)
    lines = ["COMP4117", "Mr Cheng, Kam Kong", "Dr Choy, Man Ting", "Dr SHEK, Pui Wah"]
    y = block[1] + 36
    for index, line in enumerate(lines):
        draw.text(
            (block[0] + 28, y),
            line,
            font=font(26 if index else 30, 700 if index == 0 else 450),
            fill=INK,
        )
        y += 52 if index == 0 else 44
    footer(draw, "可以顯示任教導師")
    image.save(OUT / "06-show-teacher.png")


def avoid_clash():
    image, draw = card()
    header(draw, "更新 06", "避開撞堂班別", "只隱藏撞到的那一班", 72)
    rows = [
        ("A 科  00001", "11:30–12:30", "隱藏", True),
        ("A 科  00002", "13:30–14:30", "仍然顯示", False),
        ("B 科  00001", "11:30–12:30", "已選", False),
    ]
    y = 500
    for code, time, state, hidden in rows:
        draw.rounded_rectangle((72, y, W - 72, y + 170), radius=28, fill=WHITE)
        draw.text((108, y + 28), code, font=font(36, 700), fill=MUTED if hidden else INK)
        draw.text((108, y + 90), time, font=font(32, 500), fill=MUTED if hidden else NAVY)
        face = font(28, 700)
        label = state
        width = text_width(face, label) + 36
        box = (W - 108 - width, y + 58, W - 108, y + 114)
        draw.rounded_rectangle(box, radius=16, fill=(253, 236, 236) if hidden else ICE)
        center_text(draw, box, label, face, (180, 35, 24) if hidden else NAVY)
        y += 196
    footer(draw, "撞到的班會收起，其他班還在")
    image.save(OUT / "07-avoid-clash.png")


def visits():
    image, draw = card()
    header(draw, "更新 07", "網站瀏覽人數", "頁首看得到有多少人來過", 72)
    draw.rounded_rectangle((120, 560, W - 120, 1040), radius=36, fill=WHITE)
    center_text(draw, (120, 640, W - 120, 760), "網站瀏覽人數:", font(40, 700), NAVY)
    center_text(draw, (120, 760, W - 120, 960), "11,807", font(120, 700), INK)
    footer(draw, "有人打開網站，數字就會增加")
    image.save(OUT / "08-visits.png")


def main():
    OUT.mkdir(exist_ok=True)
    cover()
    no_exam()
    lecturers()
    custom_class()
    wallpaper()
    show_teacher()
    avoid_clash()
    visits()
    print(OUT)


if __name__ == "__main__":
    main()
