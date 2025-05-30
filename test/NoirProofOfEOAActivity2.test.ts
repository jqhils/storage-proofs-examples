import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { UltraPlonkBackend } from '@aztec/bb.js';

const fs = require("fs");
let toml = require("toml");

describe("NoirProofOfEOAActivity2", () => {
    describe("deployment", () => {
        it("should deploy the contract", async () => {
            const contractFactory = await ethers.getContractFactory("NoirProofOfEOAActivity2");
            const contract = await contractFactory.deploy();
            await contract.waitForDeployment();
        });
    });

    describe("proving and verifying EOA activity on-chain", () => {
        it("proves and verifies EOA activity on-chain", async () => {
        // Deploy a verifier contract
        const contractFactory = await ethers.getContractFactory("NoirProofOfEOAActivity2");
        const contract = await contractFactory.deploy();
        await contract.waitForDeployment();

        // Generate a proof
        const { noir, backend } = await hre.noir.getCircuit("prove_eoa_activity2", UltraPlonkBackend);
        // const { noir, backend } = await hre.noir.getCircuit("prove_eoa_activity");

        let witnessData = fs.readFileSync(`./test/inputs/TestNoirProofOfEOAActivityProver2.toml`);
        let input = toml.parse(witnessData);
        fs.writeFileSync('./test/inputs/prove-eoa-activity-input-data.json', JSON.stringify(input, null, 2));

        // Start timing
        const start = Date.now();

        const { witness } = await noir.execute(input);

        // const { proof, publicInputs } = await backend.generateProof(witness, {
        // keccak: true,
        // });

        const { proof, publicInputs } = await backend.generateProof(witness);
        console.log(`publicInputs: ${publicInputs}`);

        // End timing and calculate duration
        const end = Date.now();
        const duration = end - start;

        console.log(`Proving step took ${duration} milliseconds`);

        // Execute transaction to verify proof (this will show in gas report)
        const block_hash_1 = "0x96cfa0fb5e50b0a3f6cc76f3299cfbf48f17e8b41798d1394474e67ec8a97e9f";
        const block_hash_2 = "0xbe0e9c09c8f627c32386216a8f800361e21b7367aa3a013cba330f05adf9a60f";
        const account_address = "0x0e27b2411e4D45AADAF18E5bE2bDc6ebE438DfC3";
        // const pub_hash = "0xca8803c187e34117e35d1be3906a2f55dcc2f383f52ab8f9cb35c009063fdcf1";
        const tx = await contract.verify(proof, publicInputs, block_hash_1, block_hash_2, account_address);
        await tx.wait();

        // Check the result using the public isVerified variable
        const result = await contract.isVerified();
        expect(result).to.be.true;
        });
    });
});
