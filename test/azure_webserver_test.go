package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// You normally want to run this under a separate "Testing" subscription
// For lab purposes you will use your assigned subscription under the Cloud Dev/Ops program tenant
var subscriptionID string = "<Your Subscription ID>"

func TestAzureLinuxVMCreation(t *testing.T) {
	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: "../",
		// Override the default terraform variables
		Vars: map[string]interface{}{
			"labelPrefix": "onei0240",
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	// Run `terraform init` and `terraform apply`. Fail the test if there are any errors.
	terraform.InitAndApply(t, terraformOptions)


	// Run `terraform output` to get the value of output variable
	vmName := terraform.Output(t, terraformOptions, "vm_name")
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
	nicName := terraform.Output(t, terraformOptions, "nic_name")

	/* Split tests into Sub-tests that will have their own PASS/FAIL results */

	// Confirm VM exists
	t.Run("VMExists", func(t *testing.T) {
		assert.True(t, azure.VirtualMachineExists(t, vmName, resourceGroupName, subscriptionID))
	})
	
	// Confirm VM OS version
	t.Run("VMImageSKU", func(t *testing.T) {
		image := azure.GetVirtualMachineImage(t, vmName, resourceGroupName, subscriptionID)
		// confirm image
		assert.Equal(t, "22_04-lts", image.SKU)
	})

	// Check if NIC exists
	t.Run("NICExists", func(t *testing.T) {
		assert.True(t, azure.NetworkInterfaceExists(t, nicName, resourceGroupName, subscriptionID))
	})

	// Confirm NIC assosiation with VM
	t.Run("VMHasNICAssosiation", func(t *testing.T) {
		nicList := azure.GetVirtualMachineNics(t, vmName, resourceGroupName, subscriptionID)

		//expecting only 1 NIC
		assert.Equal(t, nicName, nicList[0])
	})
}

