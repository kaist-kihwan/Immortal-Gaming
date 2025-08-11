// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ItemToken
 * @dev An ERC721 Non-Fungible Token (NFT) that can only be traded using a specific ERC20 token (IGToken).
 */
contract ItemToken is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // The address of the IGToken contract
    IERC20 public immutable igToken;

    // Mapping from tokenId to its price in IGToken
    mapping(uint256 => uint256) public itemPrices;

    // Event to announce a new sale
    event ForSale(uint256 indexed tokenId, uint256 price, address indexed seller);
    // Event to announce a successful purchase
    event Sold(uint256 indexed tokenId, uint256 price, address indexed seller, address indexed buyer);
    // Event to announce that a sale is cancelled
    event SaleCancelled(uint256 indexed tokenId);

    /**
     * @param _igTokenAddress The address of the IGToken ERC20 contract.
     */
    constructor(address _igTokenAddress) ERC721("Item Token", "ITMT") Ownable(msg.sender) {
        igToken = IERC20(_igTokenAddress);
    }

    /**
     * @dev Mints a new ItemToken. Can be called by anyone.
     * The token is assigned to the caller.
     * @param _tokenURI The URI for the token's metadata. (Name changed to avoid shadowing)
     * @return The ID of the newly minted token.
     */
    function mintItem(string memory _tokenURI) public returns (uint256) {
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, _tokenURI); // Using the new parameter name
        _tokenIdCounter.increment();
        return newItemId;
    }

    /**
     * @dev Lists an NFT for sale at a specific price in IGToken.
     * @param tokenId The ID of the token to sell.
     * @param price The selling price in IGToken (in its smallest unit, e.g., wei).
     */
    function listItem(uint256 tokenId, uint256 price) public {
        require(ownerOf(tokenId) == msg.sender, "You do not own this token");
        require(price > 0, "Price must be greater than zero");
        itemPrices[tokenId] = price;
        emit ForSale(tokenId, price, msg.sender);
    }

    /**
     * @dev Cancels a listing for an NFT.
     * @param tokenId The ID of the token to remove from sale.
     */
    function cancelListing(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You do not own this token");
        require(itemPrices[tokenId] > 0, "This token is not for sale");
        delete itemPrices[tokenId];
        emit SaleCancelled(tokenId);
    }

    /**
     * @dev Buys an NFT using IGToken. The buyer must first approve this contract
     * to spend the required amount of IGToken.
     * @param tokenId The ID of the token to buy.
     */
    function buyItem(uint256 tokenId) public {
        uint256 price = itemPrices[tokenId];
        address seller = ownerOf(tokenId);

        require(price > 0, "This token is not for sale");
        require(seller != msg.sender, "You cannot buy your own token");

        // The buyer must have enough IGToken
        require(igToken.balanceOf(msg.sender) >= price, "Insufficient IGToken balance");
        // The buyer must have approved this contract to spend the IGT
        require(igToken.allowance(msg.sender, address(this)) >= price, "Check the token allowance");

        // Transfer the IGToken from the buyer to the seller
        igToken.transferFrom(msg.sender, seller, price);
        
        // Remove the item from the sale list
        delete itemPrices[tokenId];
        
        // Transfer the NFT to the buyer
        _transfer(seller, msg.sender, tokenId);
        
        emit Sold(tokenId, price, seller, msg.sender);
    }

    // The following functions are overrides required by Solidity for multiple inheritance.
    
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}