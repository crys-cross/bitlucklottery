// SPDX-License-Identifier: MIT

//TODO: update chainlink vrf and supported chains and migrate upkeep to automation
//TODO: optimized winnerspicked
//TODO: deploy and test scripts
//TODO: price converter so customers pay per $ amount not in crypto amount

pragma solidity ^0.8.24;

import {IVRFCoordinatorV2Plus} from "@chainlink/contracts@1.1.0/src/v0.8/vrf/dev/interfaces/IVRFCoordinatorV2Plus.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.1.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.1.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol"; // outdated
// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 *  @title LUCKY-TRIO-LOTTERY
 *  @author crys
 *  @notice This contract is to demo a sample funding contract
 *  @dev This is a Decentralized Lottery Game using Chainlink VRF
 *  for generating randomness in choosing the winning number
 *  submitted by the players. In the spirit of Decentralization
 *  I chose not to make a withdraw function all funds function but
 *  Admin/Owner may only withdraw the AdminFunds(10%) which is added
 *  on every draw. Directly sending this contract ETH will be considered
 *  a contribution thus will directly go to AdminFunds
 **/

contract LuckyTrio is
    VRFConsumerBaseV2Plus,
    AutomationCompatibleInterface,
    Ownable,
    ReentrancyGuard
{
    /*Errors*/
    error LuckyTrio_Not_enough_ETH_paid();
    error LuckyTrio__NotOpen();
    error LuckyTrio__NumberAlreadyTaken();
    error LuckyTrio__UpKeepNotNeeded(
        uint256 currentBalance,
        uint256 playersNum,
        uint256 LotteryState
    );
    error LuckyTrio__TransferFailed();

    /*Type declarations*/
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /*VRF Variables*/
    IVRFCoordinatorV2Plus private immutable i_vrfCoordinator;
    bytes32 private immutable i_keyHash;
    uint64 private immutable i_subscriptionId; // change to uint256
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    /*Upkeep Automation Variables*/
    uint256 private immutable i_keepersUpdateInterval;
    uint256 private s_lastTimeStamp;

    /*LotteryVariables*/
    uint256[] private s_playersNumber;
    uint256 private immutable i_entranceFee; // remove immutable if enable changeEntranceFee
    address private s_recentWinner;
    uint256 private s_recentWinningNumber;
    LotteryState private s_lotteryState;
    uint256 private s_potMoney;
    uint256 private s_adminFunds;
    uint256 private s_TotalBalance;

    //mapping
    mapping(uint256 => address) public s_playersEntry;

    /*Events*/
    event RaffleEnter(address indexed player, uint256 playersNumber);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed player, uint256 winningNumber);
    event NoWinner(uint256 winningNumber);
    event Log(string func, address sender, uint256 value, bytes data);

    // event ChangedEntranceFee(uint256 newFee); //for changeEntranceFee

    constructor(
        address vrfCoordinatorV2,
        bytes32 keyHash,
        uint256 subscriptionId,
        uint32 callbackGasLimit,
        uint256 entranceFee,
        uint256 interval
    ) VRFConsumerBaseV2Plus(vrfCoordinatorV2) {
        i_vrfCoordinator = IVRFCoordinatorV2Plus(vrfCoordinatorV2); //vrf arguments starts here
        i_keyHash = keyHash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        i_entranceFee = entranceFee; //lotery entrance feel
        s_lotteryState = LotteryState.OPEN; //upkeep automation arguments starts here
        s_lastTimeStamp = block.timestamp;
        i_keepersUpdateInterval = interval;
    }

    receive() external payable {
        s_adminFunds += msg.value;
        emit Log("receive", msg.sender, msg.value, "");
    }

    fallback() external payable {
        s_adminFunds += msg.value;
        emit Log("receive", msg.sender, msg.value, msg.data);
    }

    function enterLottery(uint256 playersNumber) public payable {
        if (msg.value < i_entranceFee) {
            revert Lottery_Not_enough_ETH_paid();
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__NotOpen();
        }
        if (s_playersEntry[playersNumber] != address(0)) {
            revert Lottery__NumberAlreadyTaken();
        }
        s_playersNumber.push(playersNumber);
        s_playersEntry[playersNumber] = payable(msg.sender);
        s_TotalBalance = address(this).balance;
        uint256 cut = (s_TotalBalance - s_adminFunds) / 10;
        s_adminFunds = cut + s_adminFunds;
        s_potMoney = s_TotalBalance - s_adminFunds;
        emit RaffleEnter(msg.sender, playersNumber);
    }

    /*for audit if safe */
    // function changeEntranceFee(uint256 newFee) internal onlyOwner {
    //     i_entranceFee = newFee;
    //     emit ChangedEntranceFee(newFee);
    // }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True. Conditions below.
     * Please don't forget to fund LINK on subscription
     */
    function checkUpkeep(
        bytes memory /*checkData*/
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /*performData*/)
    {
        bool isOpen = (LotteryState.OPEN == s_lotteryState);
        bool timePassed = ((block.timestamp - s_lastTimeStamp) >
            i_keepersUpdateInterval);
        bool hasPlayers = (s_playersNumber.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override returns (uint256 requestId) {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpKeepNotNeeded(
                address(this).balance,
                s_playersNumber.length,
                uint256(s_lotteryState)
            );
        }
        s_lotteryState = LotteryState.CALCULATING;
        requestId = COORDINATOR.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        // old vrf below
        // uint256 requestId = i_vrfCoordinator.requestRandomWords(
        //     i_keyHash, //keyHash(named keyHash)
        //     i_subscriptionId, //s_subscriptionId(named i_subscriptionId)
        //     REQUEST_CONFIRMATIONS, //requestConfirmations(named REQUEST_CONFIRMATIONS)
        //     i_callbackGasLimit, //callbackGasLimit(named i_callbackGasLimit)
        //     NUM_WORDS //numWords(named NUM_WORDS)
        // );
        emit RequestedRaffleWinner(requestId);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        s_recentWinningNumber = randomWords[0] % 999; //players can only choose 1-999
        s_recentWinner = s_playersEntry[s_recentWinningNumber];
        if (s_recentWinner == address(0)) {
            uint256[] memory numbers = s_playersNumber;
            for (
                uint256 numberIndex = 0;
                numberIndex < numbers.length;
                numberIndex++
            ) {
                uint256 index = numbers[numberIndex];
                s_playersEntry[index] = payable(address(0));
            }
            s_playersNumber = new uint256[](0);
            s_lotteryState = LotteryState.OPEN;
            s_lastTimeStamp = block.timestamp;
            emit NoWinner(s_recentWinningNumber);
        } else {
            s_lotteryState = LotteryState.OPEN;
            uint256[] memory numbers = s_playersNumber;
            for (
                uint256 numberIndex = 0;
                numberIndex < numbers.length;
                numberIndex++
            ) {
                uint256 index = numbers[numberIndex];
                s_playersEntry[index] = payable(address(0));
            }
            s_playersNumber = new uint256[](0);
            s_lotteryState = LotteryState.OPEN;
            s_lastTimeStamp = block.timestamp;
            uint256 amount = s_potMoney;
            s_potMoney = 0;
            (bool success, ) = s_recentWinner.call{value: amount}("");
            if (!success) {
                revert Lottery__TransferFailed();
            }
            s_TotalBalance = address(this).balance;
            emit WinnerPicked(s_recentWinner, s_recentWinningNumber);
        }
    }

    /*withdraw function for admin*/
    function withdrawAdminFund() public payable onlyOwner nonReentrant {
        uint256 amount = s_adminFunds;
        s_adminFunds = 0;
        payable(msg.sender).transfer(amount);
    }

    // /*emergency withdraw*/
    // function withdrawAdminFund() public payable onlyOwner {
    //     payable(msg.sender).transfer(address(this).balance);
    //     s_adminFunds = 0;
    // }

    /*View/Pure Functions*/
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRecentWinningNumber() public view returns (uint256) {
        return s_recentWinningNumber;
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getPlayersNumberbyIndex(
        uint256 index
    ) public view returns (uint256) {
        return s_playersNumber[index];
    }

    function getNumberofPlayers() public view returns (uint256) {
        return s_playersNumber.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getMinutesBeforeNextDraw() public view returns (uint256) {
        uint256 drawTime;
        drawTime = (block.timestamp - s_lastTimeStamp) / 60;
        return drawTime;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return i_keepersUpdateInterval;
    }

    function getAdminFund() public view returns (uint256) {
        return s_adminFunds;
    }

    function getPotMoney() public view returns (uint256) {
        return s_potMoney;
    }

    function getTotalBalance() public view returns (uint256) {
        return s_TotalBalance;
    }
}
