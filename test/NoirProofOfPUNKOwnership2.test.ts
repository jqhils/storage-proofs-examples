import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { UltraPlonkBackend } from '@aztec/bb.js';

const fs = require("fs");
let toml = require("toml");

describe("NoirProofOfPUNKOwnership2", () => {
    describe("deployment", () => {
        it("should deploy the contract", async () => {
            const contractFactory = await ethers.getContractFactory("NoirProofOfPUNKOwnership2");
            const contract = await contractFactory.deploy();
            await contract.waitForDeployment();
        });
    });

    describe("proving and verifying native balance on-chain", () => {
        it("proves and verifies native balance on-chain", async () => {
        // Deploy a verifier contract
        const contractFactory = await ethers.getContractFactory("NoirProofOfPUNKOwnership2");
        const contract = await contractFactory.deploy();
        await contract.waitForDeployment();

        // Generate a proof
        const { noir, backend } = await hre.noir.getCircuit("prove_hist_punk_ownership2", UltraPlonkBackend);
        // const { noir, backend } = await hre.noir.getCircuit("prove_hist_punk_ownership2");

        let witnessData = fs.readFileSync(`./test/inputs/TestNoirProofOfPUNKOwnershipProver2.toml`);
        let input = toml.parse(witnessData);
        fs.writeFileSync('./test/inputs/prove-hist-punk-ownership-input-data2.json', JSON.stringify(input, null, 2));

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
        const block_hash = "0x96cfa0fb5e50b0a3f6cc76f3299cfbf48f17e8b41798d1394474e67ec8a97e9f";
        const nft_address = "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb";
        const owner_address = "0x0000000000000000000000000000000000000000";
        // const pub_hash = "0x38d790028ec95d65701930152769c3869fe2e19e1af0314a3bc769922386d2f5";
        const tx = await contract.verify(proof, publicInputs, block_hash, nft_address, owner_address);
        await tx.wait();

        // Check the result using the public isVerified variable
        const result = await contract.isVerified();
        expect(result).to.be.true;

        });
    });
});
