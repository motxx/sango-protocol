import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract, Signer } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

chai.use(solidity);

describe("DynamicShares", () => {
  let owner: SignerWithAddress;
  let s1: SignerWithAddress;
  let s2: SignerWithAddress;
  let s3: SignerWithAddress;
  let s4: SignerWithAddress;
  let s5: SignerWithAddress;

  let rbt: Contract;
  let dShares: Contract;

  beforeEach(async () => {
    [owner, s1, s2, s3, s4, s5] = await ethers.getSigners();

    const RBT = await ethers.getContractFactory("RBT");
    rbt = await RBT.deploy();
    await rbt.deployed();

    const DynamicShares = await ethers.getContractFactory("DynamicShares");
    dShares = await DynamicShares.deploy(rbt.address);
    await dShares.deployed();
  });

  it("Should pay shares to multiple payees", async () => {
    await dShares.initShares([s1.address, s2.address], [1, 3]);
    await rbt.mint(dShares.address, 1000);
    await dShares.release(s1.address);
    await dShares.release(s2.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(250);
    expect(await rbt.balanceOf(s2.address)).to.equal(750);
  });

  it("Should pay shares to multiple payees after re-init shares", async () => {
    await dShares.initShares([s1.address, s2.address], [1, 3]);
    await dShares.initShares([s3.address, s4.address, s5.address], [1, 2, 7]);
    await rbt.mint(dShares.address, 1000);

    await expect(dShares.release(s1.address)).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: account is not due payment'");
    await expect(dShares.release(s2.address)).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: account is not due payment'");
    expect(await rbt.balanceOf(s1.address)).to.equal(0);
    expect(await rbt.balanceOf(s2.address)).to.equal(0);

    await dShares.release(s3.address);
    await dShares.release(s4.address);
    await dShares.release(s5.address);
    expect(await rbt.balanceOf(s3.address)).to.equal(100);
    expect(await rbt.balanceOf(s4.address)).to.equal(200);
    expect(await rbt.balanceOf(s5.address)).to.equal(700);
  });

  it("Should pay shares to a payee", async () => {
    await dShares.initShares([s1.address], [1]);
    await rbt.mint(dShares.address, 1000);
    await dShares.release(s1.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(1000);
  });

  it("Should pay surplus shares to the first payee", async () => {
    await dShares.initShares([s1.address, s2.address], [1, 2]);
    await rbt.mint(dShares.address, 1000);
    await dShares.release(s1.address);
    await dShares.release(s2.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(334);
    expect(await rbt.balanceOf(s2.address)).to.equal(666);
  });

  it("Should release after re-init", async () => {
    await dShares.initShares([s1.address], [1]);
    await rbt.mint(dShares.address, 1000);
    await dShares.initShares([s2.address, s3.address], [1, 3]);
    await rbt.mint(dShares.address, 1000);
    await dShares.release(s1.address);
    await dShares.release(s2.address);
    await dShares.release(s3.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(1000);
    expect(await rbt.balanceOf(s2.address)).to.equal(250);
    expect(await rbt.balanceOf(s3.address)).to.equal(750);
  });

  it("Should release after multiple mint", async () => {
    await dShares.initShares([s1.address], [1]);
    await rbt.mint(dShares.address, 1000);
    await rbt.mint(dShares.address, 200);
    await dShares.release(s1.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(1200);
  });

  it("Should withdraw after multiple mint", async () => {
    await dShares.initShares([s1.address], [1]);
    await rbt.mint(dShares.address, 1000);
    await rbt.mint(dShares.address, 200);
    await dShares.connect(s1).withdraw();
    expect(await rbt.balanceOf(s1.address)).to.equal(1200);
  });
});
