# Smart Match Recommendation System

A comprehensive nonprofit recommendation system that uses AI-powered semantic matching with BGE embeddings and deterministic filtering to connect users with relevant organizations based on their needs and preferences.

## 📁 Complete Smart Match File Structure

```
giving-connection/                      # Project root
├── app/
│   ├── controllers/
│   │   └── smart_match_controller.rb   # Main controller
│   ├── services/                       # Smart match services (standard Rails autoloading)
│   │   ├── comprehensive_recommendation_service.rb  # Main recommendation service
│   │   └── quiz_to_user_intent_converter.rb         # Quiz answer converter
│   ├── models/                         # Smart match models (standard Rails autoloading)
│   │   └── user_intent.rb              # User intent model
│   ├── javascript/controllers/
│   │   └── smart_match_controller.js   # Frontend controller
│   └── views/smart_match/              # Smart match module
│       ├── README.md                   # This documentation
│       ├── services/                   # Legacy services (backup copies)
│       │   ├── comprehensive_recommendation_service.rb  # Backup copy
│       │   └── quiz_to_user_intent_converter.rb         # Backup copy
│       ├── models/                     # Legacy models (backup copies)
│       │   └── user_intent.rb          # Backup copy
│       ├── assets/stylesheets/components/ # Smart match styles
│       │   └── _smart_match.scss       # Custom CSS
│       ├── views/                      # Main view templates
│       │   ├── index.html.slim         # Welcome/landing page
│       │   ├── quiz/                   # Quiz interface views
│       │   │   └── quiz.html.erb       # Main quiz interface
│       │   └── results/                # Results views
│       │       └── results.html.slim   # Results display page
│       ├── components/                 # Reusable UI components
│       │   ├── paths/                  # Quiz path components
│       │   │   ├── _service_seeker_path.html.slim
│       │   │   ├── _volunteer_path.html.slim
│       │   │   └── _donor_path.html.slim
│       │   └── shared/                 # Shared components (future use)
│       ├── assets/                     # Static assets
│       │   ├── images/                 # Smart match specific images
│       │   └── styles/                 # Smart match specific styles
│       ├── scripts/                    # Matrix generation and testing scripts
│       │   ├── generate_enhanced_bge_matrix.py # Generate comprehensive BGE matrix
│       │   ├── generate_user_embedding.py      # Generate user answer embeddings
│       │   ├── analyze_causes.py               # Analyze cause data from CSV
│       │   └── activate_env.sh                 # Activate Python environment
│       └── data/                       # Generated data files
│           ├── enhanced_bge_nonprofits_matrix.json # Primary matrix (928 nonprofits)
│           └── giving_connection_scraped_data.csv  # Source data (928 nonprofits)
├── config/
│   ├── matching_rules.yml              # Cause mappings, scoring weights, quiz configs
│   ├── routes.rb                       # Smart match routing configuration
│   └── city_centroids.yml              # Geographic data for location matching
├── spec/controllers/
│   └── smart_match_controller_spec.rb  # RSpec tests for smart match functionality
└── lib/tasks/                          # Development tools
    ├── smart_match_new.rake            # Current service testing tasks (working)
    ├── smart_match_debug.rake          # Debug tasks (may reference old services)
    └── test_smart_match_improvements.rake # Legacy testing tasks (may reference old services)
```

## 🎯 System Overview

The Smart Match system consists of three main user paths:

1. **Service Seeker Path** - For users seeking help from nonprofits (36 cause options)
2. **Volunteer Path** - For users wanting to volunteer their time (14 cause options)
3. **Donor Path** - For users wanting to donate to causes (14 cause options)

Each path has a customized questionnaire that collects relevant information to generate personalized recommendations using semantic similarity.

## 🤖 AI-Powered Semantic Matching

### How It Works

