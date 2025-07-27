module "Lambda_function" {
    source                 = "terraform-aws-modules/Lambda/aws"
    version                = "7.20.1"
    function_name          = var.function_name
    handler                = var.handler
    runtime                = var.runtime
    environment_variables  = var.environment_variables
    source_path            = var.source_path
    memory_size            = var.Lambda_memory_size
    layers                 = var.lambda_layers
    publish                = var.publish
    create_role            = true
    timeout                = var.Lambda_function_timeout
    role_name              = "Lambda_${var.function_name}"
    trusted_entities       = var.trusted_entities
    attach_policy_json     = var.attach_policy_json
    policy_json            = var.lambda_policy
    policy_path            = var.lambda_policy_path
    tags                   = var.tags
    attach_tracing_policy  = true
    # Enable X-Ray tracing
}