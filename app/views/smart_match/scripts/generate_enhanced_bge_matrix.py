#!/usr/bin/env python3
"""
Generate enhanced BGE nonprofits matrix using BAAI/bge-large-en-v1.5 with comprehensive text processing
Uses the giving_connection_scraped_data.csv file with mission_vision_services, causes, and state columns
This combines the superior BGE model with the enhanced text processing approach
"""

import csv
import json
import os
import sys
import re
from pathlib import Path
from datetime import datetime
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

def clean_text(text):
    """Clean and normalize text"""
    if not text:
        return ""
    
    # Remove extra whitespace and newlines
    text = re.sub(r'\s+', ' ', text.strip())
    
    # Remove special characters but keep important punctuation
    text = re.sub(r'[^\w\s\.,!?;:()&-]', '', text)
    
    return text

def load_csv_data(csv_path):
    """Load nonprofits data from the CSV file"""
    nonprofits_data = []
    
    with open(csv_path, 'r', encoding='utf-8') as file:
        reader = csv.DictReader(file)
        for row in reader:
            # Skip rows with failed scraping
            if row.get('scraping_status') != 'success':
                continue
                
            nonprofit = {
                'id': row.get('url', ''),  # Use URL as ID
                'name': clean_text(row.get('nonprofit_name', '')),
                'mission_vision_services': clean_text(row.get('mission_vision_services', '')),
                'causes': clean_text(row.get('causes', '')),
                'phone': row.get('phone', ''),
                'email': row.get('email', ''),
                'website': row.get('website', ''),
                'address': clean_text(row.get('address', '')),
                'city': clean_text(row.get('city', '')),
                'state': clean_text(row.get('state', '')),
                'hours': row.get('hours', ''),
                'ein': row.get('ein', ''),
                'url': row.get('url', '')
            }
            
            # Only include nonprofits with meaningful data
            if nonprofit['name'] and (nonprofit['mission_vision_services'] or nonprofit['causes']):
                nonprofits_data.append(nonprofit)
    
    return nonprofits_data

def create_enhanced_text_representations(nonprofits_data):
    """Create enhanced text representations for each nonprofit"""
    texts = []
    total = len(nonprofits_data)
    
    print(f"   Processing {total} nonprofits...")
    
    for i, np in enumerate(nonprofits_data):
        # Show progress every 50 nonprofits
        if i % 50 == 0 or i == total - 1:
            print(f"   Progress: {i+1}/{total} ({(i+1)/total*100:.1f}%)")
        
        text_parts = []
        
        # Add name with high weight
        if np['name']:
            text_parts.append(f"Organization: {np['name']}")
        
        # Add mission and services (most important)
        if np['mission_vision_services']:
            # Extract mission, vision, and services sections
            mission_text = np['mission_vision_services']
            
            # Look for specific sections
            mission_match = re.search(r'Mission:\s*(.*?)(?=Vision:|Services:|$)', mission_text, re.IGNORECASE | re.DOTALL)
            vision_match = re.search(r'Vision:\s*(.*?)(?=Services:|$)', mission_text, re.IGNORECASE | re.DOTALL)
            services_match = re.search(r'Services:\s*(.*?)(?=Vision:|$)', mission_text, re.IGNORECASE | re.DOTALL)
            
            if mission_match:
                text_parts.append(f"Mission: {clean_text(mission_match.group(1))}")
            if vision_match:
                text_parts.append(f"Vision: {clean_text(vision_match.group(1))}")
            if services_match:
                text_parts.append(f"Services: {clean_text(services_match.group(1))}")
            
            # If no specific sections found, use the whole text
            if not any([mission_match, vision_match, services_match]):
                text_parts.append(f"Description: {mission_text}")
        
        # Add causes with high weight
        if np['causes']:
            # Split causes and clean them
            causes = [cause.strip() for cause in np['causes'].split(',') if cause.strip()]
            if causes:
                text_parts.append(f"Causes: {', '.join(causes)}")
        
        # Add location information
        location_parts = []
        if np['city']:
            location_parts.append(np['city'])
        if np['state']:
            location_parts.append(np['state'])
        if location_parts:
            text_parts.append(f"Location: {', '.join(location_parts)}")
        
        # Add address if available
        if np['address']:
            text_parts.append(f"Address: {np['address']}")
        
        # Combine all parts
        text = ' '.join(text_parts)
        
        # Truncate if too long (BGE has a token limit of 512)
        if len(text) > 2000:
            text = text[:2000] + "..."
        
        texts.append(text)
    
    return texts

def generate_bge_embeddings(texts, model_name='BAAI/bge-large-en-v1.5'):
    """Generate BGE sentence embeddings"""
    print(f"🔄 Loading BGE model: {model_name}")
    print("   This may take a few minutes on first run...")
    model = SentenceTransformer(model_name)
    print("   ✅ Model loaded successfully!")
    
    print(f"\n🔄 Generating BGE embeddings for {len(texts)} nonprofits...")
    print("   This is the most time-consuming step - please be patient!")
    print("   Progress bar will show below:")
    
    embeddings = model.encode(texts, show_progress_bar=True, batch_size=16)  # Smaller batch size for BGE
    
    print(f"\n✅ Generated embeddings successfully!")
    print(f"   Shape: {embeddings.shape}")
    print(f"   Dimension: {embeddings.shape[1]}")
    
    return embeddings, model

