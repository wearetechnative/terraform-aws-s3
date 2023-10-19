output "replication_target_arguments" {
  value = {
    source_role_arn = module.replication_role.role_arn
  }
}
