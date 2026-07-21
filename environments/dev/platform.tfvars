# Platform Layer - Dev Environment

# --- EKS management cluster (runs ArgoCD + KRO + ACK) ---
cluster_version     = "1.36"
node_instance_types = ["m7i-flex.large"]
node_min_size       = 1
node_max_size       = 3
node_desired_size   = 2

# --- Platform repo (SHARED on purpose by the eks and cicd stacks) ---

platform_repo_name   = "platform-engineering-from-scratch"
platform_repo_branch = "main"

# Branch CodeBuild pushes rendered YAML to, and the root Application watches.
deploy_branch = "deploy"

# --- ECR (KCL modules published as OCI artifacts) ---
ecr_repository_name = "kcl-modules"

# --- CI toolchain ---
# Pin the KCL CLI the pipeline installs. 
kcl_version = "v0.12.7"

# --- ArgoCD identity ---
argocd_admin_idc_group = "platform-admins"

# IdC user to create and add to the admin group. 
#   export TF_VAR_argocd_admin_user='{"username":"...","email":"...","given_name":"...","family_name":"..."}'

