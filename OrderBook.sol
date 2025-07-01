contract OrderBook {
	enum Side { BUY, SELL }
	struct Order {
		uint price;
		uint quantity;
		uint orderId;
		uint nextOrderId;
		address baseToken;
		address quoteToken;
		Side side;
	}
	mapping(uint => Order) orders;    
	mapping(address => mapping(address => mapping(Side => uint)) orderbooks;
	uint orderCounter = 0;
	
	function placeOrder (address baseToken, address quoteToken, Side side, uint price, uint quantity) {
		uint orderId = ++orderCounter;
		orders[orderId] = Order(price, quantity, orderId, orderbooks[baseToken][quoteToken][side], baseToken, quoteToken, side);
		orderbooks[baseToken][quoteToken][side] = orderId;
	}

}
