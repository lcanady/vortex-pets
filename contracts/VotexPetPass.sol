// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/*
    @title Vortex Pets Pass
    @author Kumakun.eth
 */

contract VortexPetPass is
    ERC1155,
    Ownable,
    Pausable,
    ERC1155Supply,
    PaymentSplitter
{
    string name_ = "Vortex Pet Pass";
    string symbol_ = "VPP";
    address[] whitelist;
    string _baseURI;

    // Minting prices.
    uint256 wlPrice = 36000000000000000000;
    uint256 pubPrice = 53000000000000000000;
    uint256 totalPasses = 675;

    mapping(uint256 => address) passToAddress;

    constructor(
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares
    ) ERC1155("") PaymentSplitter(_payees, _shares) {
        _baseURI = _uri;
    }

    /**
     * @notice Get the name of the token.
     */
    function name() public view returns (string memory) {
        return name_;
    }

    /**
     * @notice Get the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return symbol_;
    }

    /**
     * @notice Set the URI of the token.
     * @param newuri The new uri to set.
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
     * @notice Add addresses to the whitelist.
     * @param addresses the array of addresses to add to the whitelist.
     */
    function setWhitelist(address[] memory addresses) public onlyOwner {
        uint256 i;
        for (i = 0; i < whitelist.length; i++) {
            whitelist.push(addresses[i]);
        }
    }

    /**
     * @notice Check to see if an address is on the whitelist.
     * @param _address  The address to check.
     */
    function isWhitelist(address _address) public view returns (bool) {
        uint256 i;

        for (i = 0; i < whitelist.length; i++) {
            if (whitelist[i] == _address) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice get the mint price depending on the address that makes the request.
     */
    function getPrice() public view returns (uint256) {
        return isWhitelist(msg.sender) ? wlPrice : pubPrice;
    }

    /**
     * @notice Get the number of passes minted.
     */
    function getCount() public view returns (uint256) {
        return totalSupply(0);
    }

    /**
     * @notice get a semi-random number!
     * @param _seed A seed to help randomize the number.
     */
    function rand(uint256 _seed) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(_seed, block.difficulty, block.timestamp)
                )
            ) % totalSupply(0);
    }

    /**
     * @notice Pause minting.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause Minting.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Mint a Vortex Pet Pass!
     */
    function mint() public payable whenNotPaused {
        uint256 price = isWhitelist(msg.sender) ? wlPrice : pubPrice;
        require(msg.value == price, "Not enough matic to mint");
        require(totalSupply(0) + 1 <= totalPasses, "No more passes to mint.");

        // Raffle 10% to a random pass holder.
        if (totalSupply(0) > 0) {
            payable(passToAddress[rand(totalSupply(0))]).transfer(
                msg.value / 10
            );
        }

        // Mint the pass!
        _mint(msg.sender, 0, 1, "");
    }

    /**
     * @notice Get the URI.
     */
    function uri() public view returns (string memory) {
        return _baseURI;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        // Make sure the raffle benefits transfer.
        uint256 i;
        for (i = 0; i < ids.length; i++) {
            passToAddress[ids[i]] = to;
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
