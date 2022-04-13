#!/usr/bin/env bash

CLOUDFRONT_DISTRIBUTION_ID=XXXXXXXXXXXXXXX

if [[ $1 == mpage ]]; then
	NEW_ORIGIN="s3-bucket-mpage-origin"
	echo "Cloudfront ORIGIN MPage - $NEW_ORIGIN"
elif [[ $1 == main ]]; then
	NEW_ORIGIN="s3-bucket-main-origin"
        echo "Cloudfront ORIGIN Main - $NEW_ORIGIN"
else 
  echo "Missing Your NEW_ORIGIN"
  exit 1
fi

ETAG=`aws cloudfront get-distribution --id $CLOUDFRONT_DISTRIBUTION_ID | jq -r .ETag`

aws cloudfront get-distribution --id $CLOUDFRONT_DISTRIBUTION_ID | \
jq --arg NEW_ORIGIN "$NEW_ORIGIN" '.Distribution.DistributionConfig.Origins.Items[0].Id=$NEW_ORIGIN' | \
jq --arg NEW_ORIGIN "$NEW_ORIGIN" '.Distribution.DistributionConfig.Origins.Items[0].DomainName=$NEW_ORIGIN' | \
jq --arg NEW_ORIGIN "$NEW_ORIGIN" '.Distribution.DistributionConfig.DefaultCacheBehavior.TargetOriginId=$NEW_ORIGIN' | \
jq .Distribution.DistributionConfig > config.json

echo "Update cloudfront distribution id $CLOUDFRONT_DISTRIBUTION_ID"
aws cloudfront update-distribution --id $CLOUDFRONT_DISTRIBUTION_ID --distribution-config "file://config.json" --if-match $ETAG > /dev/null

INVALIDATION_ID=`aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --paths "/*" | jq -r .Invalidation.Id`
echo "Waiting for invalidation $INVALIDATION_ID"

aws cloudfront wait invalidation-completed --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --id $INVALIDATION_ID 
echo "Invalidation $INVALIDATION_ID completed"
rm config.json
