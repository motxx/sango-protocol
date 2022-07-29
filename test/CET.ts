import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";

chai.use(solidity);

describe("Content Excited Token", async () => {
  let contentOwner: SignerWithAddress;
  let excitingModule: SignerWithAddress;
  let s1: SignerWithAddress;
  let cet: Contract;

  beforeEach(async () => {
    [, contentOwner, excitingModule, s1] = await ethers.getSigners();
    const CET = await ethers.getContractFactory("CET");
    cet = await CET.connect(contentOwner).deploy("Test CET", "TCET");
  });

  describe("When CET modules are set up", async () => {
    beforeEach(async () => {
      await cet.connect(contentOwner).grantExcitingModule(excitingModule.address);
    });

    it("Should mintNFT", async () => {
      await cet.connect(contentOwner).mintNFT(s1.address);
      expect(await cet.balanceOf(s1.address)).equals(1);
      expect(await cet.holdingAmount(s1.address)).equals(0);
    });
  
    it("Should mintAmount", async () => {
      await cet.connect(contentOwner).mintNFT(s1.address);
      await cet.connect(excitingModule).mintAmount(s1.address, 1000);
      expect(await cet.balanceOf(s1.address)).equals(1);
      expect(await cet.holdingAmount(s1.address)).equals(1000);
    });

    it("Should burnAmount", async () => {
      await cet.connect(contentOwner).mintNFT(s1.address);
      await cet.connect(excitingModule).mintAmount(s1.address, 1000);
      await cet.connect(contentOwner).burnAmount(s1.address, 200);
      expect(await cet.balanceOf(s1.address)).equals(1);
      expect(await cet.holdingAmount(s1.address)).equals(800);
    });
  });
});
