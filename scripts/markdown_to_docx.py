from __future__ import annotations

import re
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from xml.sax.saxutils import escape


DOCX_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
DOC_REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
CP_NS = "http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
DC_NS = "http://purl.org/dc/elements/1.1/"
DCTERMS_NS = "http://purl.org/dc/terms/"
XSI_NS = "http://www.w3.org/2001/XMLSchema-instance"


def clean_inline_markdown(text: str) -> str:
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"\1", text)
    text = text.replace("`", "")
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text)
    text = re.sub(r"__(.+?)__", r"\1", text)
    text = re.sub(r"\*(.+?)\*", r"\1", text)
    text = re.sub(r"_(.+?)_", r"\1", text)
    return text.strip()


def parse_table_row(line: str) -> list[str]:
    stripped = line.strip().strip("|")
    return [clean_inline_markdown(cell.strip()) for cell in stripped.split("|")]


def is_table_separator(line: str) -> bool:
    return bool(re.match(r"^\|\s*[-:| ]+\|\s*$", line.strip()))


def parse_markdown(content: str) -> list[tuple]:
    elements: list[tuple] = []
    paragraph_buffer: list[str] = []
    seen_chapter = False
    lines = content.splitlines()
    i = 0

    def flush_paragraph() -> None:
        if not paragraph_buffer:
            return
        text = " ".join(part.strip() for part in paragraph_buffer).strip()
        paragraph_buffer.clear()
        if text:
            elements.append(("paragraph", clean_inline_markdown(text)))

    while i < len(lines):
        raw_line = lines[i]
        line = raw_line.rstrip()

        if line.startswith("```"):
            flush_paragraph()
            code_lines: list[str] = []
            i += 1
            while i < len(lines) and not lines[i].rstrip().startswith("```"):
                code_lines.append(lines[i].rstrip("\n"))
                i += 1
            elements.append(("code", code_lines))
            i += 1
            continue

        if re.match(r"^\|.*\|\s*$", line):
            flush_paragraph()
            table_lines: list[str] = []
            while i < len(lines) and re.match(r"^\|.*\|\s*$", lines[i].rstrip()):
                table_lines.append(lines[i].rstrip())
                i += 1
            rows = [parse_table_row(table_line) for table_line in table_lines]
            if len(rows) >= 2 and is_table_separator(table_lines[1]):
                rows = [rows[0], *rows[2:]]
            elements.append(("table", rows))
            continue

        if not line.strip():
            flush_paragraph()
            elements.append(("blank",))
            i += 1
            continue

        if line.strip() == "---":
            flush_paragraph()
            elements.append(("blank",))
            i += 1
            continue

        heading_match = re.match(r"^(#{1,4})\s+(.*)$", line)
        if heading_match:
            flush_paragraph()
            level = len(heading_match.group(1))
            text = clean_inline_markdown(heading_match.group(2))
            if level == 2 and text.startswith("Chapitre"):
                if seen_chapter:
                    elements.append(("page_break",))
                seen_chapter = True
            elements.append(("heading", level, text))
            i += 1
            continue

        bullet_match = re.match(r"^-\s+(.*)$", line)
        if bullet_match:
            flush_paragraph()
            elements.append(("bullet", clean_inline_markdown(bullet_match.group(1))))
            i += 1
            continue

        number_match = re.match(r"^\d+\.\s+(.*)$", line)
        if number_match:
            flush_paragraph()
            elements.append(("number", clean_inline_markdown(number_match.group(1))))
            i += 1
            continue

        paragraph_buffer.append(line)
        i += 1

    flush_paragraph()
    return elements


def text_run(text: str, *, bold: bool = False, preserve: bool = False) -> str:
    safe_text = escape(text)
    run_properties = ""
    if bold:
        run_properties = "<w:rPr><w:b/></w:rPr>"
    space_attr = ' xml:space="preserve"' if preserve else ""
    return f"<w:r>{run_properties}<w:t{space_attr}>{safe_text}</w:t></w:r>"


def paragraph_xml(
    text: str = "",
    *,
    style: str | None = None,
    bullet: bool = False,
    number: bool = False,
    bold: bool = False,
    preserve: bool = False,
) -> str:
    properties: list[str] = []
    if style:
        properties.append(f'<w:pStyle w:val="{style}"/>')
    if bullet:
        properties.append("<w:numPr><w:ilvl w:val=\"0\"/><w:numId w:val=\"1\"/></w:numPr>")
    if number:
        properties.append("<w:numPr><w:ilvl w:val=\"0\"/><w:numId w:val=\"2\"/></w:numPr>")

    if style == "Title":
        properties.append("<w:jc w:val=\"center\"/>")

    properties_xml = f"<w:pPr>{''.join(properties)}</w:pPr>" if properties else ""

    if text:
        run = text_run(text, bold=bold, preserve=preserve)
    else:
        run = "<w:r/>"

    return f"<w:p>{properties_xml}{run}</w:p>"