1. **Nonprofit Embeddings**: All 928 nonprofits are converted to semantic embeddings using the `BAAI/bge-large-en-v1.5` model (1024 dimensions)
2. **User Answer Processing**: User quiz answers are converted to natural language text representations
3. **Semantic Matching**: User text is converted to embeddings and compared with nonprofit embeddings using cosine similarity
4. **Deterministic Filtering**: Additional filtering based on location, causes, and user preferences
5. **Recommendation Ranking**: Nonprofits are ranked by combined similarity and filtering scores

### Matrix Generation

The system uses BGE (BAAI/bge-large-en-v1.5) to generate embeddings for nonprofits based on:
- Organization name
- Mission and vision statements
- Services offered
- Causes supported (with comprehensive mapping)
- Geographic location
- Full address information

### Prerequisites

1. Create and activate the Python virtual environment:
   ```bash
   conda create -n bge_env python=3.11
   conda activate bge_env
   pip install sentence-transformers torch torchvision torchaudio
   ```

2. Ensure the CSV file `giving_connection_scraped_data.csv` is in the smart_match/data folder.

### Generating the Matrix

**Python Script:**
```bash
cd app/views/smart_match/scripts
conda run -n bge_env python generate_enhanced_bge_matrix.py
```

**Expected Output:**
```
🚀 Starting Enhanced BGE Matrix Generation...
📊 Loading CSV data: 928 nonprofits found
🔧 Creating enhanced text representations...
🤖 Loading BGE model: BAAI/bge-large-en-v1.5
📈 Generating embeddings: 100% complete
💾 Saving matrix: enhanced_bge_nonprofits_matrix.json
✅ Matrix generation complete! (928 nonprofits, 1024 dimensions)
```

### Testing the Recommendation System

**Rake Task:**
```bash
rails smart_match_new:test_service         # Test comprehensive service
rails smart_match_debug:debug_food_assistance  # Debug specific scenarios
```

## 📊 Data Structure

### Input CSV Format

The CSV file contains these fields:
- `url`: Organization URL (used as ID)
- `name`: Organization name
- `mission_vision_services`: Organization description and services
- `causes`: Causes supported (comma-separated)
- `city`: Geographic location
- `state`: Geographic location
- `address`: Full address

### Output Matrix Format

```json
{
  "model": "BAAI/bge-large-en-v1.5",
  "dimension": 1024,
  "nonprofits_count": 928,
  "model_info": {
    "name": "BGE-Large-EN",
    "max_seq_length": 512,
    "embedding_dimension": 1024
  },
  "nonprofits": [
    {
      "id": "https://example.org",
      "name": "Example Nonprofit",
      "causes": "Education, Youth Development",
      "city": "Atlantic City",
      "state": "NJ",
      "lat": 39.3643,
      "lng": -74.4229,
      "embedding": [0.062, -0.015, 0.059, ...]
    }
  ],
  "generated_at": "2024-01-01T12:00:00Z"
}
```

## 🔧 Recommendation Service

The `ComprehensiveRecommendationService` class handles:

1. **User Intent Conversion**: Converts quiz answers to structured user intent
2. **Deterministic Filtering**: Filters nonprofits by location and causes
3. **BGE Embedding Generation**: Uses Python script to generate semantic embeddings
4. **Similarity Calculation**: Computes cosine similarity with filtered nonprofits
5. **Scoring & Ranking**: Combines similarity scores with deterministic filtering scores

### Usage

```ruby
# In your controller
converter = QuizToUserIntentConverter.new(user_answers, user_intent)
user_intent_obj = converter.convert
recommendation_service = ComprehensiveRecommendationService.new(user_intent_obj)
recommendations = recommendation_service.generate_recommendations(10)

# Returns array of hashes with:
# - id: nonprofit URL
# - name: nonprofit name
# - score: 0.0-1.0 combined score
# - relevance_reason: human-readable explanation with all causes served
```

## 🎯 Matchmaking Algorithm: Complete Breakdown

### **🔄 The 6-Step Matchmaking Process**

#### **Step 1: User Intent Validation**
```ruby
# From comprehensive_recommendation_service.rb
def generate_recommendations(limit = 10)
  # Step 1: Basic validation
  return [] unless @user_intent.respond_to?(:causes_selected) && @user_intent.causes_selected.any?
```

