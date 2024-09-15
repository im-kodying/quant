from nautilus_trader.adapters.interactive_brokers.config import DockerizedIBGatewayConfig
from nautilus_trader.adapters.interactive_brokers.gateway import DockerizedIBGateway
import logging
logger = logging.getLogger()
logger.setLevel("INFO")

if __name__ == "main":
    gateway_config = DockerizedIBGatewayConfig(
        username="imkodying",
        password="cvNQOH3qRAT3ze8F5yr4",
        trading_mode="paper",
    )

    # This may take a short while to start up, especially the first time
    gateway = DockerizedIBGateway(
        config=gateway_config
    )
    gateway.start()

    # Confirm you are logged in
    logger.info(gateway.is_logged_in(gateway.container))

    # Inspect the logs
    logger.info(gateway.container.logs())
