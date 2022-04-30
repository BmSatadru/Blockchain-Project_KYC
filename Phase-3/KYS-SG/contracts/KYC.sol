// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;
import './Admincontrolled.sol';
contract KYC is admincontrolled{
    address admin;

    
    struct Customer {
        string userName;   
        string data; 
        bool kycStatus;
        uint Downvotes;
        uint Upvotes;
        address bank;
    }
    
    struct Bank {
        string name;
        address ethAddress;
        uint complaintsReported;
        uint KYC_count;
        bool isAllowedToVote;
        bool isAllowedToDoKYC;
        string regNumber;
    }

    struct KYC_Request {
        string uName ;
        address bankAddress;
        string customerData;
    }

    mapping(string => Customer) customers;
    mapping(address => Bank) banks;
    mapping(string => KYC_Request) kyc;
    
    
    constructor() admincontrolled(msg.sender, false) {

    }

    //                       ------ Bank Interface ------

    //only verified banks, added by admin, can add request for customers
    function addRequest(string memory _customerName, string memory _customerData) public returns(bool){
        require(banks[msg.sender].isAllowedToDoKYC == true);
        kyc[_customerName].uName = _customerName;
        kyc[_customerName].bankAddress = msg.sender;
        kyc[_customerName].customerData = _customerData;
        return true;
    }
    /*only verified banks, added by admin, can add customers' data
     
    Before adding the customer data, the check is required that those customers were added to 
    request list or not
    
    Initially when a customer added by a bank, that customer will already be upvoted by that bank. */
    function addCustomer(string memory _userName, string memory _customerData) public {
        require(banks[msg.sender].isAllowedToDoKYC == true);
        require(kyc[_userName].bankAddress != address(0), "Customer is not present in the request list");
        banks[msg.sender].KYC_count +=1;
        require(customers[_userName].bank == address(0), "Customer is already present, please call modifyCustomer to edit the customer data");
        customers[_userName].userName = _userName;
        customers[_userName].data = _customerData;
        customers[_userName].bank = msg.sender;
        customers[_userName].Upvotes = 1;
        customers[_userName].Downvotes = 0;
        customers[_userName].kycStatus = true;
        
    }
    //only verified banks, added by admin, can remove request for customers
    function RemoveRequest(string memory _CustomerName) public returns(bool){
        require(banks[msg.sender].isAllowedToDoKYC == true);
        delete kyc[_CustomerName];
        return true;
    }
    // only verified banks can view customer's data
    function viewCustomer(string memory _userName) public view returns (string memory, string memory, address, bool, uint, uint) {
        require(banks[msg.sender].isAllowedToDoKYC == true);
        require(customers[_userName].bank != address(0), "Customer is not present in the database");
        return (customers[_userName].userName, customers[_userName].data, customers[_userName].bank, 
                customers[_userName].kycStatus, customers[_userName].Upvotes, 
                customers[_userName].Downvotes);
    }
    // A bank can not do both the Downvote & Upvote for the same customer
    // A bank can upvote or downvote only once for a particular customer
    struct upVoteGiver{
        
        address bankUpvoted;
        address bankUpVotedOnce;
    }
    mapping (string => upVoteGiver) listOfUpVoteGiverBanks;
    function upVoteCustomer(string memory CUSTOMER_Name) public returns(bool){
        require(banks[msg.sender].isAllowedToDoKYC == true );
        require(banks[msg.sender].isAllowedToVote == true);
        require(listOfDownVoteGiverBanks[CUSTOMER_Name].bankDownvoted != msg.sender, "This bank has downvoted");
        require(listOfUpVoteGiverBanks[CUSTOMER_Name].bankUpVotedOnce != msg.sender, "This bank has already upvoted");
        customers[CUSTOMER_Name].Upvotes +=1;
        listOfUpVoteGiverBanks[CUSTOMER_Name].bankUpvoted = msg.sender; 
        listOfUpVoteGiverBanks[CUSTOMER_Name].bankUpVotedOnce = msg.sender;
        return true;
    }
    struct downVoteGiver{
        address bankDownvoted;
        address bankDownVotedOnce;
    }
    mapping (string => downVoteGiver) listOfDownVoteGiverBanks;
    function downVoteCustomer(string memory _customerName) public returns(bool){
        require(banks[msg.sender].isAllowedToDoKYC == true);
        require(banks[msg.sender].isAllowedToVote == true);
        require(listOfUpVoteGiverBanks[_customerName].bankUpvoted != msg.sender, "This bank has upvoted");
        require(listOfDownVoteGiverBanks[_customerName].bankDownVotedOnce != msg.sender, "This Bank has already downvoted");
        while(customers[_customerName].Downvotes >= 0){
            customers[_customerName].Downvotes -=1;
            listOfDownVoteGiverBanks[_customerName].bankDownvoted = msg.sender;
        }
        listOfDownVoteGiverBanks[_customerName].bankDownvoted = msg.sender; 
        listOfDownVoteGiverBanks[_customerName].bankDownVotedOnce = msg.sender;
        
        return true;
    }
    // If needed customer information can be edited, in that case no of & downvotes will be restored.
    function modifyCustomer(string memory _user_Name, string memory _newcustomerData) public {
        require(banks[msg.sender].isAllowedToDoKYC == true);
        require(customers[_user_Name].bank != address(0), "Customer is not present in the database");
        customers[_user_Name].data = _newcustomerData;
        customers[_user_Name].Upvotes = 1;
        customers[_user_Name].Downvotes = 0;
        customers[_user_Name].kycStatus = true;
    }   
    // A bank can report against other bank if situation arised 
    function reportBank(address Bank_Address) public returns(bool){
        require(banks[msg.sender].isAllowedToDoKYC == true);
        require(isKycGoing == true, "KYC process is closed");

        banks[Bank_Address].complaintsReported +=1;
        return true;
    }
    // Only admin can see the number of complaints for a bank, done by other banks
    function getBankComplaints(address _BankAddress) public onlyOwner view returns(uint){
        return banks[_BankAddress].complaintsReported;
    }
    // Any bank can see KYC status of a customer
    function kycStatusOfCustomer(string memory _customer_NAME) public returns(bool){
        require(banks[msg.sender].isAllowedToDoKYC == true);
        uint m;
        m = (customers[_customer_NAME].Upvotes) - (customers[_customer_NAME].Downvotes);
        if(m>0){
            customers[_customer_NAME].kycStatus = false;
        return customers[_customer_NAME].kycStatus;
        }
    }
    // If admin wants, he/she can see Bank details
    event _viewBankDetails(string Name,address bank, uint NoOfComplaints, uint NoOfKYC_Count, bool isBankAllowedToDoKYC, bool isBankAllowedToVote, string BankRegNo);
    function viewBankDetails(address _bankADDRESS) public onlyOwner returns(bool){
        emit _viewBankDetails(banks[_bankADDRESS].name, banks[_bankADDRESS].ethAddress, banks[_bankADDRESS].complaintsReported, banks[_bankADDRESS].KYC_count, banks[_bankADDRESS].isAllowedToDoKYC, banks[_bankADDRESS].isAllowedToVote, banks[_bankADDRESS].regNumber );
        
    }

    /* Only admin can call the function to remove a bank, the bank will be removed on the 
     basis of certain conditions. One condition is - if number of complaints are greater than half
     of the total number of banks, 2nd Condition is- if number of upvotes is less than the number of
     downvotes of a customer's KYC then the bank which enrolled the customer will be removed.

     
    */
    function removeBankOnTheBasisOfReport(address BankAddress) public onlyOwner returns(bool){
        if(bankCount>1){  // if number of banks in the network is greater than 1 then we can proceed
            if(banks[BankAddress].complaintsReported >= (bankCount/2)){
                banks[BankAddress].isAllowedToDoKYC = false;
            }
        }
        
        
        return true;
    }
    function removeBankOnTheBasisOfCustomerUpVote(string memory customer_NAME)public returns(bool){
        if(bankCount>1){ // if number of banks in the network is greater than 1 then we can proceed
            uint n;
            n = (customers[customer_NAME].Upvotes) - (customers[customer_NAME].Downvotes);
            if(n<0){
                address a;
                a = customers[customer_NAME].bank;
                banks[a].isAllowedToDoKYC = false;
            }
        }
        
        return true;
    }
    
    
    //                                ----- Admin Interface -------
    // Only Admin can start the whole process
    function startKyc() external onlyOwner returns(bool){
        require(!isKycGoing, "Kyc process is already open");
        isKycGoing = true;
        return true;
    }
    // Similarly admin can end the KYC process
    function stopKyc() external onlyOwner returns(bool){
        require(isKycGoing, "Kys process is CLOSED");
        isKycGoing = false;
        return true;
    }

    uint bankCount = 0;
    function addBank(string memory _bankName, address _bankAddress, string memory _bankRegNo) external onlyOwner returns(bool){
        require(isKycGoing == true, "KYC process is closed");
        bool isAddedToBankListFlag = false;
        banks[_bankAddress].ethAddress = _bankAddress;
        banks[_bankAddress].name = _bankName;
        banks[_bankAddress].regNumber = _bankRegNo;
        banks[_bankAddress].complaintsReported = 0;
        banks[_bankAddress].KYC_count = 0;
        banks[_bankAddress].isAllowedToVote = true; // If admin wants she can remove the bank from the list
        banks[_bankAddress].isAllowedToDoKYC = true; // admin can prohibit the bank to upvote or downvote
        isAddedToBankListFlag = true;
        if(isAddedToBankListFlag == true){
            bankCount = bankCount+1; // will give the number of banks onboarded by the admin
        }
        return true;
    }
    // can give the number of banks onboarded by the admin
    function modifyIsAllowedToVote(address bankAddress) external onlyOwner returns(bool) {
        require(isKycGoing == true, "KYC process is closed");
        banks[bankAddress].isAllowedToVote = false;
        return true;
    }
    // admin can remove the bank
    function removeBank(address bank_Address) external onlyOwner returns(bool) {
        require(isKycGoing == true, "KYC process is closed");
        bool isRemovedFromBankListFlag = false;
        delete banks[bank_Address];
        return isRemovedFromBankListFlag;
    }    
}    