**What it does:**
- Validates that user intent has required fields (state, city, travel_bucket, user_type, causes)
- Ensures data quality before proceeding

#### **Step 2: Deterministic Filtering**
```ruby
# Step 2: Apply deterministic filters
candidates = apply_deterministic_filters
```

**What it does:**
1. **State Filter**: Only nonprofits in user's state (NJ, CA, TN)
2. **Distance Filter**: Based on travel preference:
   - Walk: 5 miles radius
   - Transit: 10 miles radius  
   - Car: 50 miles radius
3. **Progressive Radius Expansion**: If no results, expands radius gradually

#### **Step 3: Query Text Building**
```ruby
# Step 3: Build query text for BGE
query_text = build_query_text
```

**What it does:**
- Converts user preferences to natural language text
- Includes cause synonyms, language preferences, accessibility needs
- Example: `"education learning school academic educational programs literacy training educational services learning support; spanish; wheelchair accessible; Atlantic City NJ"`

#### **Step 4: Embedding Generation**
```ruby
# Step 4: Generate query embedding
query_embedding = generate_query_embedding(query_text)
```

**What it does:**
- Calls Python script to generate 1024-dimensional BGE embedding
- Uses `BAAI/bge-large-en-v1.5` model for superior semantic understanding

#### **Step 5: Multi-Factor Scoring**
```ruby
# Step 5: Calculate scores for all candidates
scored_candidates = calculate_scores(candidates, query_embedding)
```

**What it does:**
Calculates three scores for each nonprofit:

1. **Dense Similarity (70% weight)**:
   ```ruby
   def calculate_dense_similarity(candidate, query_embedding)
     # Cosine similarity between user query and nonprofit embedding
     # Plus content boost for detailed descriptions
     dot_product = candidate_emb.zip(query_embedding).sum { |a, b| a * b }
     magnitude_a = sqrt(candidate_emb.sum { |x| x**2 })
     magnitude_b = sqrt(query_embedding.sum { |x| x**2 })
     similarity = dot_product / (magnitude_a * magnitude_b)
     
     # Content boost for rich descriptions
     if candidate["mission_vision_services"]&.length.to_i > 500
       similarity += 0.10  # 10% boost for detailed descriptions
     elsif candidate["mission_vision_services"]&.length.to_i > 200
       similarity += 0.05  # 5% boost for moderate descriptions
     end
   ```

2. **Attribute Bonus (20% weight)**:
   ```ruby
   def calculate_attribute_bonus(candidate)
     bonus = 0.0
     @user_intent.prefs_selected.each do |pref|
       rule = @config["attributes"][@user_intent.user_type]&.[](pref)
       if rule && (field_value & rule["any_of"]).any?
         bonus += rule["weight"]  # 0.04-0.08 per match
       end
     end
   ```

3. **Distance Score (10% weight)**:
   ```ruby
   def calculate_distance_score(candidate)
     distance = haversine_distance(user_coords, nonprofit_coords)
     # Map to score: 2mi=1.0, 5mi=0.95, 10mi=0.90, 25mi=0.80, 50mi=0.70
   ```

#### **Step 6: Final Ranking**
```ruby
# Step 6: Sort and limit results
recommendations = scored_candidates
  .sort_by { |c| -c[:final_score] }
  .first(limit)
  .map { |c| build_recommendation(c) }
```

### **🎯 Scoring Formula**

```ruby
final_score = (0.70 × dense_similarity) + (0.20 × attribute_bonus) + (0.10 × distance_score)
```

### **📊 Configuration-Driven Matching**

The system uses `config/matching_rules.yml` for flexible configuration:

