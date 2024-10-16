// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";
import { CropInsurance } from "../src/CropInsurance.sol";

contract CropInsuranceScript is Script {
    // Save address
    string internal configDir = string.concat(vm.projectRoot(), "/");
    string internal configFilePath = string.concat(configDir, "address.json");

    uint256 internal deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
    CropInsurance cropInsurance;
    address usdc = address(0x1);

    function run() public {
        vm.startBroadcast(deployerPrivateKey);
        cropInsurance = new CropInsurance(usdc);

        updateJson(".cropInsurance", address(cropInsurance));
    }

    function updateJson(string memory _key, address _address) internal {
        vm.writeJson(vm.toString(_address), configFilePath, _key);
    }
}
