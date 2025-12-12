#!/bin/bash

mkdir -p /results

echo "Running OpenSCAP STIG scan..."
oscap xccdf eval \
    --profile xccdf_org.ssgproject.content_profile_stig \
    --results /results/openscap-results.xml \
    --report /results/openscap-report.html \
    $SSG_CONTENT

echo "Running GOSS tests..."
goss -g /etc/goss/goss.yaml validate --format json > /results/goss.json
goss -g /etc/goss/goss.yaml validate --format junit > /results/goss-junit.xml

echo "Running InSpec checks..."
inspec exec /inspec-profile \
    --reporter json:/results/inspec.json \
    --reporter junit:/results/inspec-junit.xml

echo "All scans completed."
