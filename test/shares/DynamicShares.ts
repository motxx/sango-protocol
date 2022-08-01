import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

chai.use(solidity);

describe("DynamicShares", () => {
  let owner: SignerWithAddress;
  let royaltyProvider: SignerWithAddress;
  let s1: SignerWithAddress;
  let s2: SignerWithAddress;
  let s3: SignerWithAddress;
  let s4: SignerWithAddress;
  let s5: SignerWithAddress;

  let rbt: Contract;
  let dShares: Contract;

  beforeEach(async () => {
    [owner, royaltyProvider, s1, s2, s3, s4, s5] = await ethers.getSigners();

    const RBT = await ethers.getContractFactory("RBT");
    rbt = await RBT.deploy();
    await rbt.deployed();

    const MockShares = await ethers.getContractFactory("MockShares");
    dShares = await MockShares.deploy();
    await dShares.deployed();
    await dShares.approveToken(rbt.address);
  });

  const distributeRoyaltyByERC20 = async (erc20: Contract, amount: number) => {
    await erc20.mint(royaltyProvider.address, amount);
    await erc20.connect(royaltyProvider).approve(dShares.address, amount);
    await dShares.connect(royaltyProvider).distribute(erc20.address, amount);
  };

  const distributeRoyalty = async (amount: number) => {
    await distributeRoyaltyByERC20(rbt, amount);
  };

  it("Should pay shares to multiple payees", async () => {
    await dShares.initPayees([s1.address, s2.address], [1, 3]);
    await distributeRoyalty(1000);
    await dShares.release(rbt.address, s1.address);
    await dShares.release(rbt.address, s2.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(250);
    expect(await rbt.balanceOf(s2.address)).to.equal(750);
  });

  it("Should pay shares to multiple payees after re-init shares", async () => {
    await dShares.initPayees([s1.address, s2.address], [1, 3]);
    await dShares.initPayees([s3.address, s4.address, s5.address], [1, 2, 7]);
    await distributeRoyalty(1000);

    await expect(dShares.release(rbt.address, s1.address)).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: account is not due payment'");
    await expect(dShares.release(rbt.address, s2.address)).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: account is not due payment'");
    expect(await rbt.balanceOf(s1.address)).to.equal(0);
    expect(await rbt.balanceOf(s2.address)).to.equal(0);

    await dShares.release(rbt.address, s3.address);
    await dShares.release(rbt.address, s4.address);
    await dShares.release(rbt.address, s5.address);
    expect(await rbt.balanceOf(s3.address)).to.equal(100);
    expect(await rbt.balanceOf(s4.address)).to.equal(200);
    expect(await rbt.balanceOf(s5.address)).to.equal(700);
  });

  it("Should pay shares to a payee", async () => {
    await dShares.initPayees([s1.address], [1]);
    await distributeRoyalty(1000);
    await dShares.release(rbt.address, s1.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(1000);
  });

  it("Should pay surplus shares to the first payee", async () => {
    await dShares.initPayees([s1.address, s2.address], [1, 2]);
    await distributeRoyalty(1000);
    await dShares.release(rbt.address, s1.address);
    await dShares.release(rbt.address, s2.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(334);
    expect(await rbt.balanceOf(s2.address)).to.equal(666);
  });

  it("Should release after re-init", async () => {
    await dShares.initPayees([s1.address], [1]);
    await distributeRoyalty(1000);
    await dShares.initPayees([s2.address, s3.address], [1, 3]);
    await distributeRoyalty(1000);
    await dShares.release(rbt.address, s1.address);
    await dShares.release(rbt.address, s2.address);
    await dShares.release(rbt.address, s3.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(1000);
    expect(await rbt.balanceOf(s2.address)).to.equal(250);
    expect(await rbt.balanceOf(s3.address)).to.equal(750);
  });

  it("Should release after multiple distribute", async () => {
    await dShares.initPayees([s1.address], [1]);
    await distributeRoyalty(1000);
    await distributeRoyalty(200);
    await dShares.release(rbt.address, s1.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(1200);
  });

  it("Should withdraw after multiple distribute", async () => {
    await dShares.initPayees([s1.address], [1]);
    await distributeRoyalty(1000);
    await distributeRoyalty(200);
    await dShares.connect(s1).withdraw(rbt.address);
    expect(await rbt.balanceOf(s1.address)).to.equal(1200);
  });

  it("Should return correct total received", async () => {
    await dShares.initPayees([s1.address, s2.address], [2, 3]);
    await distributeRoyalty(1000);
    expect(await dShares.totalReceived(rbt.address, s1.address)).to.equal(400);
    expect(await dShares.totalReceived(rbt.address, s2.address)).to.equal(600);

    await distributeRoyalty(100);
    expect(await dShares.totalReceived(rbt.address, s1.address)).to.equal(440);
    expect(await dShares.totalReceived(rbt.address, s2.address)).to.equal(660);
  });

  it("Should return correct already released", async () => {
    await dShares.initPayees([s1.address, s2.address], [2, 3]);
    await distributeRoyalty(1000);
    expect(await dShares.alreadyReleased(rbt.address, s1.address)).to.equal(0);
    expect(await dShares.alreadyReleased(rbt.address, s2.address)).to.equal(0);

    await dShares.release(rbt.address, s1.address);
    await dShares.release(rbt.address, s2.address);
    expect(await dShares.alreadyReleased(rbt.address, s1.address)).to.equal(400);
    expect(await dShares.alreadyReleased(rbt.address, s2.address)).to.equal(600);

    await distributeRoyalty(100);
    expect(await dShares.alreadyReleased(rbt.address, s1.address)).to.equal(400);
    expect(await dShares.alreadyReleased(rbt.address, s2.address)).to.equal(600);

    await dShares.release(rbt.address, s1.address);
    await dShares.release(rbt.address, s2.address);
    expect(await dShares.alreadyReleased(rbt.address, s1.address)).to.equal(440);
    expect(await dShares.alreadyReleased(rbt.address, s2.address)).to.equal(660);
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

  it("Should fail to receive not approved ERC20", async () => {
    const FakeRBT = await ethers.getContractFactory("RBT");
    const fakeERC20 = await FakeRBT.deploy();
    await fakeERC20.deployed();

    await dShares.initPayees([s1.address], [1]);
    await expect(distributeRoyaltyByERC20(fakeERC20, 1000)).to.revertedWith(
      "VM Exception while processing transaction: reverted with reason string 'DynamicShares: not approved token'");
  });
});
