"commandToExecute": "[concat('mkdir -p /var/log/cloud/azure; mkdir -p /config/cloud; echo ', variables('initScript'), ' | /usr/bin/base64 -d > /config/cloud/init.sh; chmod +x /config/cloud/init.sh;', ' /config/cloud/init.sh --cloud azure --log-level debug --data-interface eth1 --license ', parameters('bigIqLicenseKey1'), ' --ntp ', parameters('ntpServer'), ' --timezone ', parameters('timeZone'), ' --create-license-pool ', parameters('licensePoolKeys'), ' --create-reg-key-pool ', parameters('regPoolKeys'), ' --big-iq-password-data-uri file:///mnt/cloudTmp/.bigiq_pass --big-iq-password ', variables('adminPassword'), ' --big-iq-master-key ', parameters('masterKey'), ' --fcl-tag ', variables('f5CloudLibsTag'), ' --fcl-cloud-tag ', variables('f5CloudLibsAzureTag'), ' --vlan ', variables('singleQuote'), 'n:internal,nic:1.1', variables('singleQuote'), ' --self-ip ', variables('singleQuote'), 'n:internal_self,a:', variables('intSubnetPrivateAddress'), ',v:internal,i:eth1', variables('singleQuote'), ' --usage-analytics ', variables('singleQuote'), 'send:', parameters('allowUsageAnalytics'), ',r:', variables('location'), ',cI:', variables('subscriptionID'), ',dI:', variables('deploymentId'), ',cN:azure,lT:byol,bIV:6.0.0,tN:f5-existing-stack-byol-2nic-bigiq,tV:4.3.0', variables('singleQuote'), ' &>> /var/log/cloud/azure/install.log &')]"



mkdir -p /var/log/cloud/azure;
mkdir -p /config/cloud;
echo "$initScript | /usr/bin/base64 -d > /config/cloud/init.sh;
chmod +x /config/cloud/init.sh;
/config/cloud/init.sh --cloud azure --log-level debug --data-interface eth1 --license ${var.bigIqLicenseKey1} --ntp ${var.ntpServer} --timezone ${timeZone} \
--create-license-pool ${var.licensePoolKeys} --create-reg-key-pool ${var.regPoolKeys} --big-iq-password-data-uri file:///mnt/cloudTmp/.bigiq_pass --big-iq-password ${adminPassword} \
--big-iq-master-key ${var.masterKey} --fcl-tag ${var.f5CloudLibsTag} --fcl-cloud-tag ${var.f5CloudLibsAzureTag} \
--vlan 'n:internal,nic:1.1' --self-ip "n:internal_self,a:${var.intSubnetPrivateAddress} v:internal,i:eth1" \
--usage-analytics 'send:'${var.allowUsageAnalytics} r: ${var.location} cI:${var.subscriptionID} dI:${var.deploymentId} cN:azure,lT:byol,bIV:6.0.0,tN:f5-existing-stack-byol-2nic-bigiq,tV:4.3.0 &>> /var/log/cloud/azure/install.log"

${var.bigIqLicenseKey1}
${var.ntpServer}
${timeZone}
${var.licensePoolKeys}
${var.regPoolKeys}
${adminPassword}
${var.masterKey}
${var.f5CloudLibsTag}
${var.f5CloudLibsAzureTag}
${var.intSubnetPrivateAddress}
${var.allowUsageAnalytics}
${var.location}
${var.subscriptionID}
${var.deploymentId}


node /config/cloud/azure/node_modules/@f5devcentral/f5-cloud-libs/scripts/onboard.js --host localhost --log-level info --output "/config/cloud/azure/onboard.log" --signal ONBOARD_DONE --hostname bigiq-tf-f5vm01.eastus2.cloudapp.azure.com --help false --log-level debug --cloud azure --skip-verify true --license big-iq-key-key-key --ntp 0.us.pool.ntp.org --timezone UTC  --data-interface eth1 --usage-analytics false --vlan n:internal,nic:1.1 --self-ip n:internal_self,a:10.90.3.4,v:internal,i:eth1 --discovery-address 10.90.3.4 --create-license-pool pool-key-key-key --create-reg-key-pool key-key-key-key --fcl-tag v4.15.0 --fcl-cloud-tag v2.12.0  --master true  --big-iq-master-key Obfuscated  --big-iq-password-data-uri file:///mnt/cloudTmp/.bigiq_pass