def save_enhanced_bge_matrix(matrix_data, nonprofits_data, output_path, model):
    """Save the enhanced BGE matrix to JSON file"""
    matrix = {
        'model': 'BAAI/bge-large-en-v1.5-enhanced',
        'dimension': int(matrix_data.shape[1]),
        'nonprofits_count': len(nonprofits_data),
        'model_info': {
            'name': str(model),
            'max_seq_length': model.max_seq_length,
            'embedding_dimension': matrix_data.shape[1],
            'enhanced_processing': True,
            'model_type': 'BGE Large English v1.5 Enhanced'
        },
        'nonprofits': []
    }
    
    for i, np in enumerate(nonprofits_data):
        nonprofit_entry = {
            'id': np['id'],
            'name': np['name'],
            'causes': np['causes'],
            'state': np['state'],
            'city': np['city'],
            'address': np['address'],
            'phone': np['phone'],
            'email': np['email'],
            'website': np['website'],
            'hours': np['hours'],
            'ein': np['ein'],
            'url': np['url'],
            'embedding': [float(x) for x in matrix_data[i].tolist()]
        }
        matrix['nonprofits'].append(nonprofit_entry)
    
    matrix['generated_at'] = datetime.now().isoformat()
    matrix['data_source'] = 'giving_connection_scraped_data.csv'
    
    # Ensure output directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Save to JSON file
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(matrix, f, indent=2, ensure_ascii=False)
    
    print(f"Enhanced BGE matrix saved to: {output_path}")
    print(f"Matrix contains {matrix['nonprofits_count']} nonprofits with {matrix['dimension']}-dimensional embeddings")

def analyze_data_quality(nonprofits_data):
    """Analyze the quality of the data"""
    print("\n=== Data Quality Analysis ===")
    
    total = len(nonprofits_data)
    print(f"Total nonprofits: {total}")
    
    # Count nonprofits with different data
    with_mission = sum(1 for np in nonprofits_data if np['mission_vision_services'])
    with_causes = sum(1 for np in nonprofits_data if np['causes'])
    with_location = sum(1 for np in nonprofits_data if np['city'] and np['state'])
    
    print(f"With mission/vision/services: {with_mission} ({with_mission/total*100:.1f}%)")
    print(f"With causes: {with_causes} ({with_causes/total*100:.1f}%)")
    print(f"With location: {with_location} ({with_location/total*100:.1f}%)")
    
    # Analyze causes distribution
    all_causes = []
    for np in nonprofits_data:
        if np['causes']:
            causes = [cause.strip() for cause in np['causes'].split(',')]
            all_causes.extend(causes)
    
    from collections import Counter
    cause_counts = Counter(all_causes)
    print(f"\nTop 10 causes:")
    for cause, count in cause_counts.most_common(10):
        print(f"  {cause}: {count}")
    
    # Analyze state distribution
    state_counts = Counter([np['state'] for np in nonprofits_data if np['state']])
    print(f"\nTop 10 states:")
    for state, count in state_counts.most_common(10):
        print(f"  {state}: {count}")

def main():
    """Main function to generate enhanced BGE matrix"""
    start_time = datetime.now()
    print("🚀 === Enhanced BGE Matrix Generation ===")
    print(f"   Started at: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print("   This will create a new matrix with BGE embeddings for all 928 nonprofits")
    print("   Estimated time: 10-20 minutes depending on your system")
    print()
    
    # Set up paths
    script_dir = Path(__file__).parent
    data_dir = script_dir.parent / "data"
    csv_path = data_dir / "giving_connection_scraped_data.csv"
    output_path = data_dir / "enhanced_bge_nonprofits_matrix.json"
    
    print(f"📁 CSV source: {csv_path}")
    print(f"💾 Output: {output_path}")
    print()
    
    # Check if CSV file exists
    if not csv_path.exists():
        print(f"❌ Error: CSV file not found at {csv_path}")
        sys.exit(1)
    
    # Load data
    print("📊 Loading nonprofits data from CSV...")
    nonprofits_data = load_csv_data(csv_path)
    print(f"   ✅ Loaded {len(nonprofits_data)} nonprofits")
    
    # Analyze data quality
    analyze_data_quality(nonprofits_data)
    
    # Create text representations
    print("\n📝 Creating enhanced text representations...")
    texts = create_enhanced_text_representations(nonprofits_data)
    print(f"   ✅ Created {len(texts)} text representations")
    
    # Show sample text
    print("\n📄 Sample text representation:")
    sample_text = texts[0][:200] + "..." if len(texts[0]) > 200 else texts[0]
    print(f"   {sample_text}")
    
    # Generate embeddings
    print("\n" + "="*60)
    print("🤖 STARTING BGE EMBEDDING GENERATION")
    print("="*60)
    embeddings, model = generate_bge_embeddings(texts)
    
    # Save matrix
    print("\n💾 Saving enhanced BGE matrix...")
    save_enhanced_bge_matrix(embeddings, nonprofits_data, output_path, model)
    
    print("\n" + "="*60)
    print("🎉 === GENERATION COMPLETE ===")
    print("="*60)
    print(f"✅ Enhanced BGE matrix saved with {len(nonprofits_data)} nonprofits")
    print(f"✅ Embedding dimension: {embeddings.shape[1]}")
    print(f"✅ Model used: BAAI/bge-large-en-v1.5")
    print(f"✅ File saved to: {output_path}")
    print("\n🚀 You can now use this matrix for better matching results!")

if __name__ == "__main__":
    main()
