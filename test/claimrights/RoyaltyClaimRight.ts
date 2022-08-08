import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

chai.use(solidity);

describe("RoyaltyClaimRight - Settings", async () => {
  let erc20: Contract;
  let claimRight: Contract;

  beforeEach(async () => {
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    erc20 = await MockERC20.deploy();
    const MockRoyaltyClaimRight = await ethers.getContractFactory("MockRoyaltyClaimRight");
    claimRight = await MockRoyaltyClaimRight.deploy("MockRoyaltyClaimRight", "MRCR");
  });

  it("Should verify _setApprovalForIncomingToken", async () => {
    expect(await claimRight.isApprovedToken(erc20.address)).false;
    await claimRight.setApprovalForIncomingToken(erc20.address, true);
    expect(await claimRight.isApprovedToken(erc20.address)).true;
    await claimRight.setApprovalForIncomingToken(erc20.address, false);
    expect(await claimRight.isApprovedToken(erc20.address)).false;
  });

  it("Should verify minIncomingAmount", async () => {
    await claimRight.setApprovalForIncomingToken(erc20.address, true);
    expect(await claimRight.minIncomingAmount(erc20.address)).equals(0);
    await claimRight.setMinIncomingAmount(erc20.address, 1);
    expect(await claimRight.minIncomingAmount(erc20.address)).equals(1);
  });
});

describe("RoyaltyClaimRight - Distributions", async () => {
  let erc20: Contract;
  let claimRight: Contract;
  let owner: SignerWithAddress;
  let s1: SignerWithAddress;
  let s2: SignerWithAddress;

  beforeEach(async () => {
    [owner, s1, s2] = await ethers.getSigners();
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    erc20 = await MockERC20.deploy();
    const MockRoyaltyClaimRight = await ethers.getContractFactory("MockRoyaltyClaimRight");
    claimRight = await MockRoyaltyClaimRight.deploy("MockRoyaltyClaimRight", "MRCR");
    await claimRight.setApprovalForIncomingToken(erc20.address, true);
    await erc20.mint(owner.address, 1000);
  });

  it("Should distribute royalties", async () => {
    expect(await erc20.balanceOf(claimRight.address)).equals(0);
    await erc20.approve(claimRight.address, 1);
    await claimRight.distribute(erc20.address, 1);
    expect(await erc20.balanceOf(claimRight.address)).equals(1);
    expect(await erc20.allowance(owner.address, claimRight.address)).equals(0);
  });

  it("Should not distribute royalties if the token is not approved", async () => {
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const anotherERC20 = await MockERC20.deploy();
    await anotherERC20.approve(claimRight.address, 1);
    await claimRight.isApprovedToken(anotherERC20.address).false;
    await expect(claimRight.distribute(anotherERC20.address, 1)).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'RoyaltyClaimRight: not approved token'");
  });

  it("Should not distribute royalties less than minIncomingAmount", async () => {
    expect(await erc20.balanceOf(claimRight.address)).equals(0);
    await erc20.approve(claimRight.address, 2);
    await claimRight.setMinIncomingAmount(erc20.address, 2);
    await expect(claimRight.distribute(erc20.address, 1)).revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'RoyaltyClaimRight: less than min incoming amount'");
    await claimRight.distribute(erc20.address, 2);
    expect(await erc20.balanceOf(claimRight.address)).equals(2);
  });

  describe("_claimNext", async () => {
    it("Should get royalty", async () => {
      await claimRight.mint(s1.address, 1);

      await erc20.approve(claimRight.address, 1);
      await claimRight.distribute(erc20.address, 1);

      await claimRight.claimNext(s1.address, erc20.address);

      expect(await erc20.balanceOf(claimRight.address)).equals(0);
      expect(await erc20.balanceOf(s1.address)).equals(1);
    });

    it("Should not get royalty if no distribution", async () => {
      await claimRight.mint(s1.address, 1);
      await expect(claimRight.claimNext(s1.address, erc20.address)).revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'RoyaltyClaimRight: no more incoming amount exists'");
    });

    it("Should skip if no shares", async () => {
      // Distribute royalty but no claimers.
      await erc20.approve(claimRight.address, 1);
      await claimRight.distribute(erc20.address, 1);

      // Add a claimer.
      await claimRight.mint(s1.address, 1);
      await claimRight.claimNext(s1.address, erc20.address);

      // Verify the claimer can't get royalty.
      expect(await erc20.balanceOf(claimRight.address)).equals(1);
      expect(await erc20.balanceOf(s1.address)).equals(0);

      // Distribute royalty again.
      await erc20.approve(claimRight.address, 1);
      await claimRight.distribute(erc20.address, 1);
      await claimRight.claimNext(s1.address, erc20.address);

      // Verify the claimer can get only most recent royalty.
      expect(await erc20.balanceOf(claimRight.address)).equals(1);
      expect(await erc20.balanceOf(s1.address)).equals(1);
    });

    it("Should skip if no amount can be got because of too small share", async () => {
      await claimRight.mint(s1.address, 1);
      await claimRight.mint(s2.address, 2);

      await erc20.approve(claimRight.address, 1);
      await claimRight.distribute(erc20.address, 1);

      await claimRight.claimNext(s1.address, erc20.address);

      expect(await erc20.balanceOf(claimRight.address)).equals(1);
      expect(await erc20.balanceOf(s1.address)).equals(0);
    });

    it("Should get royalties by multiple claimers", async () => {
      await claimRight.mint(s1.address, 1);
      await claimRight.mint(s2.address, 2);

      await erc20.approve(claimRight.address, 10);
      await claimRight.distribute(erc20.address, 10);

      await claimRight.claimNext(s1.address, erc20.address);
      await claimRight.claimNext(s2.address, erc20.address);

      expect(await erc20.balanceOf(claimRight.address)).equals(1); // Remainder exists in the contract.
      expect(await erc20.balanceOf(s1.address)).equals(3);
      expect(await erc20.balanceOf(s2.address)).equals(6);
    });
  });

  describe("_claimIterate", async () => {
    it("Should get royalties by iteration times", async () => {
      await claimRight.mint(s1.address, 1);

      await erc20.approve(claimRight.address, 6);
      await claimRight.distribute(erc20.address, 1);
      await claimRight.distribute(erc20.address, 2);
      await claimRight.distribute(erc20.address, 3);
      await claimRight.claimIterate(s1.address, erc20.address, 2);

      expect(await erc20.balanceOf(s1.address)).equals(3);
    });

    it("Should get royalties until last if iteration times > distribution times", async () => {
      await claimRight.mint(s1.address, 1);

      await erc20.approve(claimRight.address, 6);
      await claimRight.distribute(erc20.address, 1);
      await claimRight.distribute(erc20.address, 2);
      await claimRight.distribute(erc20.address, 3);
      await claimRight.claimIterate(s1.address, erc20.address, 10);

      expect(await erc20.balanceOf(s1.address)).equals(6);
    });

    it("Should not get royalties if no distribution", async () => {
      await claimRight.mint(s1.address, 1);
      await expect(claimRight.claimIterate(s1.address, erc20.address, 1)).revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'RoyaltyClaimRight: no more incoming amount exists'");
    });
  });

  describe("_claimAll", async () => {
    it("Should get all royalties to claim", async () => {
      await claimRight.mint(s1.address, 1);

      await erc20.approve(claimRight.address, 6);
      await claimRight.distribute(erc20.address, 1);
      await claimRight.distribute(erc20.address, 2);
      await claimRight.distribute(erc20.address, 3);
      await claimRight.claimAll(s1.address, erc20.address);

      expect(await erc20.balanceOf(s1.address)).equals(6);
    });

    it("Should not get royalties if no distribution", async () => {
      await claimRight.mint(s1.address, 1);
      await expect(claimRight.claimAll(s1.address, erc20.address)).revertedWith(
        "VM Exception while processing transaction: reverted with reason string 'RoyaltyClaimRight: no more incoming amount exists'");
    });
  });
});

