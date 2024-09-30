import logging
from nautilus_trader.adapters.interactive_brokers.common import IB_VENUE
from nautilus_trader.adapters.interactive_brokers.factories import InteractiveBrokersLiveDataClientFactory
from nautilus_trader.adapters.interactive_brokers.factories import InteractiveBrokersLiveExecClientFactory
from nautilus_trader.config import LiveDataEngineConfig
from nautilus_trader.config import LoggingConfig
from nautilus_trader.config import TradingNodeConfig
from nautilus_trader.live.node import TradingNode
from nautilus_trader.adapters.interactive_brokers.config import InteractiveBrokersExecClientConfig
from nautilus_trader.config import RoutingConfig
from nautilus_trader.adapters.interactive_brokers.config import IBMarketDataTypeEnum
from nautilus_trader.adapters.interactive_brokers.config import InteractiveBrokersDataClientConfig
from nautilus_trader.adapters.interactive_brokers.config import InteractiveBrokersInstrumentProviderConfig
from nautilus_trader.adapters.interactive_brokers.common import IBContract

logger = logging.getLogger()
logger.setLevel("INFO")


def main():
    logger.info("Starting Quant Trading Platform . . .")
    host = "172.17.0.1"
    port = 4002
    instrument_provider_config = InteractiveBrokersInstrumentProviderConfig(
        build_futures_chain=False,  # Set to True if fetching futures
        build_options_chain=False,  # Set to True if fetching options
        min_expiry_days=10,  # Relevant for futures/options with expiration
        max_expiry_days=60,  # Relevant for futures/options with expiration
        load_ids=frozenset(
            [
                "EUR/USD.IDEALPRO",
                "BTC/USD.PAXOS",
                "SPY.ARCA",
                "V.NYSE",
                "YMH24.CBOT",
                "CLZ27.NYMEX",
                "ESZ27.CME",
            ],
        ),
        load_contracts=frozenset(
            [
                IBContract(secType='STK', symbol='SPY', exchange='SMART', primaryExchange='ARCA'),
                IBContract(secType='STK', symbol='AAPL', exchange='SMART', primaryExchange='NASDAQ')
            ]
        ),
    )
    data_client_config = InteractiveBrokersDataClientConfig(
        ibg_port=port,
        ibg_host=host,
        handle_revised_bars=False,
        use_regular_trading_hours=True,
        market_data_type=IBMarketDataTypeEnum.DELAYED_FROZEN,  # Default is REALTIME if not set
        instrument_provider=instrument_provider_config,
    )
    exec_client_config = InteractiveBrokersExecClientConfig(
        ibg_port=port,
        ibg_host=host,
        account_id="DU123456",  # Must match the connected IB Gateway/TWS
        instrument_provider=instrument_provider_config,
        routing=RoutingConfig(
            default=True,
        )
    )
    try:
        config_node = TradingNodeConfig(
            trader_id="TESTER-001",
            logging=LoggingConfig(log_level="INFO"),
            data_clients={"IB": data_client_config},
            exec_clients={"IB": exec_client_config},
            data_engine=LiveDataEngineConfig(
                time_bars_timestamp_on_close=False,  # Use opening time as `ts_event`, as per IB standard
                validate_data_sequence=True,  # Discards bars received out of sequence
            ),
        )

        node = TradingNode(config=config_node)
        node.add_data_client_factory("IB", InteractiveBrokersLiveDataClientFactory)
        node.add_exec_client_factory("IB", InteractiveBrokersLiveExecClientFactory)
        node.build()
        node.portfolio.set_specific_venue(IB_VENUE)
        node.run()
    finally:
        node.dispose()
    return


if __name__ == "__main__":
    main()
