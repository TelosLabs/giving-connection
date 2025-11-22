#!/bin/bash
# Script to activate the smart_match virtual environment

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
ENV_PATH="$PROJECT_ROOT/smart_match_env"

echo "Activating smart_match virtual environment..."
echo "Environment path: $ENV_PATH"

if [ -d "$ENV_PATH" ]; then
    source "$ENV_PATH/bin/activate"
    echo "Virtual environment activated!"
    echo "You can now run: python scripts/generate_sentence_transformers_matrix.py"
else
    echo "Error: Virtual environment not found at $ENV_PATH"
    echo "Please create it first with: python3 -m venv smart_match_env"
    exit 1
fi 