import { expect } from "chai";
import hre, { ethers } from "hardhat";
import { UltraPlonkBackend } from '@aztec/bb.js';

describe("HelloWorld", () => {
  describe("deployment", () => {
    it("should deploy the contract", async () => {
        const contractFactory = await ethers.getContractFactory("HelloWorld");
        const contract = await contractFactory.deploy();
        await contract.waitForDeployment();
    });
  });

  describe("proving and verifying native balance on-chain", () => {
    it("proves and verifies HelloWorld on-chain", async () => {
      // Deploy a verifier contract
      const contractFactory = await ethers.getContractFactory("HelloWorld");
      const contract = await contractFactory.deploy();
      await contract.waitForDeployment();

      // Generate a proof
      const { noir, backend } = await hre.noir.getCircuit("hello_world", UltraPlonkBackend);
      const input = { x: 1, y: 1};
      const { witness } = await noir.execute(input);
      // const { proof, publicInputs } = await backend.generateProof(witness, {
      //   keccak: true,
      // });
      const { proof, publicInputs } = await backend.generateProof(witness);
      // it matches because we marked y as `pub` in `main.nr`
      expect(BigInt(publicInputs[0])).to.eq(BigInt(input.y));

      // Execute transaction to verify proof (this will show in gas report)
      const tx = await contract.verify(proof, input.y);
      await tx.wait();

      // Verify the proof on-chain
      const result = await contract.isVerified();
      expect(result).to.eq(true);

      // You can also verify in JavaScript.
      const resultJs = await backend.verifyProof(
        {
          proof,
          publicInputs: [String(input.y)],
        },
        // { keccak: true },
      );
      expect(resultJs).to.eq(true);
    });
  });
});