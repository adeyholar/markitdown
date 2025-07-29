#!/usr/bin/env python3
"""
Hebrew Grammar Text to Markdown Converter
Converts Gesenius Hebrew Grammar from Archive.org to clean Markdown
"""

import requests
import re
from pathlib import Path

def download_text(url, filename):
    """Download text file from URL"""
    print(f"Downloading from {url}...")
    try:
        response = requests.get(url)
        response.raise_for_status()
        
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(response.text)
        print(f"✓ Downloaded: {filename}")
        return True
    except Exception as e:
        print(f"✗ Download failed: {e}")
        return False

def clean_ocr_text(text):
    """Clean common OCR errors in Hebrew grammar texts"""
    
    # Fix the � character (usually "viz." in academic texts)
    text = re.sub(r'�\s+(imper\.|juss\.|infin\.|perf\.)', r'viz. \1', text)
    text = re.sub(r'�\s+(the|forms|cases|instances)', r'viz. \1', text)
    text = re.sub(r',\s*�\s*,', ', viz.,', text)
    text = re.sub(r'�', 'viz.', text)  # Default replacement
    
    # Fix common abbreviations
    text = re.sub(r'e\s*\.\s*g\s*\.', 'e.g.', text)
    text = re.sub(r'i\s*\.\s*e\s*\.', 'i.e.', text)
    text = re.sub(r'c\s*f\s*\.', 'cf.', text)
    text = re.sub(r'v\s*s\s*\.', 'vs.', text)
    
    # Fix section references
    text = re.sub(r'§\s*(\d+)', r'§\1', text)
    text = re.sub(r'¶\s*(\d+)', r'¶\1', text)
    
    # Fix spacing and punctuation
    text = re.sub(r'\s+', ' ', text)  # Multiple spaces to single
    text = re.sub(r'\s*,\s*', ', ', text)
    text = re.sub(r'\s*\.\s*', '. ', text)
    text = re.sub(r'\s*;\s*', '; ', text)
    text = re.sub(r'\s*:\s*', ': ', text)
    
    # Remove space before punctuation
    text = re.sub(r'\s+([,.;:])', r'\1', text)
    
    return text.strip()

def convert_to_markdown(text):
    """Convert cleaned text to Markdown format"""
    
    lines = text.split('\n')
    markdown_lines = []
    
    # Add header
    markdown_lines.extend([
        "# Gesenius' Hebrew Grammar",
        "",
        "*Converted from Archive.org digitized text*",
        "",
        "---",
        ""
    ])
    
    for line in lines:
        line = line.strip()
        if not line:
            continue
            
        # Clean the line
        line = clean_ocr_text(line)
        
        # Detect and format different types of content
        if re.match(r'^(CHAPTER|PART|SECTION)\s+([IVX]+|\d+)', line, re.IGNORECASE):
            # Main chapters/parts
            markdown_lines.extend(["", f"## {line}", ""])
            
        elif re.match(r'^§\s*\d+', line):
            # Section headings
            markdown_lines.extend(["", f"### {line}", ""])
            
        elif re.match(r'^[A-Z\s]{10,}$', line):
            # All caps lines (likely headings)
            markdown_lines.extend(["", f"### {line}", ""])
            
        elif re.match(r'^\d+\.\s', line) and len(line) < 100:
            # Numbered items (short ones are likely headings)
            markdown_lines.extend(["", f"#### {line}", ""])
            
        elif re.match(r'^[a-z]\)', line):
            # Lettered sub-items
            markdown_lines.extend(["", f"- {line}", ""])
            
        elif line.startswith('NOTE') or line.startswith('Obs.'):
            # Notes and observations
            markdown_lines.extend(["", f"> **{line}**", ""])
            
        else:
            # Regular paragraph content
            markdown_lines.extend([line, ""])
    
    return '\n'.join(markdown_lines)

def main():
    # Configuration
    url = "https://archive.org/stream/hebrewgrammar00geseuoft/hebrewgrammar00geseuoft_djvu.txt"
    raw_file = "gesenius_raw.txt"
    markdown_file = "gesenius_hebrew_grammar.md"
    
    # Download the file
    if not download_text(url, raw_file):
        return
    
    # Read and process the content
    print("Converting to Markdown...")
    try:
        with open(raw_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Convert to markdown
        markdown_content = convert_to_markdown(content)
        
        # Save markdown file
        with open(markdown_file, 'w', encoding='utf-8') as f:
            f.write(markdown_content)
        
        print(f"✓ Conversion completed!")
        print(f"Files created:")
        print(f"  Raw text: {raw_file}")
        print(f"  Markdown: {markdown_file}")
        
        # Show file sizes
        raw_size = Path(raw_file).stat().st_size / 1024
        md_size = Path(markdown_file).stat().st_size / 1024
        print(f"Raw file size: {raw_size:.1f} KB")
        print(f"Markdown file size: {md_size:.1f} KB")
        
        print("\nReview needed for:")
        print("  - Hebrew text formatting")
        print("  - Table structures")
        print("  - Footnotes")
        print("  - Section numbering accuracy")
        
    except Exception as e:
        print(f"✗ Conversion failed: {e}")

if __name__ == "__main__":
    main()