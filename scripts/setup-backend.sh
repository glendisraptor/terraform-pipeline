#!/bin/bash

set -e

BUCKET_NAME="terraform-state-bucket-345676654"
TABLE_NAME="terraform-state-locks"
REGION="af-south-1"

echo "🚀 Setting up Terraform backend resources..."

# Check if the bucket exists and is owned by you
bucket_exists=$(aws s3api head-bucket --bucket "$BUCKET_NAME" 2>&1 || true)

if echo "$bucket_exists" | grep -q '403'; then
    echo "❌ Bucket exists but is owned by someone else. Exiting."
    exit 1
elif echo "$bucket_exists" | grep -q '404'; then
    echo "📦 Bucket does not exist. Creating bucket: $BUCKET_NAME"
    if [ "$REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION
    else
        aws s3api create-bucket \
            --bucket $BUCKET_NAME \
            --region $REGION \
            --create-bucket-configuration LocationConstraint=$REGION
    fi
else
    echo "ℹ️ Bucket already exists and is owned by you."
    # Uncomment below to delete and recreate the bucket
    # echo "⚠️ Deleting existing bucket..."
    # aws s3 rb s3://$BUCKET_NAME --force
    # echo "🆕 Recreating bucket..."
    # (same create-bucket logic as above)
fi

# Enable versioning
echo "🔄 Enabling S3 bucket versioning..."
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled \
    --region $REGION

# Enable encryption
echo "🔐 Enabling S3 bucket encryption..."
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --region $REGION \
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
    --region $REGION \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create DynamoDB table for state locking
echo "🔒 Creating DynamoDB table: $TABLE_NAME"
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION || echo "ℹ️ DynamoDB table $TABLE_NAME already exists."

echo "✅ Backend setup complete!"
echo "📝 Update your terraform backend configuration with:"
echo "   bucket = \"$BUCKET_NAME\""
echo "   dynamodb_table = \"$TABLE_NAME\""
echo "   region = \"$REGION\""