#### **Cause Mapping:**
```yaml
education:
  synonyms: ["education", "learning", "school", "academic", "educational programs", "literacy", "training", "educational services", "learning support"]

# CSV to Quiz Mapping - Maps actual causes from CSV data to quiz causes
csv_to_quiz_mapping:
  "Advocacy": "advocacy"
  "Human & Social Services": "human_services"
  "Children & Family Services": "youth"
  "Youth Development": "youth"
  "Health": "healthcare"
  "Education": "education"
  "Arts & Culture": "arts_culture"
  "Community & Economic Development": "community_development"
  "Housing & Homelessness": "housing"
  "Faith-Based": "faith_based"
  "Disability Services": "disability"
  "Hunger & Food Security": "food_assistance"
  "Philanthropy": "human_services"
  "Mental Health": "mental_health"
  "Sports & Recreation": "sports_recreation"
  "Clothing & Living Essentials": "clothing_essentials"
  "Drug & Alcohol Treatment": "substance_abuse"
  "Animals": "animal_welfare"
  "Environment": "environment"
  "Emergency & Safety": "crisis"
  "LGBTQ+": "lgbtqia"
  "Veteran & Military": "veterans"
  "Immigrant & Refugee": "immigrant_refugee"
  "Race & Ethnicity": "advocacy"
  "Inmate & Formerly Incarcerated": "legal_help"
  "Justice & Legal Services": "legal_help"
  "Disaster Relief & Preparedness": "disaster_relief"
  "Research & Public Policy": "advocacy"
  "Media & Broadcasting": "arts_culture"
  "Social Sciences": "education"
  "Science & Technology": "education"
```

#### **Attribute Rules:**
```yaml
seeker:
  lgbtqia: 
    field: "cause_tags"
    any_of: ["lgbtq_services", "lgbtq_affirming"]
    weight: 0.08
  wheelchair_access:
    field: "facilities"
    any_of: ["wheelchair_accessible"]
    weight: 0.07
```

### ** Real-World Example**

**User Input:**
- Location: Atlantic City, NJ
- Travel: Walking (5 mile radius)
- Cause: Education
- Preferences: Spanish language, wheelchair accessible
- User Type: Service seeker

**Matchmaking Process:**

1. **Filter**: 928 nonprofits → 196 nonprofits in NJ → 15 nonprofits within 5 miles of Atlantic City

2. **Query Text**: `"education learning school academic educational programs literacy training educational services learning support; spanish; wheelchair accessible; Atlantic City NJ"`

3. **Scoring Example**:
   ```
   Nonprofit A: Atlantic County Collaborative for Educational Equity
   - Dense Similarity: 0.85 (high semantic match)
   - Attribute Bonus: 0.15 (Spanish + wheelchair accessible)
   - Distance Score: 0.95 (2 miles away)
   - Final Score: (0.70×0.85) + (0.20×0.15) + (0.10×0.95) = 0.78
   
   Nonprofit B: Animal Shelter
   - Dense Similarity: 0.25 (low semantic match)
   - Attribute Bonus: 0.07 (wheelchair accessible only)
   - Distance Score: 0.90 (3 miles away)
   - Final Score: (0.70×0.25) + (0.20×0.07) + (0.10×0.90) = 0.28
   ```

4. **Result**: Atlantic County Collaborative for Educational Equity ranked #1 with 78% match

### ** Key Features**

1. **Embedding-First Approach**: 70% weight on semantic similarity using BGE embeddings
2. **Comprehensive Cause Mapping**: Maps all 35 unique causes from CSV to quiz categories
3. **Multi-cause support**: Handles nonprofits with multiple causes (61.9% of nonprofits)
4. **Configurable Weights**: Easy to adjust scoring without code changes
5. **Progressive Filtering**: Starts strict, expands if needed
6. **Fallback Mechanisms**: Text-based similarity for nonprofits without embeddings
7. **Explainable Results**: Clear reasoning showing all causes each nonprofit serves

## 🔄 Complete Workflow Files

### **User Journey Files:**

1. **Landing Page**: `app/views/smart_match/views/index.html.slim`
2. **Quiz Interface**: `app/views/smart_match/views/quiz/quiz.html.erb`
3. **Quiz Paths**: 
   - `app/views/smart_match/components/paths/_service_seeker_path.html.slim`
   - `app/views/smart_match/components/paths/_donor_path.html.slim`
   - `app/views/smart_match/components/paths/_volunteer_path.html.slim`
