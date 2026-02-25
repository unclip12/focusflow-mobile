#!/usr/bin/env python3
import re
import json
import os
import sys

# Regex to match the footer which denotes the end of a page and contains the page number
PAGE_MARKER = re.compile(r'FAS[A-Za-z0-9_\-]+\.indd\s+(\d+)')

SUBJECT_MAP = [
    (31, 92, "Biochemistry", "General Principles"),
    (93, 120, "Immunology", "General Principles"),
    (121, 200, "Microbiology", "General Principles"),
    (201, 226, "Pathology", "General Principles"),
    (227, 254, "Pharmacology", "General Principles"),
    (255, 278, "Public Health Sciences", "General Principles"),
    (279, 282, "Intro", "General Principles"),
    (283, 328, "Cardiovascular", "Organ Systems"),
    (329, 362, "Endocrine", "Organ Systems"),
    (363, 408, "Gastrointestinal", "Organ Systems"),
    (409, 448, "Hematology & Oncology", "Organ Systems"),
    (449, 498, "Musculoskeletal & Skin", "Organ Systems"),
    (499, 568, "Neurology", "Organ Systems"),
    (569, 594, "Psychiatry", "Organ Systems"),
    (595, 628, "Renal", "Organ Systems"),
    (629, 676, "Reproductive", "Organ Systems"),
    (677, 706, "Respiratory", "Organ Systems"),
]

STOP_WORDS = ("The ", "This ", "In ", "A ", "An ", "For ", "To ", "By ", "With ", "And ", "Of ", "As ", "Is ", "Are ")

def get_subject_system(page_num):
    for start, end, subj, sys_name in SUBJECT_MAP:
        if start <= page_num <= end:
            return subj, sys_name
    return "Unknown", "Unknown"

def strip_running_headers(lines):
    cleaned = []
    for line in lines:
        ls = line.strip()
        if ls.isdigit():
            continue
            
        upper_line = line.upper()
        has_section = "SEC TION" in upper_line or "SECTION" in upper_line
        subjects = [
            "BIOCHEMISTR", "IMMUNOLOG", "MICROBIOLOGY", "PHARMACOLOG", "PATHOLOG", 
            "CARDIOVASCULAR", "NEUROLOGY", "HEMATOLOG", "GASTROINTESTINAL", 
            "ENDOCRINE", "RENAL", "REPRODUCTIVE", "RESPIRATORY", "MUSCULOSKELETAL", "PSYCHIATRY"
        ]
        has_subject = any(s in upper_line for s in subjects)
        
        if has_section and has_subject:
            continue
            
        cleaned.append(line)
    return cleaned

def is_level_1(line, prev_blank):
    if not prev_blank: return False
    ls = line.strip()
    if len(ls) > 55 or len(ls) < 3: return False
    if not ls[0].isupper(): return False
    if ls.isupper(): return False
    if '.' in ls or ',' in ls: return False
    if ls.isdigit(): return False
    if ls.startswith(STOP_WORDS): return False
    return True

def is_level_2(line, prev_blank):
    if not prev_blank: return False
    ls = line.strip()
    if len(ls) < 8 or len(ls) > 60: return False
    if not ls[0].isupper(): return False
    if ls.isupper(): return False
    if ls.endswith('.'): return False
    if ls.startswith(STOP_WORDS): return False
    return True

def is_level_3(line):
    ls = line.strip()
    if len(ls) >= 40 or len(ls) < 3: return False
    if not ls.isupper(): return False
    if not re.match(r'^[A-Z\s/\-]+$', ls): return False
    return True

def process_page(page_num, lines):
    subj, sys_name = get_subject_system(page_num)
    status = "read" if 33 <= page_num <= 49 else "unread"
    
    cleaned_lines = strip_running_headers(lines)
    
    topics = []
    l1_node = None
    l2_node = None
    
    prev_blank = True
    
    for line in cleaned_lines:
        ls = line.strip()
        if not ls:
            prev_blank = True
            continue
            
        if is_level_3(ls):
            l3_node = {"t": ls[:80]}
            if l2_node is not None:
                if "s" not in l2_node: l2_node["s"] = []
                l2_node["s"].append(l3_node)
            elif l1_node is not None:
                if "s" not in l1_node: l1_node["s"] = []
                l1_node["s"].append(l3_node)
            else:
                l1_node = {"t": f"{subj} — continued", "s": [l3_node]}
                topics.append(l1_node)
            prev_blank = False
            
        elif is_level_1(ls, prev_blank):
            l1_node = {"t": ls[:80]}
            topics.append(l1_node)
            l2_node = None
            prev_blank = False
            
        elif is_level_2(ls, prev_blank):
            l2_node = {"t": ls[:80]}
            if l1_node is not None:
                if "s" not in l1_node: l1_node["s"] = []
                l1_node["s"].append(l2_node)
            else:
                l1_node = {"t": f"{subj} — continued", "s": [l2_node]}
                topics.append(l1_node)
            prev_blank = False
            
        else:
            prev_blank = False
            
    if not topics:
        topics.append({"t": f"{subj} — continued"})
        
    return {
        "pageNum": page_num,
        "subject": subj,
        "system": sys_name,
        "status": status,
        "topics": topics
    }

def main():
    input_path = sys.argv[1] if len(sys.argv) > 1 else './fa_2025.txt'
    out_path = 'assets/data/fa_2025_seed.json'
    
    if not os.path.exists(input_path):
        print(f"Error: Input file {input_path} not found.")
        sys.exit(1)
        
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    
    pages_data = []
    current_page_lines = []
    
    with open(input_path, 'r', encoding='utf-8', errors='replace') as f:
        for line in f:
            match = PAGE_MARKER.search(line)
            if match:
                page_num = int(match.group(1))
                if 31 <= page_num <= 706:
                    page_obj = process_page(page_num, current_page_lines)
                    pages_data.append(page_obj)
                    if len(pages_data) % 50 == 0:
                        print(f"Processed {len(pages_data)} pages...")
                current_page_lines = []
            else:
                current_page_lines.append(line)

    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(pages_data, f, ensure_ascii=False, indent=2)
        
    print(f"\nSuccess! Processed a total of {len(pages_data)} pages (31-706).")
    print(f"Output saved to: {out_path}")

if __name__ == '__main__':
    main()