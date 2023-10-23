// SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

//INTERNAL IMPORT FOR NFT OPENZIPLINE
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage{
    using Counters for Counters.Counter;

    Counters.Counter  private _tokenIds;
    Counters.Counter  private _itemsSold;

    address payable owner;
    uint listingPrice=0.0015 ether;

    mapping (uint256 =>MarketItem) private idMarketItem;
    struct MarketItem{
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event idMarketItemCreated(
        uint256 indexedtokenId,
        address payable seller,
        address payable owner,
        uint256 price,
        bool sold 
    );

    modifier onlyOwner{
        require(
            msg.sender==owner,"only owner of nftMarketPlace can update the listing price"
        );
        _;
    }

    constructor() ERC721("NFT Metavarse Token","MYNFT"){
        owner=payable(msg.sender);
    }

    
    function updateListingPrice(uint256 _listingPrice)public payable onlyOwner{
        listingPrice=_listingPrice;    
    }

    function getListingPrice() public view returns(uint256){
        // view keyword to see listingprice which is a state variable
            return listingPrice;
    }

    //listing of nft(nft ownership remain with contract till it is sold)
    function createToken(string memory tokenURI ,uint256 price)public payable returns(uint256) {
        _tokenIds.increment();

        uint256 newTokenId=_tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId,tokenURI);
        createMarketItem(newTokenId,price);

        return newTokenId;
    }

    function createMarketItem(uint256 tokenId,uint256 price)private{
        require(price>0,"Price must be atleast one");
        require(msg.value==listingPrice,"Price must be equal to listing price" );
        idMarketItem[tokenId]=MarketItem(
            tokenId,
            payable(msg.sender),//who is creating nft
            payable(address(this)),//this is address of owner
            // address(this)  refers to smart contract itself
            price,
            false
        );
        _transfer(msg.sender, address(this), tokenId);
        //used to send ether 

        emit idMarketItemCreated(tokenId, payable(msg.sender),payable(address(this)),price,false);
        // initial value assigned
             
    }


    //Function for resale of nft
    function resaleNft(uint256 tokenId,uint256 price)public payable{
        require(idMarketItem[tokenId].owner==msg.sender,"Only owner of nft can resle it" );
        require(msg.value==listingPrice,"Price msut be equal to listing price");
        idMarketItem[tokenId].sold=false;
        idMarketItem[tokenId].price=price;
        idMarketItem[tokenId].seller=payable(msg.sender);
        idMarketItem[tokenId].owner=payable(address(this));

        _itemsSold.decrement();
        _transfer(msg.sender,address(this),tokenId);
    }

    //function createMarketSale
    function createMarketSale(uint256 tokenId)public payable {
        uint256 price=idMarketItem[tokenId].price;
        require(msg.value==price,"Please submit the asking money to complete the purchase");
        idMarketItem[tokenId].owner=payable(msg.sender);
        idMarketItem[tokenId].sold=true;
        idMarketItem[tokenId].owner=payable(address(0));

        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }

    //getting unsold nft data that user can buy
    function fetchMarketItem()public view returns(MarketItem[] memory){
        uint256 itemCount=_tokenIds.current();
        uint256 unsoldItemCount=_tokenIds.current()-_itemsSold.current();
        uint256 currentIndex=0;

        MarketItem[] memory items=new MarketItem[](unsoldItemCount);
        for(uint256 i=0;i<itemCount;i++){
            if(idMarketItem[i+1].owner==address(this)){
                uint currentId=i+1;

                MarketItem memory currentItem=idMarketItem[currentId];//he used storage
                items[currentIndex]=currentItem;
            }
        }
        return items;
    }

    //purchased item
    function fetchMyNft() public view returns(MarketItem[] memory){
        uint256 totalCount=_tokenIds.current();
        uint currentId=0;
        uint itemCount=0;

        for(uint i=0;i<totalCount;i++){
            if(idMarketItem[i+1].owner==msg.sender){
                itemCount+=1;
            }
        }

        MarketItem[] memory items=new MarketItem[](itemCount);
        for(uint i=0;i<totalCount;i++){
            if(idMarketItem[i+1].owner==msg.sender){
                MarketItem memory currentItem=idMarketItem[i+1];
                items[currentId]=currentItem;
            }
        }
        return items;
    }

    //single user item that he has listed
    function fetchItemsListed() public view returns(MarketItem[] memory){
        uint256 totalCount=_tokenIds.current();
        uint currentId=0;
        uint itemCount=0;

        for(uint i=0;i<totalCount;i++){
            if(idMarketItem[i+1].seller==msg.sender){
                itemCount+=1;
            }
        }

        MarketItem[] memory items=new MarketItem[](itemCount);
        for(uint i=0;i<totalCount;i++){
            if(idMarketItem[i+1].seller==msg.sender){
                MarketItem memory currentItem=idMarketItem[i+1];
                items[currentId]=currentItem;
            }
        }
        return items;
    }



}




//when nft is listed the token is transferred to contract and when buy happens it go to person making the purchase from the contract