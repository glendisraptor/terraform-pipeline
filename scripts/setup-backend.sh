#!/bin/bash

# Setup script for Terraform backend resources
set -e

BUCKET_NAME="your-terraform-state-bucket-sgdsygf43reygh"
TABLE_NAME="terraform-state-locks"
REGION="us-east-1"

echo "🚀 Setting up Terraform backend resources..."

# Create S3 bucket for state storage
echo "📦 Creating S3 bucket: $BUCKET_NAME"
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Enable versioning
echo "🔄 Enabling S3 bucket versioning..."
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# Enable encryption
echo "🔐 Enabling S3 bucket encryption..."
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

# Block public access
echo "🛡️  Blocking public access..."
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table for state locking
echo "🔒 Creating DynamoDB table: $TABLE_NAME"
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION

echo "✅ Backend setup complete!"
echo "📝 Update your terraform backend configuration with:"
echo "   bucket = \"$BUCKET_NAME\""
echo "   dynamodb_table = \"$TABLE_NAME\""
echo "   region = \"$REGION\""