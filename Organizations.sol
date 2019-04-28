pragma solidity >=0.4.21 <0.6.0;

contract Organizations {
    struct Member {
        address addr;
        mapping (string => bool) endorsements;
    }

    struct Organization {
        bytes32 id;
        address founder;
        uint pledge;
        uint dues;
        string name;
        string intro;
        mapping (address => Member) members;
        uint funds;
    }

    struct Application {
        bytes32 orgID;
        address applicant;
        uint dues;
    }

    address lord;
    uint minPledge;
    mapping (bytes32 => Organization) organizations;
    mapping (bytes32 => Application) applications;
    uint nonce;

    modifier founderOnly(bytes32 orgID) {
        require(
            organizations[orgID].founder == msg.sender,
            "Permission denied. Founder only."
        );
        _;
    }

    modifier memberOnly(bytes32 orgID) {
        require(
            organizations[orgID].members[msg.sender].addr == msg.sender,
            "Permission denied. Member only."
        );
        _;
    }

    modifier applicantOnly(bytes32 appID) {
        require(
            applications[appID].applicant == msg.sender,
            "Permission denied. Applicant only."
        );
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
        require(organizations[orgID].founder == address(0), "Duplicate organization ID.");

        organizations[orgID] = Organization({
            id: orgID,
            founder: msg.sender,
            pledge: msg.value,
            dues: dues,
            name: name,
            intro: intro,
            funds: 0
        });
        organizations[orgID].members[msg.sender] = Member({ addr: msg.sender });

        return orgID;
    }

    function dismiss(bytes32 orgID) public founderOnly(orgID) {
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

    function applyJoin(bytes32 orgID, string memory words)
        public payable
        returns (bytes32 appID)
    {
        Organization storage org = organizations[orgID];

        require(org.founder != address(0), "Organization does not exist");
        require(org.members[msg.sender].addr == address(0), "Already joined in.");
        require(msg.value >= org.dues, "Insufficient dues.");

        appID = genID();
        require(applications[appID].applicant == address(0), "Duplicate application ID.");

        applications[appID] = Application({
            orgID: orgID,
            applicant: msg.sender,
            dues: msg.value
        });

        return appID;
    }

    function cancelApplication(bytes32 appID) public applicantOnly(appID) {
        uint dues = applications[appID].dues;

        delete applications[appID];

        msg.sender.transfer(dues);
    }

    function auditApplication(bytes32 appID) public {
        Application storage app = applications[appID];
        require(app.applicant != address(0), "Application does not exist");

        Organization storage org = organizations[app.orgID];
        require(org.founder == msg.sender, "Permission denied. Founder only.");
        require(org.members[app.applicant].addr == address(0), "Already joined in.");

        org.members[app.applicant] = Member({ addr: app.applicant });
        org.funds += app.dues;
        delete applications[appID];
    }

    // TODO: emit refuse event

    function exit(bytes32 orgID) public memberOnly(orgID) {
        Organization storage org = organizations[orgID];
        require(org.founder != msg.sender, "Permission denied. Call dismiss instead.");

        delete org.members[msg.sender]; // TODO: check
    }

    function expel(bytes32 orgID, address member) public founderOnly(orgID) {
        require(member != address(0), "Invalid member.");

        Organization storage org = organizations[orgID];
        require(org.members[member].addr == member, "Member does not exist.");
        require(org.founder != member, "Permission denied. Call dismiss instead.");

        delete org.members[member];
    }

    function isMember(bytes32 orgID, address addr) public view returns (bool) {
        require(addr != address(0), "Invalid addr.");

        return organizations[orgID].members[addr].addr == addr;
    }

    function getInfo(bytes32 orgID)
        public view
        returns (
            bytes32 id,
            address founder,
            uint pledge,
            uint dues,
            string memory name,
            string memory intro,
            uint funds
        )
    {
        require(organizations[orgID].founder != address(0), "Organization does not exist.");

        Organization storage org = organizations[orgID];
        return (
            org.id,
            org.founder,
            org.pledge,
            org.dues,
            org.name,
            org.intro,
            org.funds
        );
    }

    function setDues(bytes32 orgID, uint dues) public founderOnly(orgID) {
        organizations[orgID].dues = dues;
    }

    function setName(bytes32 orgID, string memory name) public founderOnly(orgID) {
        organizations[orgID].name = name;
    }

    function setIntro(bytes32 orgID, string memory intro) public founderOnly(orgID) {
        organizations[orgID].intro = intro;
    }

    function genID() internal returns (bytes32) {
        nonce += 1;
        return keccak256(abi.encodePacked(nonce, msg.sender, blockhash(block.number)));
    }
}
