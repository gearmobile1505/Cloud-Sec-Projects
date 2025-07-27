#!/bin/bash

set -e

LAYER_DIR="modules/vpc-flow-logs-lambda"
LAYER_ZIP="python-requests.zip"

echo "Creating Python requests layer..."

cd $LAYER_DIR

# Create layer structure
mkdir -p python/lib/python3.11/site-packages

# Install requests
pip install requests -t python/lib/python3.11/site-packages/

# Create zip file
zip -r $LAYER_ZIP python/

# Clean up
rm -rf python/

echo "Layer created: $LAYER_ZIP"
