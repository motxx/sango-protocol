import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

chai.use(solidity);

describe("ManagedRoyaltyClaimRight", async () => {
  let erc20: Contract;
  let managedCR: Contract;
  let owner: SignerWithAddress;
  let s1: SignerWithAddress;
  let s2: SignerWithAddress;

  beforeEach(async () => {
    [owner, s1, s2] = await ethers.getSigners();
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    erc20 = await MockERC20.deploy();
    const ManagedRoyaltyClaimRight = await ethers.getContractFactory("ManagedRoyaltyClaimRight");
    managedCR = await ManagedRoyaltyClaimRight.deploy("ManagedRoyaltyClaimRight", "MRCR", ["0x0000000000000000000000000000000000012345"]);
    await managedCR.setApprovalForIncomingToken(erc20.address, true);
    await erc20.mint(owner.address, 1000);
  });

  it("Should verify accounts", async () => {
    expect(await managedCR.accounts()).deep.equals([]);
    await managedCR.mint(s1.address, 1);
    expect(await managedCR.accounts()).deep.equals([s1.address]);
    await managedCR.mint(s1.address, 1);
    expect(await managedCR.accounts()).deep.equals([s1.address]);
    await managedCR.mint(s2.address, 1);
    expect(await managedCR.accounts()).deep.equals([s1.address, s2.address]);
  });

  it("Should verify mint", async () => {
    await managedCR.mint(s1.address, 1);
    await managedCR.mint(s2.address, 2);
    await managedCR.mint(s1.address, 3);
    expect(await managedCR.balanceOf(s1.address)).equals(4);
    expect(await managedCR.balanceOf(s2.address)).equals(2);
  });

  describe("batchMint", async () => {
    it("Should work", async () => {
      await managedCR.batchMint([s1.address], [1]);
      expect(await managedCR.balanceOf(s1.address)).equals(1);
      await managedCR.batchMint([s1.address, s2.address], [1, 2]);
      expect(await managedCR.accounts()).deep.equals([s1.address, s2.address]);
      expect(await managedCR.balanceOf(s1.address)).equals(2);
      expect(await managedCR.balanceOf(s2.address)).equals(2);
    });

    it("Should work if arrays are empty", async () => {
      await managedCR.batchMint([], []);
    });

    it("Should work if duplicate accounts", async () => {
      await managedCR.batchMint([s1.address, s1.address], [1, 2]);
      expect(await managedCR.balanceOf(s1.address)).equals(3);
    });

    it("Should revert if mismatch length", async () => {
      await expect(managedCR.batchMint([s1.address], [1, 2])).revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'ManagedRoyaltyClaimRight: mismatch length'");
      await expect(managedCR.batchMint([s1.address, s2.address], [1])).revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'ManagedRoyaltyClaimRight: mismatch length'");
    });
  });

  describe("burnAll", async () => {
    it("Should verify accounts cleared", async () => {
      await managedCR.batchMint([s1.address, s2.address], [1, 2]);
      await managedCR.burnAll();
      expect(await managedCR.accounts()).deep.equals([]);
      expect(await managedCR.balanceOf(s1.address)).equals(0);
      expect(await managedCR.balanceOf(s2.address)).equals(0);
    });

    it("Should verify idempotence", async () => {
      await managedCR.batchMint([s1.address, s2.address], [1, 2]);
      await managedCR.burnAll();
      await managedCR.batchMint([s1.address, s2.address], [1, 2]);
      expect(await managedCR.accounts()).deep.equals([s1.address, s2.address]);
      expect(await managedCR.balanceOf(s1.address)).equals(1);
      expect(await managedCR.balanceOf(s2.address)).equals(2);
    });
  });
});
