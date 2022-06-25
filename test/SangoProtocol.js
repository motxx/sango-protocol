const { expect } = require("chai");

describe("Token contract", function () {
  let SangoProtocol;
  let sangoProtocol;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    SangoProtocol = await ethers.getContractFactory("SangoProtocol");
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    sangoProtocol = await SangoProtocol.deploy();

    await sangoProtocol.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await sangoProtocol.owner()).to.equal(owner.address);
    });

    it("Should assign the total supply of tokens to the owner", async function () {
      const ownerBalance = await sangoProtocol.balanceOf(owner.address);
      expect(await sangoProtocol.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      // Transfer 50 tokens from owner to addr1
      await sangoProtocol.transfer(addr1.address, 50);
      const addr1Balance = await sangoProtocol.balanceOf(
        addr1.address
      );
      expect(addr1Balance).to.equal(50);

      // Transfer 50 tokens from addr1 to addr2
      // We use .connect(signer) to send a transaction from another account
      await sangoProtocol.connect(addr1).transfer(addr2.address, 50);
      const addr2Balance = await sangoProtocol.balanceOf(
        addr2.address
      );
      expect(addr2Balance).to.equal(50);
    });

    it("Should fail if sender doesn’t have enough tokens", async function () {
      const initialOwnerBalance = await sangoProtocol.balanceOf(
        owner.address
      );

      // Try to send 1 token from addr1 (0 tokens) to owner (1000 tokens).
      // `require` will evaluate false and revert the transaction.
      await expect(
        sangoProtocol.connect(addr1).transfer(owner.address, 1)
      ).to.be.revertedWith("Not enough tokens");

      // Owner balance shouldn't have changed.
      expect(await sangoProtocol.balanceOf(owner.address)).to.equal(
        initialOwnerBalance
      );
    });

    it("Should update balances after transfers", async function () {
      const initialOwnerBalance = await sangoProtocol.balanceOf(
        owner.address
      );

      // Transfer 100 tokens from owner to addr1.
      await sangoProtocol.transfer(addr1.address, 100);

      // Transfer another 50 tokens from owner to addr2.
      await sangoProtocol.transfer(addr2.address, 50);

      // Check balances.
      const finalOwnerBalance = await sangoProtocol.balanceOf(
        owner.address
      );
      expect(finalOwnerBalance).to.equal(initialOwnerBalance - 150);

      const addr1Balance = await sangoProtocol.balanceOf(
        addr1.address
      );
      expect(addr1Balance).to.equal(100);

      const addr2Balance = await sangoProtocol.balanceOf(
        addr2.address
      );
      expect(addr2Balance).to.equal(50);
    });
  });
});
