import asyncio
import datetime
import logging
from decimal import Decimal

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
from nautilus_trader.adapters.interactive_brokers.historic import HistoricInteractiveBrokersClient
from nautilus_trader.backtest.config import BacktestVenueConfig, BacktestDataConfig, BacktestRunConfig, \
    BacktestEngineConfig
from nautilus_trader.backtest.node import BacktestNode
from nautilus_trader.model.data import QuoteTick
from nautilus_trader.persistence.catalog.parquet import ParquetDataCatalog
from nautilus_trader.trading.config import ImportableStrategyConfig
import socket
import random
from typing import Tuple

logger = logging.getLogger()
logger.setLevel("INFO")


async def main_live():
    logger.info("Kody: Starting Quant Trading Platform . . .")
    # host = "127.0.0.1"
    # port = 4002
    # instrument_provider_config = InteractiveBrokersInstrumentProviderConfig(
    #     build_futures_chain=False,  # Set to True if fetching futures
    #     build_options_chain=False,  # Set to True if fetching options
    #     min_expiry_days=10,  # Relevant for futures/options with expiration
    #     max_expiry_days=60,  # Relevant for futures/options with expiration
    #     load_ids=frozenset(
    #         [
    #             "EUR/USD.IDEALPRO",
    #             "BTC/USD.PAXOS",
    #             "SPY.ARCA",
    #             "V.NYSE",
    #             "YMH24.CBOT",
    #             "CLZ27.NYMEX",
    #             "ESZ27.CME",
    #         ],
    #     ),
    #     load_contracts=frozenset(
    #         [
    #             IBContract(secType='STK', symbol='SPY', exchange='SMART', primaryExchange='ARCA'),
    #             IBContract(secType='STK', symbol='AAPL', exchange='SMART', primaryExchange='NASDAQ')
    #         ]
    #     ),
    # )
    # data_client_config = InteractiveBrokersDataClientConfig(
    #     ibg_port=port,
    #     ibg_host=host,
    #     handle_revised_bars=False,
    #     use_regular_trading_hours=True,
    #     market_data_type=IBMarketDataTypeEnum.DELAYED_FROZEN,  # Default is REALTIME if not set
    #     instrument_provider=instrument_provider_config,
    # )
    # exec_client_config = InteractiveBrokersExecClientConfig(
    #     ibg_port=port,
    #     ibg_host=host,
    #     account_id="DU123456",  # Must match the connected IB Gateway/TWS
    #     instrument_provider=instrument_provider_config,
    #     routing=RoutingConfig(
    #         default=True,
    #     )
    # )
    # try:
    #     config_node = TradingNodeConfig(
    #         trader_id="TESTER-001",
    #         logging=LoggingConfig(log_level="INFO"),
    #         data_clients={"IB": data_client_config},
    #         exec_clients={"IB": exec_client_config},
    #         data_engine=LiveDataEngineConfig(
    #             time_bars_timestamp_on_close=False,  # Use opening time as `ts_event`, as per IB standard
    #             validate_data_sequence=True,  # Discards bars received out of sequence
    #         ),
    #     )
    #
    #     node = TradingNode(config=config_node)
    #     node.add_data_client_factory("IB", InteractiveBrokersLiveDataClientFactory)
    #     node.add_exec_client_factory("IB", InteractiveBrokersLiveExecClientFactory)
    #     node.build()
    #     node.portfolio.set_specific_venue(IB_VENUE)
    #     node.run()
    # finally:
    #     node.dispose()
    return


