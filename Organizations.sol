pragma solidity >=0.4.21 <0.6.0;

contract Organizations {
    struct Member {
        bool valid;
        mapping (bytes32 => bool) endorsements;
    }

    struct Organization {
        bool valid;
        address founder;
        uint pledge;
        uint dues;
        string name;
        string intro;
        mapping (address => Member) members;
        uint funds;
    }

    struct Application {
        bool valid;
        uint dues;
        bool rejected;
    }

    address public lord;
    uint public minPledge;
    mapping (bytes32 => Organization) public organizations;
    mapping (bytes32 => mapping (address => Application)) public applications;
    uint nonce;

    event Create(
        bytes32 indexed orgID, 
        address indexed founder,
        uint pledge,
        uint dues,
        string name,
        string intro
    );

    event Dismiss(bytes32 indexed orgID);

    event JoinApply(
        bytes32 indexed orgID,
        address indexed applicant,
        uint dues,
        string words
    );

    event CancelApplication(bytes32 indexed orgID, address indexed applicant);

    event ApproveApplication(bytes32 indexed orgID, address indexed applicant);

    event RejectApplication(bytes32 indexed orgID, address indexed applicant, string words);

    event Exit(bytes32 indexed orgID, address indexed applicant);

    event Expel(bytes32 indexed orgID, address indexed applicant);

    event AddEndorsement(bytes32 indexed orgID, address indexed member, bytes32 hash);

    event RemoveEndorsement(bytes32 indexed orgID, address indexed member, bytes32 hash);

    event SetDues(bytes32 indexed orgID, uint dues);

    event SetName(bytes32 indexed orgID, string name);

    event SetIntro(bytes32 indexed orgID, string intro);

    modifier founderOnly(bytes32 orgID) {
        require(
            organizations[orgID].valid,
            "Organization does not exist."
        );
        require(
            organizations[orgID].founder == msg.sender,
            "Permission denied. Founder only."
        );
        _;
    }

    modifier memberOnly(bytes32 orgID) {
        require(
            organizations[orgID].members[msg.sender].valid,
            "Permission denied. Member only."
        );
        _;
    }

    modifier applicantOnly(bytes32 orgID) {
        require(
            applications[orgID][msg.sender].valid,
            "Permission denied. Applicant only."
        );
        _;
    }

    modifier applicationValid(bytes32 orgID, address applicant) {
        Application storage app = applications[orgID][applicant];
        require(app.valid, "Application does not exist.");
        require(!app.rejected, "Application has been rejected.");
        _;
    }

    constructor(uint pledge) public {
        lord = msg.sender;
        minPledge = pledge;
    }

    function create(uint dues, string memory name, string memory intro)
        public payable
        returns (bytes32 orgID)
    {
        require(msg.value >= minPledge, "Insufficient pledge.");

        orgID = genID();
        require(!organizations[orgID].valid, "Duplicate organization ID.");

        emit Create(orgID, msg.sender, msg.value, dues, name, intro);

        organizations[orgID] = Organization({
            valid: true,
            founder: msg.sender,
            pledge: msg.value,
            dues: dues,
            name: name,
            intro: intro,
            funds: 0
        });
        organizations[orgID].members[msg.sender] = Member({ valid: true });

        return orgID;
    }

    function dismiss(bytes32 orgID) public founderOnly(orgID) {
        emit Dismiss(orgID);

        Organization storage org = organizations[orgID];
        uint pledge = org.pledge;
        uint funds = org.funds;

        delete organizations[orgID];

        msg.sender.transfer(pledge + funds);
    }

    function withdraw(bytes32 orgID, uint value) public founderOnly(orgID) {
        require(organizations[orgID].funds >= value, "Insufficient funds.");

        organizations[orgID].funds -= value;

        msg.sender.transfer(value);
    }

    function joinApply(bytes32 orgID, string memory words) public payable {
        Organization storage org = organizations[orgID];

        require(org.valid, "Organization does not exist.");
        require(!org.members[msg.sender].valid, "Already joined in.");
        require(msg.value >= org.dues, "Insufficient dues.");
        require(!applications[orgID][msg.sender].valid, "Duplicate application.");

        emit JoinApply(orgID, msg.sender, msg.value, words);

        applications[orgID][msg.sender] = Application({
            valid: true,
            dues: msg.value,
            rejected: false
        });
    }

    function cancelApplication(bytes32 orgID) public applicantOnly(orgID) {
        emit CancelApplication(orgID, msg.sender);

        uint dues = applications[orgID][msg.sender].dues;

        delete applications[orgID][msg.sender];

        msg.sender.transfer(dues);
    }

    function approveApplication(bytes32 orgID, address applicant)
        public
        founderOnly(orgID)
        applicationValid(orgID, applicant)
    {
        emit ApproveApplication(orgID, applicant);

        Organization storage org = organizations[orgID];
        Application storage app = applications[orgID][applicant];
        org.members[applicant] = Member({ valid: true });
        org.funds += app.dues;
        delete applications[orgID][applicant];
    }

    function rejectApplication(bytes32 orgID, address applicant, string memory words)
        public
        founderOnly(orgID)
        applicationValid(orgID, applicant)
    {
        emit RejectApplication(orgID, applicant, words);

        applications[orgID][applicant].rejected = true;
    }

    function exit(bytes32 orgID) public memberOnly(orgID) {
        Organization storage org = organizations[orgID];
        require(org.founder != msg.sender, "Permission denied. Call dismiss instead.");

        emit Exit(orgID, msg.sender);

        delete org.members[msg.sender];
    }

    function expel(bytes32 orgID, address member) public founderOnly(orgID) {
        Organization storage org = organizations[orgID];
        require(org.members[member].valid, "Member does not exist.");
        require(org.founder != member, "Permission denied. Call dismiss instead.");

        emit Expel(orgID, member);

        delete org.members[member];
    }

    function checkMember(bytes32 orgID, address member) public view returns (bool ok) {
        return organizations[orgID].members[member].valid;
    }

    function addEndorsement(bytes32 orgID, address member, bytes32 hash)
        public
        founderOnly(orgID)
    {
        Organization storage org = organizations[orgID];
        require(org.members[member].valid, "Member does not exist.");

        require(
            !organizations[orgID].members[member].endorsements[hash],
            "Duplicate endorsement."
        );

        emit AddEndorsement(orgID, member, hash);

        organizations[orgID].members[member].endorsements[hash] = true;
    }

    function removeEndorsement(bytes32 orgID, address member, bytes32 hash)
        public
        founderOnly(orgID)
    {
        Organization storage org = organizations[orgID];
        require(org.members[member].valid, "Member does not exist.");

        require(
            organizations[orgID].members[member].endorsements[hash],
            "Endorsement does not exist."
        );

        emit RemoveEndorsement(orgID, member, hash);

        delete organizations[orgID].members[member].endorsements[hash];
    }

    function checkEndorsement(bytes32 orgID, address member, bytes32 hash)
        public view
        returns (bool ok)
    {
        return organizations[orgID].members[member].endorsements[hash];
    }

    function setDues(bytes32 orgID, uint dues) public founderOnly(orgID) {
        emit SetDues(orgID, dues);

        organizations[orgID].dues = dues;
    }

    function setName(bytes32 orgID, string memory name) public founderOnly(orgID) {
        emit SetName(orgID, name);

        organizations[orgID].name = name;
    }

    function setIntro(bytes32 orgID, string memory intro) public founderOnly(orgID) {
        emit SetIntro(orgID, intro);

        organizations[orgID].intro = intro;
    }

    function genID() internal returns (bytes32) {
        nonce += 1;
        return keccak256(abi.encodePacked(nonce, msg.sender, blockhash(block.number)));
    }
}
