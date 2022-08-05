import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

chai.use(solidity);

describe("FixedRoyaltyClaimRight", async () => {
  let erc20: Contract;
  let owner: SignerWithAddress;
  let s1: SignerWithAddress;
  let s2: SignerWithAddress;

  beforeEach(async () => {
    [owner, s1, s2] = await ethers.getSigners();
  });

  it("Should verify accounts", async () => {
    const FixedRoyaltyClaimRight = await ethers.getContractFactory("FixedRoyaltyClaimRight");
    let fixedCR = await FixedRoyaltyClaimRight.deploy(
      "FixedRoyaltyClaimRight", "FRCR",
      [], [],
      ["0x0000000000000000000000000000000000012345"],
    );
    expect(await fixedCR.accounts()).deep.equals([]);

    fixedCR = await FixedRoyaltyClaimRight.deploy(
      "FixedRoyaltyClaimRight", "FRCR",
      [s1.address, s2.address], [1, 2],
      ["0x0000000000000000000000000000000000012345"],
    );
    expect(await fixedCR.accounts()).deep.equals([s1.address, s2.address]);
  });

  it("Should not construct if duplicate accounts", async () => {
    const FixedRoyaltyClaimRight = await ethers.getContractFactory("FixedRoyaltyClaimRight");
    await expect(FixedRoyaltyClaimRight.deploy(
      "FixedRoyaltyClaimRight", "FRCR",
      [s1.address, s1.address], [1, 2],
      ["0x0000000000000000000000000000000000012345"],
    )).revertedWith("VM Exception while processing transaction: reverted with reason string 'FixedRoyaltyClaimRight: duplicate accounts'");
  });
});