def find_listening_port(
        port_range: Tuple[int, int] = None,
        host='',
        socket_type='tcp',
        default: int = None
) -> int:
    """Find an available listening port

    Arguments:
        port_range: Optional tuple of ports to randomly search, ``[min_port, max_port]``
            If omitted, then randomly search between ``[6000, 65534]``
        host: Host interface to search, if omitted then bind to all interfaces
        socket_type: The socket type, this should be ``tcp`` or ``udp``
        default: The port to try first before randomly searching the port range

    Returns:
        Available port for listening
    """

    def _test_port(host, port, socket_protocol):
        with socket.socket(socket.AF_INET, socket_protocol) as sock:
            try:
                sock.bind((host, port))
                if socket_type == 'tcp':
                    sock.listen(1)
                return port
            except:
                pass

        return -1

    if port_range is None:
        port_range = (4001, 65534)

    if socket_type == 'tcp':
        socket_protocol = socket.SOCK_STREAM
    elif socket_type == 'udp':
        socket_protocol = socket.SOCK_DGRAM
    else:
        raise Exception('Invalid socket_type argument, must be: tcp or udp')

    searched_ports = []
    if default is not None:
        port = _test_port(host, default, socket_protocol)
        if port != -1:
            return port
        searched_ports.append(default)

    for port in range(port_range[0], port_range[1]):
        port = _test_port(host, port, socket_protocol)
        if port != -1:
            return port

        searched_ports.append(port)
    logger.warning(f"Kody: No Ports Found. Searched ports: {searched_ports}")
    raise Exception(f'Failed to find {socket_type} listening port for host={host}')


async def main_backtest(port):
    logger.warning("Kody: Backtest Started")
    host = "localhost"
    contract = IBContract(
        secType="STK",
        symbol="AAPL",
        exchange="SMART",
        primaryExchange="NASDAQ",
    )
    instrument_id = "TSLA.NASDAQ"

    client = HistoricInteractiveBrokersClient(host=host, port=port, client_id=5)
    await client.connect()
    await asyncio.sleep(2)
    logger.warning("Kody: Client Connected")
    start = datetime.datetime(2023, 11, 6, 10, 0)
    end = datetime.datetime(2023, 11, 6, 16, 30)

    instruments = await client.request_instruments(
        contracts=[contract],
        instrument_ids=[instrument_id],
    )

    bars = await client.request_bars(
        bar_specifications=["1-HOUR-LAST", "30-MINUTE-MID"],
        start_date_time=start,
        end_date_time=end,
        tz_name="America/New_York",
        contracts=[contract],
        instrument_ids=[instrument_id],
    )

    trade_ticks = await client.request_ticks(
        "TRADES",
        start_date_time=start,
        end_date_time=end,
        tz_name="America/New_York",
        contracts=[contract],
        instrument_ids=[instrument_id],
    )

    quote_ticks = await client.request_ticks(
        "BID_ASK",
        start_date_time=start,
        end_date_time=end,
        tz_name="America/New_York",
        contracts=[contract],
        instrument_ids=[instrument_id],
    )

    catalog = ParquetDataCatalog("./catalog")
    catalog.write_data(instruments)
    catalog.write_data(bars)
    catalog.write_data(trade_ticks)
    catalog.write_data(quote_ticks)

    venue_configs = [
        BacktestVenueConfig(
            name="SIM",
            oms_type="HEDGING",
            account_type="MARGIN",
            base_currency="USD",
            starting_balances=["1_000_000 USD"],
        ),
    ]

    instrument = catalog.instruments()[0]
    data_configs = [
        BacktestDataConfig(
            catalog_path=str(ParquetDataCatalog.from_env().path),
            data_cls=QuoteTick,
            instrument_id=instrument.id,
            start_time=start,
            end_time=end,
        ),
    ]

    strategies = [
        ImportableStrategyConfig(
            strategy_path="nautilus_trader.examples.strategies.ema_cross:EMACross",
            config_path="nautilus_trader.examples.strategies.ema_cross:EMACrossConfig",
            config={
                "instrument_id": instrument.id,
                "bar_type": "EUR/USD.SIM-15-MINUTE-BID-INTERNAL",
                "fast_ema_period": 10,
                "slow_ema_period": 20,
                "trade_size": Decimal(1_000_000),
            },
        ),
    ]

    config = BacktestRunConfig(
        engine=BacktestEngineConfig(strategies=strategies),
        data=data_configs,
        venues=venue_configs,
    )

    node = BacktestNode(configs=[config])

    results = node.run()
    logger.info("Kody", results)
    return


async def main():
    await asyncio.sleep(300)
    port = find_listening_port(host="localhost")
    logger.warning(f"Open Port found! {port}")
    await asyncio.gather(main_live(), main_backtest(port))
    return


if __name__ == "__main__":
    asyncio.run(main())
