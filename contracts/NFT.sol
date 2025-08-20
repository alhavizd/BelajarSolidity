// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VeritixTicket is ERC721URIStorage, Ownable {
    uint256 private _nextTicketId;

    struct EventInfo {
        string name;       // Nama event
        string location;   // Lokasi event
        string date;       // Tanggal event
        uint256 price;     // Harga tiket (dalam wei)
        uint256 maxSupply; // Maksimal tiket untuk event ini
        uint256 sold;      // Jumlah tiket terjual
    }

    // Mapping eventId => EventInfo
    mapping(uint256 => EventInfo) public events;

    // Mapping ticketId => eventId
    mapping(uint256 => uint256) public ticketToEvent;

    uint256 public nextEventId;

    constructor() ERC721("VeritixTicket", "VTX") Ownable(msg.sender) {
        _nextTicketId = 1;
        nextEventId = 1;
    }

    /// @notice Buat event baru
    function createEvent(
        string memory _name,
        string memory _location,
        string memory _date,
        uint256 _price,
        uint256 _maxSupply
    ) external onlyOwner {
        events[nextEventId] = EventInfo({
            name: _name,
            location: _location,
            date: _date,
            price: _price,
            maxSupply: _maxSupply,
            sold: 0
        });

        nextEventId++;
    }

    /// @notice Beli tiket untuk event tertentu
    function buyTicket(uint256 eventId, string memory tokenURI) external payable {
        EventInfo storage e = events[eventId];
        require(e.maxSupply > 0, "Event tidak ada");
        require(e.sold < e.maxSupply, "Tiket habis");
        require(msg.value == e.price, "Harga salah");

        uint256 ticketId = _nextTicketId;
        _safeMint(msg.sender, ticketId);
        _setTokenURI(ticketId, tokenURI);

        ticketToEvent[ticketId] = eventId;
        e.sold++;
        _nextTicketId++;
    }

    /// @notice Tarik dana hasil jualan tiket
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @notice Dapatkan detail tiket dari ID
    function getTicketInfo(uint256 ticketId) external view returns (EventInfo memory) {
        uint256 eventId = ticketToEvent[ticketId];
        return events[eventId];
    }
}
