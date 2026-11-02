az deployment sub What-if will error since one of the canary-vm params takes the value of a previously deployed subnetId which doesn't exist yet! Will work when actually created.

When specifying the sshpubkey parameter for creating a vm I need the contents of the ssh file, I do it like this so I don't have to copy the file contents and paste it manually into a command:
sshPubKey="$(cat ~/.ssh/azure_lab.pub)"

Full command example for deploying:
az deployment sub create --location uksouth --template-file infra/
main.bicep --parameters sshPubKey="$(cat ~/.ssh/azure_lab.pub)" adminUserName=
