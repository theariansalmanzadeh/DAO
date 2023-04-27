// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


// 1.contributes investing
// 2.send get shares back
// 3.transfer shares
// 4.invest in a project
// 5.send shares to the project

contract DAO{

    struct ProjectProposal{
        bytes32 id;
        uint totalAmount;
        string name;
        address payable contractAddress;
        bool isExecuted;
        uint votingDeadline;
        uint voters;
    }

    mapping(address=>bool) public isInvestor;
    mapping(address=>uint) public investorFunds;
    mapping (bytes32=>ProjectProposal) AllProjects;
    mapping(bytes32=>mapping(address=>bool)) projectInvestedByVoter;
    mapping(bytes32=>mapping(address=>uint)) projectInvestedAmountVoter;
    mapping(address =>bytes32) addressToprojectInvested;
    mapping(bytes32 => bool) projectInvested;
    mapping(bytes32 => bool) projectProsed;
    
    address public admin;
    
    uint public totalShares;
    uint public avalaibleShares;
    uint public persentageVote;
    uint public contirbiutionTime;

    modifier onlyInvestor(){
        require(isInvestor[msg.sender] , "not a investor");
        _;
    }

    modifier isNotInvestor(){
        require(isInvestor[msg.sender] == false , "not a investor");
        _;
    }

    modifier investorFundAvailable(uint amount){
        require(investorFunds[msg.sender] >= amount , "not sufficinet fund");
        _;
    }

    modifier contributionTime(){
        require(block.timestamp < contirbiutionTime , "patrticipation time passed");
        _;
    }

    //////////////////////////////////////////////////////////////////

    constructor(uint _persentageVote,uint _contirbiutionTime){
        require(_persentageVote > 0 && _persentageVote>100 ,"percentage not accepted");
        
        persentageVote = _persentageVote;

        contirbiutionTime = block.timestamp + _contirbiutionTime;

        admin = msg.sender;
    }

    function contribute() external payable isNotInvestor{

        investorFunds[msg.sender] += msg.value;

        totalShares += msg.value;

        avalaibleShares += msg.value;

        isInvestor[msg.sender] = true;
    }

    function withdrawAllShares()external{
        require(investorFunds[msg.sender] >0 , "insufficient fund");

        uint amount = investorFunds[msg.sender];
        
        isInvestor[msg.sender] = false;

        _transferEther(amount ,payable(msg.sender));

    }

    function transferShares(address from ,address to ,uint amount)external 
    onlyInvestor 
    investorFundAvailable(amount) 
    contributionTime{

        if(!isInvestor[to]){
            isInvestor[to] = true;
        }
        if(investorFunds[from] == amount){
            isInvestor[from] = false;
        }

        investorFunds[from] -=amount;

        investorFunds[to] +=amount;
    }

    function _transferEther(uint amount,address payable to)internal {
        to.transfer(amount);
    }

    function proposeProject(string memory name , uint _amount,uint deadline ,address payable _address)onlyInvestor external {

        bytes32 id = keccak256(abi.encode(name));

        require(projectInvested[id] == false, "project was proposed");

        ProjectProposal memory projectProposal = ProjectProposal(id ,_amount ,name ,_address
                                                                ,false ,block.timestamp + deadline ,0);

        AllProjects[id] = projectProposal;
        projectProsed[id] = true;

    }

    function investProject(string memory name,uint _share)onlyInvestor investorFundAvailable(_share) external {
        bytes32 id = keccak256(abi.encode(name));

        require(projectProsed[id] , "no project is proposed");
        require(AllProjects[id].votingDeadline > block.timestamp,"time for investing passed");
        require(AllProjects[id].isExecuted ==false,"time for investing passed");

        ProjectProposal memory project = AllProjects[id];

        project.voters += _share;

        avalaibleShares -=_share;

        projectInvestedByVoter[project.id][msg.sender] = true;
        projectInvestedAmountVoter[project.id][msg.sender] = _share;

    }

    function executeProposal(string memory name)public{
        bytes32 id = keccak256(abi.encode(name));

        require(projectProsed[id] , "no project is proposed");
        require(AllProjects[id].votingDeadline <= block.timestamp,"time for investing passed");
        require(AllProjects[id].isExecuted == false,"time for investing passed");
        require(AllProjects[id].totalAmount <= AllProjects[id].voters,"time for investing passed");
        require(AllProjects[id].voters <= avalaibleShares,"time for investing passed");

        AllProjects[id].contractAddress.transfer(AllProjects[id].voters);

        AllProjects[id].isExecuted = true;
    }

}