def blank_paragraph() -> str:
    return "<w:p><w:r/></w:p>"


def page_break_xml() -> str:
    return "<w:p><w:r><w:br w:type=\"page\"/></w:r></w:p>"


def table_xml(rows: list[list[str]]) -> str:
    if not rows:
        return ""

    max_cols = max(len(row) for row in rows)
    grid = "".join("<w:gridCol w:w=\"2400\"/>" for _ in range(max_cols))
    row_xml_parts: list[str] = []

    for row_index, row in enumerate(rows):
        padded = row + [""] * (max_cols - len(row))
        cell_xml_parts: list[str] = []
        for cell in padded:
            header_props = (
                "<w:shd w:val=\"clear\" w:color=\"auto\" w:fill=\"D9EAF7\"/>"
                if row_index == 0
                else ""
            )
            cell_paragraph = paragraph_xml(cell, bold=row_index == 0)
            cell_xml_parts.append(
                "<w:tc>"
                "<w:tcPr>"
                "<w:tcW w:w=\"0\" w:type=\"auto\"/>"
                f"{header_props}"
                "</w:tcPr>"
                f"{cell_paragraph}"
                "</w:tc>"
            )
        row_xml_parts.append(f"<w:tr>{''.join(cell_xml_parts)}</w:tr>")

    return (
        "<w:tbl>"
        "<w:tblPr>"
        "<w:tblW w:w=\"0\" w:type=\"auto\"/>"
        "<w:tblBorders>"
        "<w:top w:val=\"single\" w:sz=\"8\" w:space=\"0\" w:color=\"4A5568\"/>"
        "<w:left w:val=\"single\" w:sz=\"8\" w:space=\"0\" w:color=\"4A5568\"/>"
        "<w:bottom w:val=\"single\" w:sz=\"8\" w:space=\"0\" w:color=\"4A5568\"/>"
        "<w:right w:val=\"single\" w:sz=\"8\" w:space=\"0\" w:color=\"4A5568\"/>"
        "<w:insideH w:val=\"single\" w:sz=\"4\" w:space=\"0\" w:color=\"A0AEC0\"/>"
        "<w:insideV w:val=\"single\" w:sz=\"4\" w:space=\"0\" w:color=\"A0AEC0\"/>"
        "</w:tblBorders>"
        "</w:tblPr>"
        f"<w:tblGrid>{grid}</w:tblGrid>"
        f"{''.join(row_xml_parts)}"
        "</w:tbl>"
    )


def build_document(elements: list[tuple]) -> str:
    body_parts: list[str] = []
    first_heading = True

    for element in elements:
        kind = element[0]

        if kind == "heading":
            _, level, text = element
            style = {
                1: "Title",
                2: "Heading1",
                3: "Heading2",
                4: "Heading3",
            }.get(level, "Heading3")
            if first_heading and style == "Title":
                body_parts.append(paragraph_xml(text, style=style))
            else:
                body_parts.append(paragraph_xml(text, style=style))
            first_heading = False
            continue

        if kind == "paragraph":
            _, text = element
            body_parts.append(paragraph_xml(text, style="Normal"))
            continue

        if kind == "bullet":
            _, text = element
            body_parts.append(paragraph_xml(text, style="Normal", bullet=True))
            continue

        if kind == "number":
            _, text = element
            body_parts.append(paragraph_xml(text, style="Normal", number=True))
            continue

        if kind == "code":
            _, code_lines = element
            if not code_lines:
                body_parts.append(paragraph_xml("", style="CodeBlock"))
            for code_line in code_lines:
                body_parts.append(
                    paragraph_xml(code_line or " ", style="CodeBlock", preserve=True)
                )
            continue

        if kind == "table":
            _, rows = element
            body_parts.append(table_xml(rows))
            continue

        if kind == "page_break":
            body_parts.append(page_break_xml())
            continue

        if kind == "blank":
            body_parts.append(blank_paragraph())

    section = (
        "<w:sectPr>"
        "<w:pgSz w:w=\"11906\" w:h=\"16838\"/>"
        "<w:pgMar w:top=\"1134\" w:right=\"1134\" w:bottom=\"1134\" w:left=\"1134\" "
        "w:header=\"708\" w:footer=\"708\" w:gutter=\"0\"/>"
        "</w:sectPr>"
    )

    return (
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        f"<w:document xmlns:w=\"{DOCX_NS}\" xmlns:r=\"{DOC_REL_NS}\">"
        f"<w:body>{''.join(body_parts)}{section}</w:body>"
        "</w:document>"
    )


