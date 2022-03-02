// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*
 * @title Vortex pet v1!
 * @Author Lem Canady
 */

contract VortexPet is ERC1155, Ownable {
    using Strings for string;

    uint256 constant RATE = 86400;
    uint256 constant STAGES = 3;
    uint256 TOTAL_PETS = 5000;

    string _name;
    string _symbol;
    string _baseURI;
    uint256 models = 3;
    uint256 count = 0;

    struct VortexPetStruct {
        address owner;
        uint256 bornOn;
        uint256 model;
        uint256 variant;
    }

    mapping(uint256 => VortexPetStruct) pets;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _uri
    ) ERC1155(_uri) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = _uri;
    }

    /**
     * @notice Get the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Get the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Set the baseURI
     */
    function setURI(string memory _uri) public {
        _baseURI = _uri;
    }

    function getStage(uint256 _id) public view returns (uint256) {
        require(pets[_id].bornOn > 0);
        uint256 stage = (block.timestamp - pets[_id].bornOn) / RATE;

        return stage <= STAGES ? stage : STAGES;
    }

    function random(uint256 seed) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, seed)
                )
            );
    }

    function createPet(uint256 id, address owner) private {
        pets[id].owner = owner;
        pets[id].bornOn = block.timestamp;
        pets[id].model = (random(id) % models) + 1;
        pets[id].variant = (random(id + 1) % 3) + 1;
    }

    function getPet(uint256 id)
        public
        view
        returns (
            address owner,
            uint256 bornOn,
            uint256 model,
            uint256 variant,
            uint256 stage
        )
    {
        require(pets[id].bornOn > 0);
        return (
            pets[id].owner,
            pets[id].bornOn,
            pets[id].model,
            pets[id].variant,
            getStage(id)
        );
    }

    function mint(uint256 amt) public payable {
        require(amt > 0);
        require(count + amt <= TOTAL_PETS);

        uint256 i;
        for (i = 0; i < amt; i++) {
            count += 1;
            createPet(count, msg.sender);
            _mint(msg.sender, count, 1, "0x0");
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        if (getStage(tokenId) == STAGES) {
            return
                string(
                    abi.encodePacked(
                        _baseURI,
                        Strings.toString(STAGES),
                        "/",
                        Strings.toString(pets[tokenId].model),
                        "-",
                        Strings.toString(pets[tokenId].variant),
                        ".json"
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        _baseURI,
                        Strings.toString(getStage(tokenId)),
                        "/",
                        Strings.toString(pets[tokenId].model),
                        ".json"
                    )
                );
        }
    }
}
