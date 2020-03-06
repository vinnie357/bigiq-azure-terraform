# management public ip

output "BIGIQ01_mgmt_public_ip" { value = "https://${module.bigiq.f5vm01_mgmt_public_ip}" }

output "buildName" {
  value = "${random_pet.buildSuffix.id}"
}