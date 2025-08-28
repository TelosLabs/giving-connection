from collections import defaultdict
from pytrends.request import TrendReq
import pandas as pd
import time
import random

def load_keywords(filepath):
    """
    Description: load keywords from a text file formatted with categories.

    The text file should have categories ending with a colon, followed by comma-separated keywords. Lines starting with '#' or blank lines are ignored.

    Example input (keywords.txt):
        Advocacy:
            advocacy, lobbying, grassroots organizing
        Agriculture:
            farming, crops, livestock  

    Parameters: 
        filepath (str): path to the keywords text file.

    Returns: 
        dict: a dictionary where keys are category names (str) and values are list of keywords (List[str]) under that category. 
    """
    categories = defaultdict(list)
    cur_category = None

    with open(filepath, 'r') as file:
        for line in file:
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            if line.endswith(':'):
                cur_category = line[:-1].strip()
            elif cur_category:  # Only add keywords if we have a current category
                keywords = [kw.strip() for kw in line.split(',') if kw.strip()]
                categories[cur_category].extend(keywords)
        
    return dict(categories)

def fetch_trends(keywords_dict, timeframe='today 1-m', geo='US', max_retries=3):
    """
    Description: Fetch Google Trends data for keywords in batches of 5 with improved rate limiting handling.
    
    Parameters:
        keywords_dict (dict): Dictionary of categories and keywords
        timeframe (str): Time period for trends data (default: past month)
        geo (str): Geographic location
        max_retries (int): Maximum number of retries for failed requests
    
    Returns:
        dict: Dictionary with keyword trends data
    """
    trends_data = {}
    
    # Create a single pytrends instance and reuse it
    pytrends = TrendReq(hl='en-US', tz=360, timeout=(10, 25))
    
    # Flatten all keywords into a single list with category info
    all_keywords = []
    for category, keywords in keywords_dict.items():
        for keyword in keywords:
            all_keywords.append((category, keyword))
    
    print(f"Processing {len(all_keywords)} keywords in batches of 5...")
    print(f"Total batches needed: {(len(all_keywords) + 4) // 5}")
    
    # Process keywords in batches of 5
    for batch_start in range(0, len(all_keywords), 5):
        batch = all_keywords[batch_start : batch_start + 5]
        batch_keywords = [keyword for _, keyword in batch]
        batch_number = batch_start // 5 + 1
        
        print(f"\nBatch {batch_number}: {batch_keywords}")
        
        success = False
        retries = 0
        
        while not success and retries < max_retries:
            try:
                # Add delay between batches to avoid rate limiting
                if batch_start > 0:  # Don't delay on first batch
                    delay = random.uniform(3, 6)  # 3-6 seconds between batches
                    print(f"  Waiting {delay:.1f} seconds before processing batch...")
                    time.sleep(delay)
                
                # Build payload for batch of keywords (max 5)
                pytrends.build_payload(batch_keywords, cat=0, timeframe=timeframe, geo=geo, gprop='')
                data = pytrends.interest_over_time()
                
                if not data.empty:
                    # Remove isPartial column if it exists
                    if 'isPartial' in data.columns:
                        data = data.drop(columns=['isPartial'])
                    
                    # Store each keyword's data with category prefix
                    successful_keywords = []
                    for category, keyword in batch:
                        if keyword in data.columns:
                            key = f"{category}_{keyword}" if len(keywords_dict) > 1 else keyword
                            trends_data[key] = data[keyword]
                            successful_keywords.append(keyword)
                    
                    print(f"  ✓ Successfully fetched data for {len(successful_keywords)} keywords: {successful_keywords}")
                else:
                    print(f"  ⚠ No data available for batch: {batch_keywords}")
                
                success = True
                
            except Exception as e:
                retries += 1
                error_msg = str(e).lower()
                
                if '429' in error_msg or 'rate limit' in error_msg:
                    wait_time = min(60 * (2 ** retries), 300)  # Exponential backoff, max 5 minutes
                    print(f"  Rate limit hit for batch {batch_number}. Waiting {wait_time} seconds... (Retry {retries}/{max_retries})")
                    time.sleep(wait_time)
                elif '400' in error_msg:
                    print(f"  Bad request for batch {batch_number}: {e}")
                    break  # Don't retry for bad requests
                else:
                    wait_time = 30 * retries
                    print(f"  Error fetching batch {batch_number}: {e}")
                    print(f"  Waiting {wait_time} seconds before retry...")
                    time.sleep(wait_time)
        
        if not success:
            print(f"  Failed to fetch batch {batch_number} after {max_retries} retries")
    
    print(f"\nFetched trends for {len(trends_data)} keywords successfully.")
    return trends_data

def save_trends_data(trends_data, output_file='trends_data.csv'):
    """
    Description: Save trends data to CSV file.
    
    Parameters:
        trends_data (dict): Dictionary of trends data
        output_file (str): Output CSV filename
    """
    if not trends_data:
        print("No data to save.")
        return
    
    # Combine all series into a DataFrame
    df = pd.DataFrame(trends_data)
    df.to_csv(output_file)
    print(f"Trends data saved to {output_file}")

if __name__ == "__main__":
    try:
        keywords_dict = load_keywords('lib/data/keywords.txt')
        print(f"Loaded {len(keywords_dict)} categories:")
        for category, keywords in keywords_dict.items():
            print(f"  {category}: {len(keywords)} keywords")
        
        # Fetch trends for past month only with batch processing
        trends_data = fetch_trends(keywords_dict, timeframe='today 1-m')
        
        if trends_data:
            save_trends_data(trends_data)
        else:
            print("No trends data was successfully fetched.")
            
    except FileNotFoundError:
        print("Error: Could not find 'lib/data/keywords.txt'. Please check the file path.")
    except Exception as e:
        print(f"Error: {e}")