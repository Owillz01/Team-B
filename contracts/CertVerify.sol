pragma solidity >=0.5.0 < 0.6.0;

import "./Ownable.sol";

contract CertVerify is Ownable {
    
    uint public maxAdmins;
    uint public adminIndex = 0;
    uint public studentIndex = 0;
    
    enum assignmentStatus { 
        Inactive,
        Pending,
        Completed
    }
    
    enum grades { 
        Good, 
        Great, 
        Outstanding, 
        Epic, 
        Legendary
    }
    
    struct Admin {
        bool authorized;
        uint Id;
    }
    
    struct Assignment {
        string link;
        bytes32 assignmentStatus;
    }
    
    struct Student {
        bytes32 firstName;
        bytes32 lastName;
        bytes32 commendation;
        bytes32 grades;
        uint16 assignmentIndex;
        bool active;
        string email;
        uint16 assignments;
    }
    
    mapping(address => Admin) public admins;
    mapping(uint => address) public adminsReverseMapping;
    mapping(uint => Student) public students;
    mapping(string => uint) public studentsReverseMapping;
    
    modifier onlyAdmins() {
        require(admins[msg.sender].authorized = true, "Only admins allowed");
        _;
    }
    
    modifier onlyNonOwnerAdmins(address _addr) {
        require(_addr != owner(), "only none-owner admin");
        _;
    }
    
    modifier onlyPermissibleAdminLimit() {
        require(adminIndex <= 1, "Maximum admins already");
        _;
    }
    
    modifier onlyNonExistentStudents(string memory _email) {
        require(keccak256(abi.encodePacked(students[studentsReverseMapping[_email]].email)) 
        != keccak256(abi.encodePacked(_email)), "Email already exist");
        _;
    }
   
    modifier onlyValidStudents(string memory _email)  {
        require(keccak256(abi.encodePacked(students[studentsReverseMapping[_email]].email)) 
        == keccak256(abi.encodePacked(_email)), "Email does not exist");
        _;
   }
    
   event AdminAdded(address _newAdmin, uint indexed _maxAdminNum);
    event AdminRemoved(address _newAdmin, uint indexed _maxAdminNum);
    event AdminLimitChanged(uint _newAdminLimit);
    event addStudent(bytes32 _firstName, bytes32 _lastName, bytes32 _commendation, grades _grades, string memory _email)
    event StudentRemoved(string _email);
    event StudentNameUpdated(string _email, string _newFirstName, string _newLastName);
    event StudentCommendationUpdated(string _email, string _newCommendation);
    event StudentGradeUpdated(string _email, uint _studentGrade);
    event StudentEmailUpdated(string _oldEmail, string _newEmail);
    // event AssignmentAdded(string _studentEmail, string _newEmail);
    event AssignmentUpdated(string _studentEmail, uint indexed _assignmentIndex, string _status);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        maxAdmins = 2;
        _addAdmin(msg.sender);
    }
    
    function addAdmin(address _newAdmin) public onlyOwner onlyPermissibleAdminLimit {
        _addAdmin(_newAdmin);
    } 
    
    function _addAdmin(address _newAdmin) internal returns(string memory){
        Admin memory admin = admins[_newAdmin];
        require(admins[_newAdmin].authorized = false, "Already an admin");
        admins[_newAdmin] = admin;
        adminsReverseMapping[adminIndex] = _newAdmin;
        adminIndex++;                                                                                             //safemath
        //emit AdminAdded(address _newAdmin);
    }
    
    function removeAdmin(address _admin) public onlyOwner {
        require(_admin != owner(), "Cannot remove owner");
        _removeAdmin(_admin);
    } 
    
    function _removeAdmin(address _admin) internal returns (string memory) {
        require(_admin != owner(), "Cannot remove owner");
        require(adminIndex > 1, "Cannot operate without admin");
        require(admins[_admin].authorized = true, "Not an admin");
        delete admins[_admin].Id;
        adminIndex--;                                                                                               //safemath
    }
    
    //Create the Student struct on the current studentIndex, pass assignment index as 0 and set the student as active
    
    function addStudent(bytes32 _firstName, bytes32 _lastName, bytes32 _commendation, grades _grades, string memory _email) public onlyAdmins onlyNonExistentStudents(_email) returns(bool) {
        
            Student memory student = students[studentIndex];
            student.firstName = _firstName;
            student.lastName = _lastName;
            student.commendation = _commendation;
            //student.grades = _grades;                                                                             //check how to include enums
            student.email = _email;
            student.assignmentIndex = 0;
            student.active = true;
            studentsReverseMapping[_email] = studentIndex;
            return true;
            studentIndex++;                                                                                         //safemath
            //emit StudentAdded
    }
    
    function removeStudent(string memory _email) public onlyAdmins onlyValidStudents(_email) returns(bool) {
        Student memory student = students[studentIndex];
        studentsReverseMapping[_email] = studentIndex;
        student.active = false;
        studentIndex--;                                                                                             //safemath
        return true;
        emit StudentRemoved(_email);
    }
    
    function changeAdminLimit(uint _newAdminLimit) public {
        require(_newAdminLimit > 1 && adminIndex, "Cannot have lesser admins");
        maxAdmins = _newAdminLimit; 
        emit AdminLimitChanged(maxAdmins);                                                                               //safemath
        //event AdminLimitChanged
    }

    function changeStudentName(string memory _email, bytes32 _newFirstName, bytes32 _newLastName) public onlyAdmins onlyValidStudents(_email){
        studentsReverseMapping[_email] = studentIndex;
        Student memory student = students[studentIndex];
        student.firstName = _newFirstName;
        student.lastName = _newLastName; 
        emit StudentNameUpdated(_email, _newFirstName, _newLastName);
    }

    function changeStudentCommendation(string memory _email, bytes32 _newCommendation ) public onlyAdmins onlyValidStudents(_email){
        studentsReverseMapping[_email] = studentIndex;
        Student memory student = students[studentIndex];
        student.commendation = _newCommendation;
        emit StudentCommendationUpdated(_email, _newCommendation);
    }

    function changeStudentGrade(string memory _email, grades _grade ) public onlyAdmins onlyValidStudents(_email) {
        studentsReverseMapping[_email] = studentIndex;
        Student memory student = students[studentIndex];
        student.grade = _grade;
        emit StudentGradeUpdated(_email, _grade);

    }

    function changeStudentEmail(string memory _email, string memory _newEmail) public onlyAdmins onlyValidStudents(_email){
        studentsReverseMapping[_email] = studentIndex;
        Student memory student = students[studentIndex];
        student.email = _newEmail;
        emit StudentEmailUpdated(_email, _newEmail);
    }
// onlyValidStudents

// Overriding Ownable Functions

    function transferOwnership(address _newOwner) public onlyAdmins {
        removeAdmin(msg.sender);
        addAdmin( _newOwner);
        transferOwnership(_newOwner);
        OwnershipTransferred(msg.sender, _newOwner);

    }

    function renounceOwnership() public onlyAdmins{
        removeAdmin(msg.sender);
        // AdminRemoved(address _newAdmin, _maxAdminNum);
        renounceOwnership();
    }
}