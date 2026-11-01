# Cybersecurity-Azure-Lab
I'm building this lab to practice using Microsoft Azure, networking, playbooks, bicep, KQL, basic governance with policies and RBAC, etc.


When specifying the sshpubkey parameter for creating a vm I need the contents of the ssh file, do it like this so you don't have to copy the file contents and paste it manually into a command:
sshPubKey="$(cat ~/.ssh/azure_lab.pub)"

Full command example:
az deployment sub what-if --location uksouth --template-file infra/
main.bicep --parameters sshPubKey="$(cat ~/.ssh/azure_lab.pub)" adminUserName=opendrill