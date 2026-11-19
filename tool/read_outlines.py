"""Read HKBU course-outline PDFs and record whether each course has an exam or a test.

The assessment type is taken only from the left column of section
"11. Assessment Methods". Wording inside the task description is ignored,
because a test row often says "written examination" in that description.
"""

import json
import re
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import pymupdf

ROOT = Path(__file__).resolve().parents[1]
COURSES = ROOT / "assets" / "courses.json"
PDF_DIR = Path.home() / "AppData" / "Local" / "Temp" / "hkbu-outlines"
OUT = ROOT / "assets" / "assessments.json"

EXAM_RE = re.compile(
    r"examinations?|\bexams?\b|筆試|口試|考試|考核|期終|期末|終期|大考",
    re.I,
)
TEST_RE = re.compile(
    r"\btests?\b|\bquizzes\b|\bquiz\b|mid[-\s]*term|筆試|測驗|小測|測試|期中考|期中試",
    re.I,
)


def outline_url(code: str) -> str:
    return f"http://arcourseoutline.hkbu.edu.hk/outline/{code}.pdf"


def download(code: str, url: str) -> str:
    dest = PDF_DIR / f"{code}.pdf"
    if dest.exists() and dest.stat().st_size > 1000:
        return "cached"
    try:
        urllib.request.urlretrieve(url, dest)
    except Exception as error:  # noqa: BLE001 - record every failure and continue
        dest.unlink(missing_ok=True)
        return f"download:{error}"
    if dest.stat().st_size < 1000:
        dest.unlink(missing_ok=True)
        return "download:too-small"
    return "ok"


def lines_of(page):
    grouped: dict[int, list] = {}
    for word in page.get_text("words"):
        y = round(word[1])
        grouped.setdefault(y, []).append(word)
    return [grouped[key] for key in sorted(grouped)]


def is_header(text: str) -> bool:
    folded = text.lower()
    return "assessment methods" in folded or "評核" in text


def weight_line(words) -> bool:
    return any(130 <= word[0] <= 210 and word[4] == "%" for word in words)


def type_text(words) -> str:
    parts = [word[4] for word in words if word[0] < 125]
    return " ".join(parts).strip()


HEADER_WORDS = {
    "type",
    "of",
    "assessment",
    "methods",
    "weighting",
    "cilos",
    "to",
    "be",
    "addressed",
    "description",
    "tasks",
    "方法",
    "評核",
    "種類",
}


def without_header_words(label: str) -> str:
    kept = [word for word in label.split() if word.lower().strip("():") not in HEADER_WORDS]
    return " ".join(kept)


def assessment_types(path: Path) -> tuple[list[str] | None, str]:
    doc = pymupdf.open(path)
    start = None
    for index, page in enumerate(doc):
        for line in lines_of(page):
            text = " ".join(word[4] for word in line)
            if is_header(text):
                start = (index, line[0][1])
                break
        if start:
            break
    if start is None:
        return None, "no-section"

    types: list[str] = []
    current = ""
    started = False
    begun = False
    header_bottom = None
    for index, page in enumerate(doc):
        if index < start[0]:
            continue
        for line in lines_of(page):
            if index == start[0] and line[0][1] <= start[1] + 8:
                continue
            text = " ".join(word[4] for word in line)
            if header_bottom is None:
                if "Weighting" in text or "比重" in text:
                    header_bottom = line[0][1] + 36
                continue
            if index == start[0] and line[0][1] < header_bottom:
                continue
            if text.startswith("Last Update") or text.startswith("最後更新") or text.startswith("*** END"):
                begun = True
                break
            label = type_text(line)
            if weight_line(line):
                if started and current.strip():
                    types.append(re.sub(r"\s+", " ", current.strip()))
                if not started:
                    label = without_header_words(label)
                current = label
                started = True
            elif started and label:
                current = f"{current} {label}".strip()
        if begun:
            break
    if started and current.strip():
        types.append(re.sub(r"\s+", " ", current.strip()))
    if not types:
        return None, "no-rows"
    return types, "ok"


def classify(types: list[str] | None) -> dict:
    if types is None:
        return {"exam": None, "test": None, "types": []}
    blob = "\n".join(types)
    return {
        "exam": bool(EXAM_RE.search(blob)),
        "test": bool(TEST_RE.search(blob)),
        "types": types,
    }


def main() -> None:
    courses = json.loads(COURSES.read_text(encoding="utf-8"))["courses"]
    PDF_DIR.mkdir(parents=True, exist_ok=True)
    coded = [(course["code"], course.get("outline") or "") for course in courses]
    downloadable = [code for code, url in coded if url]

    status: dict[str, str] = {}
    with ThreadPoolExecutor(max_workers=12) as pool:
        futures = {pool.submit(download, code, url): code for code, url in coded if url}
        for future in as_completed(futures):
            status[futures[future]] = future.result()

    records = {}
    problems = []
    for code, url in coded:
        if not url:
            records[code] = {"exam": None, "test": None, "types": [], "status": "no-outline"}
            continue
        if status.get(code) not in {"ok", "cached"}:
            records[code] = {"exam": None, "test": None, "types": [], "status": status.get(code, "download")}
            problems.append((code, records[code]["status"]))
            continue
        types, read_status = assessment_types(PDF_DIR / f"{code}.pdf")
        row = classify(types)
        row["status"] = read_status
        records[code] = row
        if read_status != "ok":
            problems.append((code, read_status))

    payload = {
        "collectedOn": "2026-11-19",
        "source": "HKBU course outline PDFs, assessment-type column only",
        "courses": records,
    }
    OUT.write_text(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    exam = sum(1 for row in records.values() if row["exam"] is True)
    test = sum(1 for row in records.values() if row["test"] is True)
    no_exam = sum(1 for row in records.values() if row["exam"] is False)
    no_test = sum(1 for row in records.values() if row["test"] is False)
    unknown = sum(1 for row in records.values() if row["exam"] is None)
    print(f"courses {len(records)} exam {exam} test {test} no_exam {no_exam} no_test {no_test} unknown {unknown}")
    print("problems", len(problems))
    for code, reason in problems[:40]:
        print(" ", code, reason)


if __name__ == "__main__":
    main()
