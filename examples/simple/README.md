## Usage

1. Clone or copy the files in this path to a local directory and open a command prompt.
2. Amend `main.tf` with desired variables.
3. Log into azure using CLI "az login".
4. **BUILD:**

    ```hcl
    terraform init
    terraform plan -out deploy.tfplan
    terraform apply deploy.tfplan
    ```

5. **DESTROY:**

    ```hcl
    terraform plan -destroy -out destroy.tfplan
    terraform apply destroy.tfplan
    ```
