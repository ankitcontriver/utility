import os
import re
import time
import pdfplumber
import pandas as pd
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
 
INPUT_FOLDER = r"C:\Users\Kavita\goavanto.com\Reports - Documents\Daily Reports\Pacific Southwest Container\QA Report\2025\Format for QA"
OUTPUT_FILENAME = "clean file.xlsx"
 
FIELDS = [
    "Vendor Name",
    "Invoice Number",
    "Invoice Date",
    "Invoice Amount",
    "Posting Date",
    "Due Date",
    "Discount Amount",
    "Discount Date",
    "Xact",
    "Comment"
]
 
def extract_entries(text):
    # Each entry starts with 'Remit To'
    entries = re.split(r'(?=Remit To)', text)
    extracted_data = []
    for entry in entries:
        if not entry.strip():
            continue
        data = {}
        lines = entry.splitlines()
        try:
            # Vendor Name after 'Remit To'
            data["Vendor Name"] = lines[0].replace("Remit To", "").strip()
            # Use regex/split to extract values for each field
            def grab(pattern, default=""):
                match = re.search(pattern, entry, re.IGNORECASE)
                return match.group(1).strip() if match else default
 
            data["Invoice Number"] = grab(r"Invoice Number:\s*([^\n]*)")
            data["Invoice Date"] = grab(r"Invoice Date:\s*([^\n]*)")
            data["Invoice Amount"] = grab(r"Invoice Amount:\s*([^\n]*)")
            data["Posting Date"] = grab(r"Posting Date:\s*([^\n]*)")
            data["Due Date"] = grab(r"Due Date:\s*([^\n]*)")
            data["Discount Amount"] = grab(r"Discount Amount:\s*([^\n]*)")
            data["Discount Date"] = grab(r"Discount Date:\s*([^\n]*)")
            data["Xact"] = grab(r"Xact:\s*([^\n]*)")
            data["Comment"] = grab(r"Comment:\s*([^\n]*)")
        except Exception as e:
            print(f"Error parsing entry: {e}")
        extracted_data.append(data)
    return extracted_data
 
def process_pdf(pdf_path, output_folder):
    with pdfplumber.open(pdf_path) as pdf:
        all_text = ""
        for page in pdf.pages:
            all_text += page.extract_text() + "\n"
    entries = extract_entries(all_text)
    df = pd.DataFrame(entries, columns=FIELDS)
    output_path = os.path.join(output_folder, OUTPUT_FILENAME)
    df.to_excel(output_path, index=False)
    print(f"Processed: {pdf_path} → {output_path}")
 
class NewPDFHandler(FileSystemEventHandler):
    def on_created(self, event):
        if event.is_directory or not event.src_path.lower().endswith('.pdf'):
            return
        # Wait a moment for file to finish copying
        time.sleep(2)
        process_pdf(event.src_path, os.path.dirname(event.src_path))
 
if _name_ == "_main_":
    print(f"Watching folder: {INPUT_FOLDER}")
    event_handler = NewPDFHandler()
    observer = Observer()
    observer.schedule(event_handler, INPUT_FOLDER, recursive=False)
    observer.start()
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
