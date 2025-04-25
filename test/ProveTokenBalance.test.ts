import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { UltraPlonkBackend } from '@aztec/bb.js';

const fs = require("fs");
let toml = require("toml");

describe("ProveTokenBalance", () => {
    describe("deployment", () => {
        it("should deploy the contract", async () => {
            const contractFactory = await ethers.getContractFactory("ProveTokenBalance");
            const contract = await contractFactory.deploy();
            await contract.waitForDeployment();
        });
    });

    describe("proving and verifying token balance on-chain", () => {
        it("proves and verifies token balance on-chain", async () => {
        // Deploy a verifier contract
        const contractFactory = await ethers.getContractFactory("ProveTokenBalance");
        const contract = await contractFactory.deploy();
        await contract.waitForDeployment();

        // Generate a proof
        const { noir, backend } = await hre.noir.getCircuit("token_balance", UltraPlonkBackend);
        // const { noir, backend } = await hre.noir.getCircuit("native_balance");

        // Using the values from Prover.toml
        //   const input = {
        //     signature: "0x2d37b16631b67cbe79e8b115cda1ee74dde8492beef9fac0746777c463e0c8cc5cfd2cea5f1e2e6d8899e4fe33ab709a449e262cc9fc56c3d63b789d99270954",
        //     message_hash: "0x9d447d956f18f06efc4e1fa2b715e6a46fe680d3d35e1ebe90b9d56ad1eddca1",
        //     pub_key_x: "0x1209769585e7ea6b1d48fb8e7a49ad4a687f3f219c802b167132b3456ad8d2e4",
        //     pub_key_y: "0x733284ca267f3c5e6fa75bade823fdabd5b4b6a91385d1a6ded76cb55d73611c",
        //     storage_hash: "0xfe248f06eae1a153fb784d20484071892fc0cdcd8c7b764cc6b4cf33fd33a524",
        //     storage_leaf: "0xec9e3f9a854de2833fd2179351140877fd920a159800dc1c139b4e8e4b59657b8c8b027b7c8936148ec1a00001000000000000000000000000000000000000000000000000",
        //     storage_nodes: [
        //       // For brevity, we're using empty arrays here
        //       // In a real test, you would copy the full arrays from Prover.toml
        //       Array(532).fill(0),
        //       Array(532).fill(0),
        //       Array(532).fill(0),
        //       Array(532).fill(0),
        //       Array(532).fill(0),
        //       Array(532).fill(0),
        //       Array(532).fill(0)
        //     ],
        //     storage_depth: 6,
        //     storage_value: "0x27b7c8936148ec1a00001",
        //     chain_id: 8453,
        //     block_number: 0,
        //     token_address: "0x0000000000000000000000000000000000000000",
        //     balance_slot: 0,
        //     verified_balance: "0x27b7c8936148ec1a00001"
        //   };

        let witnessData = fs.readFileSync(`./test/inputs/TestTokenBalanceProver.toml`);
        let input = toml.parse(witnessData);
        fs.writeFileSync('./test/inputs/token-balance-input-data.json', JSON.stringify(input, null, 2));

        const { witness } = await noir.execute(input);

        // const { proof, publicInputs } = await backend.generateProof(witness, {
        // keccak: true,
        // });

        const { proof, publicInputs } = await backend.generateProof(witness);

        // console.log(`publicInputs: ${publicInputs}`);

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
