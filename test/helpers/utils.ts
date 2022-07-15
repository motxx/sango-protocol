import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

export type SangoCtorArgs = {
  rbtAddress: string;
  creators: string[];
  creatorShares: number[];
  primaries: string[];
  primaryShares: number[];
  creatorProp: number;
  cetBurnerProp: number;
  cbtStakerProp: number;
  primaryProp: number;
};

export type DeploySangoFunction = (args: SangoCtorArgs) => Promise<Contract>;

export const deploySango = async (args: SangoCtorArgs) => {
  const SangoContent = await ethers.getContractFactory("SangoContent");
  const sango = await SangoContent.deploy(
    args.rbtAddress,
    args.creators,
    args.creatorShares,
    args.primaries,
    args.primaryShares,
    args.creatorProp,
    args.cetBurnerProp,
    args.cbtStakerProp,
    args.primaryProp,
  );
  await sango.deployed();
  return sango;
};

export const deploySangoBy = async (deployer: SignerWithAddress, args: SangoCtorArgs) => {
  const SangoContent = await ethers.getContractFactory("SangoContent");
  const sango = await SangoContent.connect(deployer).deploy(
    args.rbtAddress,
    args.creators,
    args.creatorShares,
    args.primaries,
    args.primaryShares,
    args.creatorProp,
    args.cetBurnerProp,
    args.cbtStakerProp,
    args.primaryProp,
  );
  await sango.deployed();
  return sango;
};
