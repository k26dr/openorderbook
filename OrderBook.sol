interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract OrderBook {
        enum Side { BUY, SELL }
        struct Order {
		address user;
                uint baseQuantity;
                uint quoteQuantity;
                uint orderId;
                address baseToken;
                address quoteToken;
                Side side;
        }
        mapping(uint => Order) public orders;
        uint public orderCounter = 0; 

	event OrderPlaced(uint orderId, address indexed user, address indexed baseToken, address indexed quoteToken, Side side, uint baseQuantity, uint quoteQuantity);
	event OrderCanceled(uint indexed orderId);
	event OrderFill(uint indexed orderId, uint baseQuantity);

	function placeOrder (address baseToken, address quoteToken, Side side, uint baseQuantity, uint quoteQuantity) public {
		require(baseQuantity > 0 && quoteQuantity > 0, "zero quantity orders not permitted");
		if (side == Side.SELL) {
			IERC20(baseToken).transferFrom(msg.sender, address(this), baseQuantity);
		}
		else if (side == Side.BUY) {
			IERC20(quoteToken).transferFrom(msg.sender, address(this), quoteQuantity);
		}
                uint orderId = ++orderCounter;
                orders[orderId] = Order(msg.sender, baseQuantity, quoteQuantity, orderId, baseToken, quoteToken, side);
		emit OrderPlaced(orderId, msg.sender, baseToken, quoteToken, side, baseQuantity, quoteQuantity);
        }

	function cancelOrder (uint orderId) public {
		Order memory order = orders[orderId];
		require(msg.sender == order.user, "users can only cancel their own order");
                delete orders[orderId];
		if (order.side == Side.SELL) {
			IERC20(order.baseToken).transfer(msg.sender, order.baseQuantity);
		}
		else if (order.side == Side.BUY) {
			IERC20(order.quoteToken).transfer(msg.sender, order.quoteQuantity);
		}
		emit OrderCanceled(orderId);
        }
	
	function fillOrder (uint orderId, uint baseQuantity) public {
                Order memory order = orders[orderId];
                require(baseQuantity > 0, "zero quantity fills not permitted");
                require(baseQuantity <= order.baseQuantity, "trying to fill more than order size");
		uint quoteQuantity = baseQuantity * order.quoteQuantity / order.baseQuantity;
                require(quoteQuantity > 0, "calculated quote quantity is zero");
		orders[orderId].baseQuantity -= baseQuantity;
		orders[orderId].quoteQuantity -= quoteQuantity;
		if (orders[orderId].baseQuantity == 0) {
			delete orders[orderId];
		}
		if (order.side == Side.SELL) {
			IERC20(order.quoteToken).transferFrom(msg.sender, order.user, quoteQuantity);
			IERC20(order.baseToken).transfer(msg.sender, baseQuantity);
		}
		else if (order.side == Side.BUY) {
			IERC20(order.baseToken).transferFrom(msg.sender, order.user, baseQuantity);
			IERC20(order.quoteToken).transfer(msg.sender, quoteQuantity);
		}
		emit OrderFill(orderId, baseQuantity);
	}

	function fillOrders(uint[] calldata orderIds, uint[] calldata baseFillQuantities) public {
		require(orderIds.length == baseFillQuantities.length, "orderIds and baseFillQuantities array lengths must match");
		for (uint i=0; i < orderIds.length; i++) {
			fillOrder(orderIds[i], baseFillQuantities[i]);
		}
	}
}

