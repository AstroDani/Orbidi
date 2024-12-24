#!/bin/bash

echo "Enter the environment (development or production):"
read environment

if [ "$environment" = "development" ] || [ "$environment" = "production" ]; then
    file_path="env/${environment}/backend.conf"
    echo "The configuration file path is: $file_path"
    if [ -f "$file_path" ]; then
        echo "Deploying environment"
        terraform init --backend-config="$file_path" --reconfigure --upgrade || { echo "Terraform init failed"; exit 1; }
        terraform plan --out="plan.tfplan" --var-file="env/$environment/vars.tfvars" || { echo "Terraform plan failed"; exit 1; }
        terraform apply plan.tfplan || { echo "Terraform apply failed"; exit 1; }
        rm -f plan.tfplan
    else
        echo "The file does not exist at: $file_path"
    fi
else
    echo "Invalid input. Please enter either 'development' or 'production'."
fi