4. **JavaScript Controller**: `app/javascript/controllers/smart_match_controller.js`
5. **Rails Controller**: `app/controllers/smart_match_controller.rb`

### **Processing Files:**

6. **Quiz Converter**: `app/views/smart_match/services/quiz_to_user_intent_converter.rb`
7. **User Intent Model**: `app/views/smart_match/models/user_intent.rb`
8. **Main Service**: `app/views/smart_match/services/comprehensive_recommendation_service.rb`
9. **Python Embedding**: `app/views/smart_match/scripts/generate_user_embedding.py`

### **Configuration Files:**

10. **Matching Rules**: `config/matching_rules.yml` - Cause mappings, scoring weights, and quiz configurations
11. **Routes**: `config/routes.rb` - Smart match routing configuration
12. **City Data**: `config/city_centroids.yml` - Geographic data for location matching

### **Data Files:**

13. **Enhanced BGE Matrix**: `app/views/smart_match/data/enhanced_bge_nonprofits_matrix.json` (28MB, 928 nonprofits)
14. **Source Data**: `app/views/smart_match/data/giving_connection_scraped_data.csv` (1.9MB, 928 nonprofits)

### **Results Files:**

15. **Results Display**: `app/views/smart_match/views/results/results.html.slim`

### **Styling Files:**

16. **Smart Match Styles**: `app/views/smart_match/assets/stylesheets/components/_smart_match.scss` - Custom CSS for smart match components

### **Testing Files:**

17. **Controller Tests**: `spec/controllers/smart_match_controller_spec.rb` - RSpec tests for smart match functionality

### **Development Tools:**

18. **New Service Tasks**: `lib/tasks/smart_match_new.rake` - Current service testing tasks (working)
19. **Debug Tasks**: `lib/tasks/smart_match_debug.rake` - Debug tasks (may reference old services)
20. **Test Tasks**: `lib/tasks/test_smart_match_improvements.rake` - Legacy testing tasks (may reference old services)

### **Data Flow:**

```
User Input → Quiz Interface → JavaScript → Rails Controller → 
Quiz Converter → UserIntent → Comprehensive Service → 
Python Script → BGE Embeddings → Similarity Calculation → 
Scoring & Ranking → Results Display
```

## 🔧 Development

### Adding New Components

1. **New Quiz Paths**: Add to `components/paths/`
2. **New Services**: Add to `app/services/`
3. **New Models**: Add to `app/models/`

### Environment Setup

```bash
# Activate environment
conda activate bge_env

# Or use the convenience script
./scripts/activate_env.sh
```

### Available Commands

```bash
# Matrix generation
conda run -n bge_env python scripts/generate_enhanced_bge_matrix.py

# System testing
rails smart_match_new:test_service
rails smart_match_new:test_csv_loading
rails smart_match_new:compare_services

# Cause analysis
conda run -n bge_env python scripts/analyze_causes.py
```

**Note**: Some rake tasks may reference old services that have been removed. The working tasks are listed above.

## 🚀 Performance

- **Enhanced BGE Matrix Generation**: ~15 minutes for 928 nonprofits
- **User Embedding**: ~0.2 seconds per user
- **Recommendation Generation**: ~0.3 seconds for filtered ranking
- **Memory Usage**: ~28MB for matrix storage
- **Accuracy**: Excellent semantic matching with 53-61% scores for relevant organizations

## 🐍 Environment Setup

### **Prerequisites**

Before setting up the Smart Match environment, ensure you have:

1. **Conda** installed on your system
2. **Git** for cloning the repository
3. **Rails** application running
4. **At least 5GB free disk space** (for models and dependencies)

### **Step 1: Create Conda Environment**

```bash
# Navigate to project root
cd /path/to/giving-connection

# Create conda environment
conda create -n bge_env python=3.11

# Activate the environment
conda activate bge_env

# Verify activation (should show bge_env in prompt)
conda info --envs
```

### **Step 2: Install Required Python Packages**

