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

    const MockShares = await ethers.getContractFactory("MockShares");
    dShares = await MockShares.deploy(rbt.address);
    await dShares.deployed();
  });

  it("Should pay shares to multiple payees", async () => {
    await dShares.initPayees([s1.address, s2.address], [1, 3]);
    await rbt.mint(dShares.address, 1000);
    await dShares.release(s1.address);
    await dShares.release(s2.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(250);
    expect(await rbt.balanceOf(s2.address)).to.equal(750);
  });

  it("Should pay shares to multiple payees after re-init shares", async () => {
    await dShares.initPayees([s1.address, s2.address], [1, 3]);
    await dShares.initPayees([s3.address, s4.address, s5.address], [1, 2, 7]);
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
    await dShares.initPayees([s1.address], [1]);
    await rbt.mint(dShares.address, 1000);
    await dShares.release(s1.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(1000);
  });

  it("Should pay surplus shares to the first payee", async () => {
    await dShares.initPayees([s1.address, s2.address], [1, 2]);
    await rbt.mint(dShares.address, 1000);
    await dShares.release(s1.address);
    await dShares.release(s2.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(334);
    expect(await rbt.balanceOf(s2.address)).to.equal(666);
  });

  it("Should release after re-init", async () => {
    await dShares.initPayees([s1.address], [1]);
    await rbt.mint(dShares.address, 1000);
    await dShares.initPayees([s2.address, s3.address], [1, 3]);
    await rbt.mint(dShares.address, 1000);
    await dShares.release(s1.address);
    await dShares.release(s2.address);
    await dShares.release(s3.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(1000);
    expect(await rbt.balanceOf(s2.address)).to.equal(250);
    expect(await rbt.balanceOf(s3.address)).to.equal(750);
  });

  it("Should release after multiple mint", async () => {
    await dShares.initPayees([s1.address], [1]);
    await rbt.mint(dShares.address, 1000);
    await rbt.mint(dShares.address, 200);
    await dShares.release(s1.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(1200);
  });

  it("Should withdraw after multiple mint", async () => {
    await dShares.initPayees([s1.address], [1]);
    await rbt.mint(dShares.address, 1000);
    await rbt.mint(dShares.address, 200);
    await dShares.connect(s1).withdraw();
    expect(await rbt.balanceOf(s1.address)).to.equal(1200);
  });

  it("Should return correct total received", async () => {
    await dShares.initPayees([s1.address, s2.address], [2, 3]);
    await rbt.mint(dShares.address, 1000);
    expect(await dShares.totalReceived(s1.address)).to.equal(400);
    expect(await dShares.totalReceived(s2.address)).to.equal(600);

    await rbt.mint(dShares.address, 100);
    expect(await dShares.totalReceived(s1.address)).to.equal(440);
    expect(await dShares.totalReceived(s2.address)).to.equal(660);
  });

  it("Should return correct already released", async () => {
    await dShares.initPayees([s1.address, s2.address], [2, 3]);
    await rbt.mint(dShares.address, 1000);
    expect(await dShares.alreadyReleased(s1.address)).to.equal(0);
    expect(await dShares.alreadyReleased(s2.address)).to.equal(0);

    await dShares.release(s1.address);
    await dShares.release(s2.address);
    expect(await dShares.alreadyReleased(s1.address)).to.equal(400);
    expect(await dShares.alreadyReleased(s2.address)).to.equal(600);

    await rbt.mint(dShares.address, 100);
    expect(await dShares.alreadyReleased(s1.address)).to.equal(400);
    expect(await dShares.alreadyReleased(s2.address)).to.equal(600);

    await dShares.release(s1.address);
    await dShares.release(s2.address);
    expect(await dShares.alreadyReleased(s1.address)).to.equal(440);
    expect(await dShares.alreadyReleased(s2.address)).to.equal(660);
  });

  it("Should return correct shares", async () => {
    await dShares.initPayees([s1.address, s2.address], [2, 3]);
    expect(await dShares.shares(s1.address)).to.equal(2);
    expect(await dShares.shares(s2.address)).to.equal(3);
    expect(await dShares.shares(s3.address)).to.equal(0);

    await dShares.initPayees([s3.address], [1]);
    expect(await dShares.shares(s1.address)).to.equal(0);
    expect(await dShares.shares(s2.address)).to.equal(0);
    expect(await dShares.shares(s3.address)).to.equal(1);
  });

  it("Should behaves in the same way: resetPayees, addPayee vs initPayees", async () => {
    // Should be same as: await dShares.initPayees([s1.address, s2.address], [2, 3]);
    await dShares.addPayee(s1.address, 2);
    await dShares.addPayee(s2.address, 3);
    expect(await dShares.shares(s1.address)).to.equal(2);
    expect(await dShares.shares(s2.address)).to.equal(3);

    // Should be same as: await dShares.initPayees([s3.address], [1]);
    await dShares.resetPayees();
    await dShares.addPayee(s3.address, 1);
    expect(await dShares.shares(s1.address)).to.equal(0);
    expect(await dShares.shares(s2.address)).to.equal(0);
    expect(await dShares.shares(s3.address)).to.equal(1);
  });

  it("Should fail to initPayees if caller is not the owner", async () => {
    await expect(dShares.connect(s1).initPayees([s2.address], [100])).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'");
  });

  it("Should fail to resetPayees if caller is not the owner", async () => {
    await expect(dShares.connect(s1).resetPayees()).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'");
  });

  it("Should fail to addPayee if caller is not the owner", async () => {
    await expect(dShares.connect(s1).addPayee(s1.address, 100)).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'");
  });

  it("Should fail to receive fake RBT", async () => {
    const FakeRBT = await ethers.getContractFactory("RBT");
    const fakeRBT = await FakeRBT.deploy();
    await fakeRBT.deployed();

    await dShares.initPayees([s1.address], [1]);
    await expect(fakeRBT.mint(dShares.address, 1000)).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: must be called by pre-registered ERC20 token'");
  });
});
