import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { UltraPlonkBackend } from '@aztec/bb.js';

const fs = require("fs");
let toml = require("toml");

describe("NoirProofOfEOAActivity", () => {
    describe("deployment", () => {
        it("should deploy the contract", async () => {
            const contractFactory = await ethers.getContractFactory("NoirProofOfEOAActivity");
            const contract = await contractFactory.deploy();
            await contract.waitForDeployment();
        });
    });

    describe("proving and verifying native balance on-chain", () => {
        it("proves and verifies native balance on-chain", async () => {
        // Deploy a verifier contract
        const contractFactory = await ethers.getContractFactory("NoirProofOfEOAActivity");
        const contract = await contractFactory.deploy();
        await contract.waitForDeployment();

        // Generate a proof
        const { noir, backend } = await hre.noir.getCircuit("prove_eoa_activity", UltraPlonkBackend);
        // const { noir, backend } = await hre.noir.getCircuit("prove_eoa_activity");

        let witnessData = fs.readFileSync(`./test/inputs/TestNoirProofOfEOAActivityProver.toml`);
        let input = toml.parse(witnessData);
        fs.writeFileSync('./test/inputs/prove-eoa-activity-input-data.json', JSON.stringify(input, null, 2));

        // Start timing
        const start = Date.now();

        const { witness } = await noir.execute(input);

        // const { proof, publicInputs } = await backend.generateProof(witness, {
        // keccak: true,
        // });

        const { proof, publicInputs } = await backend.generateProof(witness);

        // End timing and calculate duration
        const end = Date.now();
        const duration = end - start;

        console.log(`Proving step took ${duration} milliseconds`);

        console.log(`publicInputs: ${publicInputs}`);

        // The first public input should be verified_balance
        //   expect(BigInt(publicInputs[0])).to.eq(BigInt(input.verified_balance));

        // // First, check expected result with staticCall
        // const expectedResult = await contract.verify.staticCall(proof, 1);
        // expect(expectedResult).to.be.true;

        // // Then execute the actual transaction to measure gas
        // const tx = await contract.verify(proof, 1);
        // const receipt = await tx.wait();
        // console.log(`Gas used for verify(): ${receipt?.gasUsed}`);

        // Execute transaction to verify proof (this will show in gas report)
        const tx = await contract.verify(proof, 1);
        await tx.wait();

        // Check the result using the public isVerified variable
        const result = await contract.isVerified();
        expect(result).to.be.true;

        //   const resultJs = await backend.verifyProof(
        //     {
        //       proof,
        //     //   publicInputs: [String(input.verified_balance)],
        //     publicInputs: [String(input.verified_balance)],
        //     },
        //     { keccak: true },
        //   );
        //   expect(resultJs).to.eq(true);
        });
    });
});