```bash
# Make sure environment is activated
conda activate bge_env

# Install core ML libraries
pip install torch torchvision torchaudio

# Install sentence transformers and utilities
pip install sentence-transformers

# Install data processing libraries
pip install numpy pandas scikit-learn

# Install additional utilities
pip install requests tqdm
```

### **Step 3: Verify Installation**

```bash
# Test Python environment
python -c "import torch; print(f'PyTorch version: {torch.__version__}')"
python -c "import sentence_transformers; print('Sentence Transformers installed')"
python -c "import numpy; print(f'NumPy version: {numpy.__version__}')"
```

### **Step 4: Test BGE Model Download**

```bash
# Navigate to scripts directory
cd app/views/smart_match/scripts

# Test model loading (this will download ~1.5GB model file)
python -c "
from sentence_transformers import SentenceTransformer
model = SentenceTransformer('BAAI/bge-large-en-v1.5')
print('BGE model loaded successfully!')
print(f'Model dimension: {model.get_sentence_embedding_dimension()}')
"
```

**Expected output:**
```
BGE model loaded successfully!
Model dimension: 1024
```

### **Environment Troubleshooting**

#### **Common Issues:**

1. **"conda: command not found"**
   ```bash
   # Install conda first
   # Download from: https://docs.conda.io/en/latest/miniconda.html
   ```

2. **"Module not found" errors**
   ```bash
   # Reinstall packages
   conda activate bge_env
   pip install --force-reinstall sentence-transformers torch
   ```

3. **Out of memory errors**
   ```bash
   # Reduce batch size in scripts
   # Edit: batch_size=32 -> batch_size=16
   ```

4. **Model download fails**
   ```bash
   # Manual download
   python -c "
   from sentence_transformers import SentenceTransformer
   import os
   os.environ['HF_HOME'] = '/path/to/custom/cache'
   model = SentenceTransformer('BAAI/bge-large-en-v1.5')
   "
   ```

### **Environment Structure**

```
bge_env/
├── bin/                    # Python executables
├── lib/                    # Python libraries
│   └── python3.11/
│       └── site-packages/  # Installed packages
├── include/               # Header files
├── share/                 # Shared data
└── conda-meta/           # Conda metadata
```

### **Model Cache Location**

The BGE model (~1.5GB) is cached in:
- **macOS**: `~/.cache/torch/sentence_transformers/`
- **Linux**: `~/.cache/torch/sentence_transformers/`
- **Windows**: `C:\Users\<username>\.cache\torch\sentence_transformers\`

### **Performance Optimization**

#### **GPU Acceleration (Optional):**
```bash
# Install CUDA version of PyTorch (if you have NVIDIA GPU)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
```

#### **Memory Optimization:**
```bash
# Set environment variables for better memory usage
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:128
export CUDA_LAUNCH_BLOCKING=1
```

### **Development Workflow**

1. **Activate environment before development:**
   ```bash
   conda activate bge_env
   ```

2. **Test changes:**
   ```bash
   # Test matrix generation
   conda run -n bge_env python scripts/generate_enhanced_bge_matrix.py
   
   # Test recommendation service
   rails smart_match_new:test_service
   ```

3. **Deactivate when done:**
   ```bash
   conda deactivate
   ```

### **Production Deployment**

For production deployment, ensure:
- Conda environment is properly set up on the server
- Model files are pre-downloaded
- Sufficient memory allocation (at least 4GB RAM)
- GPU acceleration if available

## 🔒 Privacy & Legal

- User quiz answers are processed locally
- No personal data is stored permanently
- Embeddings are generated on-demand
- All data handling follows privacy best practices

## 📈 Future Enhancements

1. **Real-time Learning**: Update embeddings based on user feedback
2. **Multi-modal Matching**: Include images and other media
3. **Personalization**: Learn from user interaction patterns
4. **Demographics Data Collection**: Store user's demographics and engagement information for nonprofits access
5. **Feedback Loop & Metrics**: Collect and track users' engagement in the platform using defined metrics 