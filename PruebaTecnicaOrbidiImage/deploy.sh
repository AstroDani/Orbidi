#!/bin/bash
file_path="env/backend.conf"
echo "The configuration file path is: $file_path"
if [ -f "$file_path" ]; then
    echo "Deploying project"
    terraform init --backend-config="$file_path" --upgrade --reconfigure || { echo "Terraform init failed"; exit 1; }
    terraform plan --out="plan.tfplan" || { echo "Terraform plan failed"; exit 1; }
    terraform apply plan.tfplan || { echo "Terraform apply failed"; exit 1; }
    rm -f plan.tfplan
else
    echo "The file does not exist at: $file_path"
fi