def build_styles() -> str:
    return (
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        f"<w:styles xmlns:w=\"{DOCX_NS}\">"
        "<w:docDefaults>"
        "<w:rPrDefault><w:rPr><w:rFonts w:ascii=\"Times New Roman\" w:hAnsi=\"Times New Roman\"/>"
        "<w:sz w:val=\"24\"/><w:szCs w:val=\"24\"/></w:rPr></w:rPrDefault>"
        "<w:pPrDefault><w:pPr><w:spacing w:after=\"120\" w:line=\"276\" w:lineRule=\"auto\"/></w:pPr></w:pPrDefault>"
        "</w:docDefaults>"
        "<w:style w:type=\"paragraph\" w:default=\"1\" w:styleId=\"Normal\">"
        "<w:name w:val=\"Normal\"/>"
        "<w:qFormat/>"
        "<w:pPr><w:jc w:val=\"both\"/><w:spacing w:after=\"120\" w:line=\"276\" w:lineRule=\"auto\"/></w:pPr>"
        "</w:style>"
        "<w:style w:type=\"paragraph\" w:styleId=\"Title\">"
        "<w:name w:val=\"Title\"/>"
        "<w:basedOn w:val=\"Normal\"/>"
        "<w:qFormat/>"
        "<w:pPr><w:jc w:val=\"center\"/><w:spacing w:before=\"240\" w:after=\"240\"/></w:pPr>"
        "<w:rPr><w:b/><w:sz w:val=\"34\"/><w:szCs w:val=\"34\"/></w:rPr>"
        "</w:style>"
        "<w:style w:type=\"paragraph\" w:styleId=\"Heading1\">"
        "<w:name w:val=\"heading 1\"/>"
        "<w:basedOn w:val=\"Normal\"/>"
        "<w:next w:val=\"Normal\"/>"
        "<w:qFormat/>"
        "<w:pPr><w:spacing w:before=\"240\" w:after=\"120\"/></w:pPr>"
        "<w:rPr><w:b/><w:sz w:val=\"30\"/><w:szCs w:val=\"30\"/></w:rPr>"
        "</w:style>"
        "<w:style w:type=\"paragraph\" w:styleId=\"Heading2\">"
        "<w:name w:val=\"heading 2\"/>"
        "<w:basedOn w:val=\"Normal\"/>"
        "<w:next w:val=\"Normal\"/>"
        "<w:qFormat/>"
        "<w:pPr><w:spacing w:before=\"180\" w:after=\"100\"/></w:pPr>"
        "<w:rPr><w:b/><w:sz w:val=\"26\"/><w:szCs w:val=\"26\"/></w:rPr>"
        "</w:style>"
        "<w:style w:type=\"paragraph\" w:styleId=\"Heading3\">"
        "<w:name w:val=\"heading 3\"/>"
        "<w:basedOn w:val=\"Normal\"/>"
        "<w:next w:val=\"Normal\"/>"
        "<w:qFormat/>"
        "<w:pPr><w:spacing w:before=\"120\" w:after=\"80\"/></w:pPr>"
        "<w:rPr><w:b/><w:sz w:val=\"24\"/><w:szCs w:val=\"24\"/></w:rPr>"
        "</w:style>"
        "<w:style w:type=\"paragraph\" w:styleId=\"CodeBlock\">"
        "<w:name w:val=\"Code Block\"/>"
        "<w:basedOn w:val=\"Normal\"/>"
        "<w:pPr><w:spacing w:after=\"0\"/><w:ind w:left=\"480\" w:right=\"240\"/>"
        "<w:shd w:val=\"clear\" w:color=\"auto\" w:fill=\"F3F4F6\"/></w:pPr>"
        "<w:rPr><w:rFonts w:ascii=\"Courier New\" w:hAnsi=\"Courier New\"/>"
        "<w:sz w:val=\"20\"/><w:szCs w:val=\"20\"/></w:rPr>"
        "</w:style>"
        "</w:styles>"
    )


