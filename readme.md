**Pre-requisites**

1. A Service Principal with "contributor access on the subscription/resource group" where resource provisioning will take place
2. The service principal is connected to an Azure DevOps Organization via a  [ADO Service Connection](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml#create-a-service-connection)
3. A storage account to manage state
    - Hierarachy of state file in the storage account
        - StorageAccountName
          - -----ContainerName
          - ---------TF_FolderName
          - ------------StateFile --> terraform.tfstate

4. **Terraform configuration**
   - tfvars file has a prefix variable that can help trigger deployment of new resources in a new resource group
5. **Azure DevOps pipelines**
    - Pipeline :: TerraformPlan :: azure-pipelines.yml 
      - Terraform init: initialize TF configurations in an empty folder. 
      - Terraform validate: validate TF scripts and syntax. 
      - Publish the tf files and tfstate to AzurePipeline.
      Prepare for deploying azure resources
    - Pipeline :: Terraform Apply :: ISS_TF_Apply.yml 
        - Downloads the tf file and the tfstate artifact to the release pipeline.
        - Apply command has an auto approve switch
    - Code: Pipeline :: TerraformPlan :: azure-pipelines.yml
    
    ```
    
    ```
