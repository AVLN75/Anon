import os
import sqlite3
from datetime import datetime

# Setup Database
conn = sqlite3.connect('files_scan.db')
cursor = conn.cursor()

# Create Table
cursor.execute('''
    CREATE TABLE IF NOT EXISTS files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        path TEXT,
        size_bytes INTEGER,
        last_modified TEXT
    )
''')

# Scan function
search_path = "." # Change this to the directory you want to scan
print(f"Scanning {os.path.abspath(search_path)}...")

for root, dirs, files in os.walk(search_path):
    for file in files:
        full_path = os.path.join(root, file)
        try:
            stats = os.stat(full_path)
            cursor.execute('''
                INSERT INTO files (name, path, size_bytes, last_modified)
                VALUES (?, ?, ?, ?)
            ''', (file, full_path, stats.st_size, datetime.fromtimestamp(stats.st_mtime)))
        except OSError:
            continue # Skip files with permission issues

conn.commit()
conn.close()
print("Scan complete. Database saved as 'files_scan.db'.")