def build_numbering() -> str:
    return (
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        f"<w:numbering xmlns:w=\"{DOCX_NS}\">"
        "<w:abstractNum w:abstractNumId=\"0\">"
        "<w:multiLevelType w:val=\"hybridMultilevel\"/>"
        "<w:lvl w:ilvl=\"0\">"
        "<w:start w:val=\"1\"/>"
        "<w:numFmt w:val=\"bullet\"/>"
        "<w:lvlText w:val=\"\"/>"
        "<w:lvlJc w:val=\"left\"/>"
        "<w:pPr><w:ind w:left=\"720\" w:hanging=\"360\"/></w:pPr>"
        "<w:rPr><w:rFonts w:ascii=\"Symbol\" w:hAnsi=\"Symbol\"/></w:rPr>"
        "</w:lvl>"
        "</w:abstractNum>"
        "<w:num w:numId=\"1\"><w:abstractNumId w:val=\"0\"/></w:num>"
        "<w:abstractNum w:abstractNumId=\"1\">"
        "<w:multiLevelType w:val=\"multilevel\"/>"
        "<w:lvl w:ilvl=\"0\">"
        "<w:start w:val=\"1\"/>"
        "<w:numFmt w:val=\"decimal\"/>"
        "<w:lvlText w:val=\"%1.\"/>"
        "<w:lvlJc w:val=\"left\"/>"
        "<w:pPr><w:ind w:left=\"720\" w:hanging=\"360\"/></w:pPr>"
        "</w:lvl>"
        "</w:abstractNum>"
        "<w:num w:numId=\"2\"><w:abstractNumId w:val=\"1\"/></w:num>"
        "</w:numbering>"
    )


def build_settings() -> str:
    return (
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        f"<w:settings xmlns:w=\"{DOCX_NS}\">"
        "<w:zoom w:percent=\"100\"/>"
        "</w:settings>"
    )


def build_root_rels() -> str:
    return (
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        f"<Relationships xmlns=\"{REL_NS}\">"
        "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"word/document.xml\"/>"
        "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties\" Target=\"docProps/core.xml\"/>"
        "<Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties\" Target=\"docProps/app.xml\"/>"
        "</Relationships>"
    )


def build_document_rels() -> str:
    return (
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        f"<Relationships xmlns=\"{REL_NS}\">"
        "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>"
        "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering\" Target=\"numbering.xml\"/>"
        "<Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings\" Target=\"settings.xml\"/>"
        "</Relationships>"
    )


def build_content_types() -> str:
    return (
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
        "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>"
        "<Default Extension=\"xml\" ContentType=\"application/xml\"/>"
        "<Override PartName=\"/word/document.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\"/>"
        "<Override PartName=\"/word/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml\"/>"
        "<Override PartName=\"/word/numbering.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml\"/>"
        "<Override PartName=\"/word/settings.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml\"/>"
        "<Override PartName=\"/docProps/core.xml\" ContentType=\"application/vnd.openxmlformats-package.core-properties+xml\"/>"
        "<Override PartName=\"/docProps/app.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.extended-properties+xml\"/>"
        "</Types>"
    )


def build_core_props(title: str) -> str:
    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    safe_title = escape(title)
    return (
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        f"<cp:coreProperties xmlns:cp=\"{CP_NS}\" xmlns:dc=\"{DC_NS}\" "
        f"xmlns:dcterms=\"{DCTERMS_NS}\" xmlns:dcmitype=\"http://purl.org/dc/dcmitype/\" "
        f"xmlns:xsi=\"{XSI_NS}\">"
        f"<dc:title>{safe_title}</dc:title>"
        "<dc:creator>Codex</dc:creator>"
        "<cp:lastModifiedBy>Codex</cp:lastModifiedBy>"
        f"<dcterms:created xsi:type=\"dcterms:W3CDTF\">{now}</dcterms:created>"
        f"<dcterms:modified xsi:type=\"dcterms:W3CDTF\">{now}</dcterms:modified>"
        "</cp:coreProperties>"
    )


def build_app_props() -> str:
    return (
        "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        "<Properties xmlns=\"http://schemas.openxmlformats.org/officeDocument/2006/extended-properties\" "
        "xmlns:vt=\"http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes\">"
        "<Application>Codex Markdown to DOCX</Application>"
        "</Properties>"
    )


def convert(markdown_path: Path, docx_path: Path) -> None:
    markdown_content = markdown_path.read_text(encoding="utf-8")
    elements = parse_markdown(markdown_content)
    title = markdown_path.stem.replace("_", " ")

    docx_path.parent.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(docx_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("[Content_Types].xml", build_content_types())
        archive.writestr("_rels/.rels", build_root_rels())
        archive.writestr("docProps/core.xml", build_core_props(title))
        archive.writestr("docProps/app.xml", build_app_props())
        archive.writestr("word/document.xml", build_document(elements))
        archive.writestr("word/styles.xml", build_styles())
        archive.writestr("word/numbering.xml", build_numbering())
        archive.writestr("word/settings.xml", build_settings())
        archive.writestr("word/_rels/document.xml.rels", build_document_rels())


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: python scripts/markdown_to_docx.py <input.md> <output.docx>")
        return 1

    input_path = Path(sys.argv[1]).resolve()
    output_path = Path(sys.argv[2]).resolve()

    if not input_path.exists():
        print(f"Input file not found: {input_path}")
        return 1

    convert(input_path, output_path)
    print(f"Created: {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
