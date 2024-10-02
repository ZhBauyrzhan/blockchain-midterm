// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract AIModelMarketplace {
    
    struct AIModel {
        string name;
        string description;
        address payable creator;
        uint256 price; // Price in wei (1 ether = 10^18 wei)
        uint256 ratingSum;
        uint256 ratingCount;
    }

    mapping(uint256 => AIModel) public models;
    mapping(address => uint256[]) public purchasedModels;
    uint256 public modelCount = 0;
    uint256 public totalFunds;
    address public owner;  
    
    constructor() {
        owner = msg.sender;  
    }

    // Event emitted when a new model is listed
    event ModelListed(uint256 modelId, string name, string description, uint256 price, address creator);

    // Event emitted when a model is purchased
    event ModelPurchased(uint256 modelId, address buyer);

    // Event emitted when a model is rated
    event ModelRated(uint256 modelId, uint8 rating, address rater);

    // Allows users to list a new model on the marketplace
    function listModel(string memory name, string memory description, uint256 price) public {
        require(price > 0, "Price must be greater than zero");

        models[modelCount] = AIModel({
            name: name,
            description: description,
            creator: payable(msg.sender),
            price: price,
            ratingSum: 0,
            ratingCount: 0
        });

        emit ModelListed(modelCount, name, description, price, msg.sender);
        modelCount++;
    }

    // Allows users to purchase a model by ID using Ether
    function purchaseModel(uint256 modelId) public payable {
        AIModel storage model = models[modelId];
        require(msg.value == model.price, "Incorrect Ether amount sent");

        // Transfer payment (Ether) to the model creator
        model.creator.transfer(msg.value);
        
        // Store the purchase information
        purchasedModels[msg.sender].push(modelId);

        emit ModelPurchased(modelId, msg.sender);
    }

    // Allows users to rate a purchased model
    function rateModel(uint256 modelId, uint8 rating) public {
        require(rating >= 1 && rating <= 5, "Rating should be between 1 and 5");
        
        bool hasPurchased = false;
        for (uint256 i = 0; i < purchasedModels[msg.sender].length; i++) {
            if (purchasedModels[msg.sender][i] == modelId) {
                hasPurchased = true;
                break;
            }
        }
        require(hasPurchased, "You must purchase the model to rate it");

        AIModel storage model = models[modelId];
        model.ratingSum += rating;
        model.ratingCount++;

        emit ModelRated(modelId, rating, msg.sender);
    }

    // Allows the contract owner to withdraw accumulated funds from the contract
    function withdrawFunds() public {
        require(msg.sender == owner, "Only the contract owner can withdraw funds"); 
        uint256 amount = address(this).balance;
        require(amount > 0, "No funds available"); 

        payable(msg.sender).transfer(amount);  
    }

    // Retrieves the details of a specific model
    function getModelDetails(uint256 modelId) public view returns (string memory, string memory, address, uint256, uint256, uint256) {
        AIModel memory model = models[modelId];
        return (model.name, model.description, model.creator, model.price, model.ratingSum, model.ratingCount);
    }

    // Fallback function to handle any ether sent to the contract without function call
    receive() external payable {}
}
