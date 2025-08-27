#!/usr/bin/env python3
"""
Analyze causes data from the CSV file to understand cause mapping issues
"""

import csv
import re
from collections import Counter

def analyze_causes():
    csv_path = "app/views/smart_match/data/giving_connection_scraped_data.csv"
    
    all_causes = []
    multi_cause_ngos = []
    single_cause_ngos = []
    
    with open(csv_path, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            if row.get('scraping_status') != 'success':
                continue
                
            nonprofit_name = row.get('nonprofit_name', '')
            causes_raw = row.get('causes', '')
            
            if not causes_raw:
                continue
                
            # Split causes by comma and clean them
            causes = [cause.strip() for cause in causes_raw.split(',') if cause.strip()]
            
            if len(causes) > 1:
                multi_cause_ngos.append({
                    'name': nonprofit_name,
                    'causes': causes,
                    'raw': causes_raw
                })
            else:
                single_cause_ngos.append({
                    'name': nonprofit_name,
                    'causes': causes,
                    'raw': causes_raw
                })
            
            all_causes.extend(causes)
    
    # Analyze results
    print("=== CAUSE ANALYSIS ===")
    print(f"Total NGOs: {len(multi_cause_ngos) + len(single_cause_ngos)}")
    print(f"NGOs with multiple causes: {len(multi_cause_ngos)} ({len(multi_cause_ngos)/(len(multi_cause_ngos) + len(single_cause_ngos))*100:.1f}%)")
    print(f"NGOs with single cause: {len(single_cause_ngos)} ({len(single_cause_ngos)/(len(multi_cause_ngos) + len(single_cause_ngos))*100:.1f}%)")
    
    print(f"\nTotal cause instances: {len(all_causes)}")
    print(f"Unique causes: {len(set(all_causes))}")
    
    # Show top causes
    cause_counts = Counter(all_causes)
    print(f"\n=== TOP 20 CAUSES ===")
    for cause, count in cause_counts.most_common(20):
        print(f"{cause}: {count}")
    
    # Show some examples of multi-cause NGOs
    print(f"\n=== EXAMPLES OF MULTI-CAUSE NGOS ===")
    for ngo in multi_cause_ngos[:10]:
        print(f"\n{ngo['name']}")
        print(f"  Raw: {ngo['raw']}")
        print(f"  Parsed: {', '.join(ngo['causes'])}")
    
    # Look for potential synonyms
    print(f"\n=== POTENTIAL SYNONYMS ===")
    causes_list = list(set(all_causes))
    
    # Look for similar causes
    synonyms = {}
    for cause in causes_list:
        cause_lower = cause.lower()
        similar = []
        for other_cause in causes_list:
            if cause != other_cause:
                other_lower = other_cause.lower()
                # Check for similar words
                if any(word in other_lower for word in cause_lower.split()) or any(word in cause_lower for word in other_lower.split()):
                    similar.append(other_cause)
        if similar:
            synonyms[cause] = similar
    
    for cause, similar in list(synonyms.items())[:10]:
        print(f"\n{cause} -> {', '.join(similar)}")
    
    # Check for education-related causes
    print(f"\n=== EDUCATION-RELATED CAUSES ===")
    education_causes = [cause for cause in causes_list if 'education' in cause.lower() or 'school' in cause.lower() or 'learning' in cause.lower()]
    for cause in education_causes:
        count = cause_counts[cause]
        print(f"{cause}: {count}")

if __name__ == "__main__":
    analyze_causes()
