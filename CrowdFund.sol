//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;
// block.timestamp is inbuild function for current time UNIX and in seconds
// msg.sender is the adrress of the user
// msg.value is the value the sender passes 
contract CrowdFunding{
    mapping(address=>uint) public contributors;
    address public  manager;
    uint public minContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors; 

    struct Request{
        string description;
        address payable recipent;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }

    mapping(uint => Request) public requests;
    uint public numRequests; 

    constructor(uint _target, uint _deadline){
        target = _target;
        deadline = block.timestamp + _deadline;
        minContribution = 100 wei;
        manager = msg.sender; // we are making 1st user as manager
    }

    function sendEth() public payable{
        require (block.timestamp < deadline, "Deadline has passed");  // see it the deadline is passed or not
        require (msg.value >= minContribution , "Minimum contribution is not met");
          
          if(contributors[msg.sender]==0){ // if 1st time user , increase noofContributor
              noOfContributors++;
          }
          contributors[msg.sender]+=msg.value;
          raisedAmount += msg.value;
    }

    function getContractBalance() public view returns (uint){
         return address(this).balance;
    }

    function refund() public {
        require(block.timestamp > deadline  && raisedAmount<target,"You are not eligible for refund");
        require(contributors[msg.sender]>0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        noOfContributors--;
        raisedAmount-=contributors[msg.sender];
        contributors[msg.sender] = 0;

    }
     
     modifier onlyManager(){
         require(msg.sender == manager , "Only manager can access");
         _;
     }

    function createRequest(string memory _description, address payable _recipient , uint _value ) public  onlyManager{
      Request storage newRequest = requests[numRequests];
      numRequests++;
      newRequest.description = _description;
      newRequest.value = _value;
      newRequest.recipent = _recipient;
      newRequest.completed = false;
      newRequest.noOfVoters = 0;
    }

    function voteRequest(uint _requestNo ) public{
        require(contributors[msg.sender]>0, "you must be a contributors");
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.voters[msg.sender] ==false ,"You ahave already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false,"The request has been completed");
        require(thisRequest.noOfVoters>noOfContributors/2,"Majority doesnot supports");
        thisRequest.recipent.transfer(thisRequest.value);
        thisRequest.completed = true;
 }
}
