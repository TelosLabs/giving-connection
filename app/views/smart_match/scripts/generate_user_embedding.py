#!/opt/anaconda3/envs/bge_env/bin/python
"""
Generate embeddings for user quiz answers using sentence transformers
Supports multiple models for better accuracy
"""

import sys
import json
from sentence_transformers import SentenceTransformer

# Model options ranked by accuracy (best first)
MODEL_OPTIONS = {
    'BAAI/bge-large-en-v1.5': {
        'description': 'BGE Large English v1.5 - best accuracy for semantic similarity',
        'dimension': 1024,
        'performance': 'excellent',
        'recommended': True
    },
    'all-mpnet-base-v2': {
        'description': 'MPNet base model - good accuracy, slower',
        'dimension': 768,
        'performance': 'very_good'
    },
    'all-MiniLM-L12-v2': {
        'description': 'MiniLM large - moderate accuracy, moderate speed',
        'dimension': 384,
        'performance': 'good'
    },
    'all-MiniLM-L6-v2': {
        'description': 'MiniLM small - current model, fast but less accurate',
        'dimension': 384,
        'performance': 'fair'
    }
}

def generate_user_embedding(user_text, model_name='BAAI/bge-large-en-v1.5'):
    """Generate embedding for user text using sentence transformers"""
    try:
        # Load the model
        # print(f"Loading model: {model_name}")  # Commented out to prevent interference with JSON output
        model = SentenceTransformer(model_name)
        
        # For BGE models, we need to add a prefix for better performance
        if 'bge' in model_name.lower():
            # BGE models work better with a prefix
            prefixed_text = f"Represent this sentence for searching relevant passages: {user_text}"
        else:
            prefixed_text = user_text
        
        # Generate embedding
        embedding = model.encode([prefixed_text], show_progress_bar=False)
        
        # Return as list
        return embedding[0].tolist()
        
    except Exception as e:
        print(f"Error generating embedding: {e}", file=sys.stderr)
        return None

def test_model_performance(model_name='BAAI/bge-large-en-v1.5'):
    """Test model performance with sample nonprofit matching"""
    try:
        model = SentenceTransformer(model_name)
        
        # Test cases for nonprofit matching
        test_cases = [
            {
                "user": "food assistance hunger relief meal programs",
                "nonprofit": "Community Food Bank providing food assistance and meal programs",
                "expected_similarity": "high"
            },
            {
                "user": "mental health counseling therapy",
                "nonprofit": "Mental Health Center offering counseling and therapy services",
                "expected_similarity": "high"
            },
            {
                "user": "veteran military support",
                "nonprofit": "Veterans Services Organization supporting military families",
                "expected_similarity": "high"
            },
            {
                "user": "food assistance hunger relief",
                "nonprofit": "Animal Shelter providing pet adoption services",
                "expected_similarity": "low"
            },
            {
                "user": "lgbtqia support gender identity",
                "nonprofit": "LGBTQ+ Community Center providing support and resources",
                "expected_similarity": "high"
            },
            {
                "user": "housing shelter homeless assistance",
                "nonprofit": "Homeless Shelter providing emergency housing and support",
                "expected_similarity": "high"
            }
        ]
        
        print(f"\nTesting model: {model_name}")
        print("=" * 50)
        
        total_similarity = 0
        high_similarity_count = 0
        low_similarity_count = 0
        
        for i, test_case in enumerate(test_cases, 1):
            # Prepare text with BGE prefix if needed
            if 'bge' in model_name.lower():
                user_text = f"Represent this sentence for searching relevant passages: {test_case['user']}"
                nonprofit_text = f"Represent this sentence for searching relevant passages: {test_case['nonprofit']}"
            else:
                user_text = test_case["user"]
                nonprofit_text = test_case["nonprofit"]
            
            user_emb = model.encode([user_text])
            nonprofit_emb = model.encode([nonprofit_text])
            
            # Calculate cosine similarity
            from sklearn.metrics.pairwise import cosine_similarity
            similarity = cosine_similarity(user_emb, nonprofit_emb)[0][0]
            
            total_similarity += similarity
            
            if test_case['expected_similarity'] == 'high':
                high_similarity_count += 1
                if similarity > 0.5:
                    print(f"Test {i}: ✅ HIGH similarity expected - Got {similarity:.4f}")
                else:
                    print(f"Test {i}: ❌ HIGH similarity expected - Got {similarity:.4f} (too low)")
            else:
                low_similarity_count += 1
                if similarity < 0.3:
                    print(f"Test {i}: ✅ LOW similarity expected - Got {similarity:.4f}")
                else:
                    print(f"Test {i}: ❌ LOW similarity expected - Got {similarity:.4f} (too high)")
            
            print(f"  User: {test_case['user']}")
            print(f"  Nonprofit: {test_case['nonprofit']}")
            print()
        
        avg_similarity = total_similarity / len(test_cases)
        print(f"Average similarity: {avg_similarity:.4f}")
        print(f"High similarity tests: {high_similarity_count}")
        print(f"Low similarity tests: {low_similarity_count}")
        
        return True
        
    except Exception as e:
        print(f"Error testing model: {e}", file=sys.stderr)
        return False

def compare_models():
    """Compare performance of different models"""
    print("Comparing model performance for nonprofit matching...")
    print("=" * 60)
    
    for model_name, model_info in MODEL_OPTIONS.items():
        print(f"\nModel: {model_name}")
        print(f"Description: {model_info['description']}")
        print(f"Dimension: {model_info['dimension']}")
        print(f"Performance: {model_info['performance']}")
        if model_info.get('recommended'):
            print("⭐ RECOMMENDED MODEL")
        
        success = test_model_performance(model_name)
        if not success:
            print("  ❌ Model test failed")
        else:
            print("  ✅ Model test completed")
        
        print("-" * 40)

def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python generate_user_embedding.py <user_text> [model_name]")
        print("  python generate_user_embedding.py compare")
        print("  python generate_user_embedding.py test [model_name]")
        print("\nAvailable models:")
        for model_name, model_info in MODEL_OPTIONS.items():
            recommended = " ⭐" if model_info.get('recommended') else ""
            print(f"  {model_name}: {model_info['description']}{recommended}")
        sys.exit(1)
    
    if sys.argv[1] == "compare":
        compare_models()
        return
    
    if sys.argv[1] == "test":
        model_name = sys.argv[2] if len(sys.argv) > 2 else 'BAAI/bge-large-en-v1.5'
        test_model_performance(model_name)
        return
    
    user_text = sys.argv[1]
    model_name = sys.argv[2] if len(sys.argv) > 2 else 'BAAI/bge-large-en-v1.5'
    
    # Generate embedding
    embedding = generate_user_embedding(user_text, model_name)
    
    if embedding:
        # Output as JSON
        result = {
            "text": user_text,
            "embedding": embedding,
            "dimension": len(embedding),
            "model": model_name
        }
        print(json.dumps(result))
    else:
        sys.exit(1)

if __name__ == "__main__":
    main() 