describe("RoyaltyClaimRight - Transferring among holders", async () => {
  let erc20: Contract;
  let claimRight: Contract;
  let owner: SignerWithAddress;
  let s1: SignerWithAddress;
  let s2: SignerWithAddress;

  beforeEach(async () => {
    [owner, s1, s2] = await ethers.getSigners();
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    erc20 = await MockERC20.deploy();
    const MockRoyaltyClaimRight = await ethers.getContractFactory("MockRoyaltyClaimRight");
    claimRight = await MockRoyaltyClaimRight.deploy("MockRoyaltyClaimRight", "MRCR");
    await claimRight.setApprovalForIncomingToken(erc20.address, true);
    await erc20.mint(owner.address, 1000);
  });

  it("Should claim but get no royalty after giving all rights to other holder", async () => {
    await claimRight.mint(s1.address, 1);
    await claimRight.connect(s1).transfer(s2.address, 1);

    await erc20.approve(claimRight.address, 1);
    await claimRight.distribute(erc20.address, 1);
    await claimRight.claimNext(s1.address, erc20.address);

    expect(await erc20.balanceOf(claimRight.address)).equals(1);
    expect(await erc20.balanceOf(s1.address)).equals(0);
  });

  it("Should claim after receiving all rights from other holder", async () => {
    await claimRight.mint(s1.address, 1);
    await claimRight.connect(s1).transfer(s2.address, 1);

    await erc20.approve(claimRight.address, 1);
    await claimRight.distribute(erc20.address, 1);
    await claimRight.claimNext(s2.address, erc20.address);

    expect(await erc20.balanceOf(claimRight.address)).equals(0);
    expect(await erc20.balanceOf(s2.address)).equals(1);
  });

  it("Should claim both holders if giving parts of rights", async () => {
    await claimRight.mint(s1.address, 2);
    await claimRight.connect(s1).transfer(s2.address, 1);

    await erc20.approve(claimRight.address, 2);
    await claimRight.distribute(erc20.address, 2);
    await claimRight.claimNext(s1.address, erc20.address);
    await claimRight.claimNext(s2.address, erc20.address);

    expect(await erc20.balanceOf(claimRight.address)).equals(0);
    expect(await erc20.balanceOf(s1.address)).equals(1);
    expect(await erc20.balanceOf(s2.address)).equals(1);
  });
});
